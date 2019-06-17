/*
 * Copyright 2010-2019, Tarantool AUTHORS, please see AUTHORS file.
 *
 * Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * <COPYRIGHT HOLDER> OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stddef.h>
#include <signal.h>
#include "coio_popen.h"
#include "coio_task.h"
#include "fiber.h"
#include "fio.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <pthread.h>
#include <float.h>
#include <sysexits.h>

/*
 * On OSX this global variable is not declared
 * in <unistd.h>
 */
extern char **environ;


struct popen_handle {
	/* Process id */
	pid_t pid;

	/*
	 * Three descriptors:
	 * [0] write to stdin of the child process
	 * [1] read from stdout of the child process
	 * [2] read from stderr of the child process
	 * Valid only for pipe.
	 */
	int fd[3];

	/*
	 * Handle to /dev/null.
	 */
	int devnull_fd;

	/*
	 * Current process status.
	 * The SIGCHLD handler changes this status.
	 */
	enum popen_status status;

	/*
	 * Exit status of the associated process
	 * or number of the signal that caused the
	 * associated process to terminate.
	 */
	int exit_code;
};

/*
 * Map: (pid) => (popen_handle *)
 */
#define mh_name _popen_storage
#define mh_key_t pid_t
#define mh_node_t struct popen_handle*
#define mh_arg_t void *
#define mh_hash(a, arg) ((*a)->pid)
#define mh_hash_key(a, arg) (a)
#define mh_cmp(a, b, arg) (((*a)->pid) != ((*b)->pid))
#define mh_cmp_key(a, b, arg) ((a) != ((*b)->pid))
#define MH_SOURCE 1
#include "salad/mhash.h"


static pthread_mutex_t mutex;
static struct mh_popen_storage_t* popen_hash_table = NULL;

void
popen_initialize()
{
	pthread_mutexattr_t errorcheck;
	pthread_mutexattr_init(&errorcheck);
	pthread_mutexattr_settype(&errorcheck,
		PTHREAD_MUTEX_ERRORCHECK);
	pthread_mutex_init(&mutex, &errorcheck);
	pthread_mutexattr_destroy(&errorcheck);

	popen_hash_table = mh_popen_storage_new();
}

static void
popen_lock_data_list()
{
	pthread_mutex_lock(&mutex);
}

static void
popen_unlock_data_list()
{
	pthread_mutex_unlock(&mutex);
}

static void
popen_append_to_list(struct popen_handle *data)
{
	struct popen_handle **old = NULL;
	mh_int_t id = mh_popen_storage_put(popen_hash_table,
		(const struct popen_handle **)&data, &old, NULL);
	(void)id;
}

static struct popen_handle *
popen_lookup_data_by_pid(pid_t pid)
{
	mh_int_t pos = mh_popen_storage_find(popen_hash_table, pid, NULL);
	if (pos == mh_end(popen_hash_table))
		return NULL;
	else {
		struct popen_handle ** ptr =
			mh_popen_storage_node(popen_hash_table, pos);
		return *ptr;
	}
}

static void
popen_exclude_from_list(struct popen_handle *data)
{
	mh_popen_storage_remove(popen_hash_table,
		(const struct popen_handle **)&data, NULL);
}

static struct popen_handle *
popen_data_new()
{
	struct popen_handle *data =
		(struct popen_handle *)calloc(1, sizeof(*data));
	data->fd[0] = -1;
	data->fd[1] = -1;
	data->fd[2] = -1;
	data->devnull_fd = -1;
	data->status = POPEN_RUNNING;
	return data;
}

enum pipe_end {
	PIPE_READ = 0,
	PIPE_WRITE = 1
};

static inline enum pipe_end
	popen_opposite_pipe(enum pipe_end side)
{
	return (enum pipe_end)(side ^ 1);
	/*
	 * The code is equal to:
	 * return (side == PIPE_READ) ? PIPE_WRITE
	 * 			      : PIPE_READ;
	 */
}

static inline bool
popen_create_pipe(int fd, int pipe_pair[2], enum pipe_end parent_side)
{
	if (fd == FIO_PIPE) {
		if (pipe(pipe_pair) < 0 ||
		    fcntl(pipe_pair[parent_side], F_SETFL, O_NONBLOCK) < 0) {
			return false;
		}
	}
	return true;
}

static inline void
popen_close_child_fd(int std_fd, int pipe_pair[2],
	int *saved_fd, enum pipe_end child_side)
{
	if (std_fd == FIO_PIPE) {
		/* Close child's side. */
		close(pipe_pair[child_side]);

		enum pipe_end parent_side = popen_opposite_pipe(child_side);
		*saved_fd = pipe_pair[parent_side];
	}
}

static inline void
popen_close_pipe(int pipe_pair[2])
{
	if (pipe_pair[0] >= 0) {
		close(pipe_pair[0]);
		close(pipe_pair[1]);
	}
}


/**
 * Implementation of fio.popen.
 * The function opens a process by creating a pipe
 * forking.
 *
 * @param argv - is an array of character pointers
 * to the arguments terminated by a null pointer.
 *
 * @param envp - is the pointer to an array
 * of character pointers to the environment strings.
 *
 * @param stdin_fd - the file handle to be redirected to the
 * child process's STDIN.
 *
 * @param stdout_fd - the file handle receiving the STDOUT
 * output of the child process.
 *
 * @param stderr_fd - the file handle receiving the STDERR
 * output of the child process.
 *
 * The stdin_fd, stdout_fd & stderr_fd accept file descriptors
 * from open() or the following values:
 *
 * FIO_PIPE - opens a pipe, binds it with child's
 * input/output. The pipe is available for reading/writing.
 *
 * FIO_DEVNULL - redirects output from process to /dev/null.
 *
 * @return handle of the pipe for reading or writing
 * (depends on value of type).
 * In a case of error returns NULL.
 */
static struct popen_handle *
popen_new_impl(char **argv, char **envp,
	int stdin_fd, int stdout_fd, int stderr_fd)
{
	bool popen_list_locked = false;
	pid_t pid;
	int pipe_rd[2] = {-1,-1};
	int pipe_wr[2] = {-1,-1};
	int pipe_er[2] = {-1,-1};
	errno = 0;

	struct popen_handle *data = popen_data_new();
	if (data == NULL)
		return NULL;

	/*
	 * Setup a /dev/null if necessary.
	 */
	bool read_devnull = (stdin_fd == FIO_DEVNULL);
	bool write_devnull = (stdout_fd == FIO_DEVNULL) ||
			     (stderr_fd == FIO_DEVNULL);
	int devnull_flags = O_RDWR;
	if (!read_devnull)
		devnull_flags = O_WRONLY;
	else if (!write_devnull)
		devnull_flags = O_RDONLY;

	if (read_devnull || write_devnull) {
		data->devnull_fd = open("/dev/null", devnull_flags);
		if (data->devnull_fd < 0)
			goto on_error;
		else {
			if (stdin_fd == FIO_DEVNULL)
				stdin_fd = data->devnull_fd;
			if (stdout_fd == FIO_DEVNULL)
				stdout_fd = data->devnull_fd;
			if (stderr_fd == FIO_DEVNULL)
				stderr_fd = data->devnull_fd;
		}
	}

	if (!popen_create_pipe(stdin_fd, pipe_rd, PIPE_WRITE))
		goto on_error;
	if (!popen_create_pipe(stdout_fd, pipe_wr, PIPE_READ))
		goto on_error;
	if (!popen_create_pipe(stderr_fd, pipe_er, PIPE_READ))
		goto on_error;

	/*
	 * Prepare data for the child process.
	 * There must be no branches, to avoid compiler
	 * error: "argument ‘xxx’ might be clobbered by
	 * ‘longjmp’ or ‘vfork’ [-Werror=clobbered]".
	 */
	if (envp == NULL)
		envp = environ;

	/* Handles to be closed in child process */
	int close_fd[3] = {-1, -1, -1};
	/* Handles to be duplicated in child process */
	int dup_fd[3] = {-1, -1, -1};
	/* Handles to be closed after dup2 in child process */
	int close_after_dup_fd[3] = {-1, -1, -1};

	if (stdin_fd == FIO_PIPE) {
		close_fd[STDIN_FILENO] = pipe_rd[PIPE_WRITE];
		dup_fd[STDIN_FILENO] = pipe_rd[PIPE_READ];
	} else if (stdin_fd != STDIN_FILENO) {
		dup_fd[STDIN_FILENO] = stdin_fd;
		close_after_dup_fd[STDIN_FILENO] = stdin_fd;
	}

	if (stdout_fd == FIO_PIPE) {
		close_fd[STDOUT_FILENO] = pipe_wr[PIPE_READ];
		dup_fd[STDOUT_FILENO] = pipe_wr[PIPE_WRITE];
	} else if (stdout_fd != STDOUT_FILENO){
		dup_fd[STDOUT_FILENO] = stdout_fd;
		if (stdout_fd != STDERR_FILENO)
			close_after_dup_fd[STDOUT_FILENO] = stdout_fd;
	}

	if (stderr_fd == FIO_PIPE) {
		close_fd[STDERR_FILENO] = pipe_er[PIPE_READ];
		dup_fd[STDERR_FILENO] = pipe_er[PIPE_WRITE];
	} else if (stderr_fd != STDERR_FILENO) {
		dup_fd[STDERR_FILENO] = stderr_fd;
		if (stderr_fd != STDOUT_FILENO)
			close_after_dup_fd[STDERR_FILENO] = stderr_fd;
	}


	popen_lock_data_list();
	popen_list_locked = true;

	pid = vfork();

	if (pid < 0)
		goto on_error;
	else if (pid == 0) /* child */ {
		/* Reset all signals to their defaults. */
		struct sigaction sa;
		memset(&sa, 0, sizeof(sa));
		sigemptyset(&sa.sa_mask);
		sa.sa_handler = SIG_DFL;

		if (sigaction(SIGUSR1, &sa, NULL) == -1 ||
		    sigaction(SIGINT, &sa, NULL) == -1 ||
		    sigaction(SIGTERM, &sa, NULL) == -1 ||
		    sigaction(SIGHUP, &sa, NULL) == -1 ||
		    sigaction(SIGWINCH, &sa, NULL) == -1 ||
		    sigaction(SIGSEGV, &sa, NULL) == -1 ||
		    sigaction(SIGFPE, &sa, NULL) == -1 ||
		    sigaction(SIGCHLD, &sa, NULL) == -1)
			exit(EX_OSERR);

		/* Unblock any signals blocked by libev. */
		sigset_t sigset;
		sigfillset(&sigset);
		if (sigprocmask(SIG_UNBLOCK, &sigset, NULL) == -1)
			exit(EX_OSERR);

		/* Setup stdin/stdout */
		for(int i = 0; i < 3; ++i) {
			if (close_fd[i] >= 0)
				close(close_fd[i]);
			if (dup_fd[i] >= 0)
				dup2(dup_fd[i], i);
			if (close_after_dup_fd[i] >= 0)
				close(close_after_dup_fd[i]);
		}

		execve( argv[0], argv, envp);
		exit(EX_OSERR);
		unreachable();
	}

	/* Parent process */
	popen_close_child_fd(stdin_fd,  pipe_rd,
		&data->fd[STDIN_FILENO], PIPE_READ);
	popen_close_child_fd(stdout_fd, pipe_wr,
		&data->fd[STDOUT_FILENO], PIPE_WRITE);
	popen_close_child_fd(stderr_fd, pipe_er,
		&data->fd[STDERR_FILENO], PIPE_WRITE);

	data->pid = pid;

on_cleanup:
	if (data){
		popen_append_to_list(data);
	}

	if (popen_list_locked)
		popen_unlock_data_list();

	if (argv){
		for(int i = 0; argv[i] != NULL; ++i)
			free(argv[i]);
		free(argv);
	}
	if (envp && envp != environ) {
		for(int i = 0; envp[i] != NULL; ++i)
			free(envp[i]);
		free(envp);
	}

	return data;

on_error:
	popen_close_pipe(pipe_rd);
	popen_close_pipe(pipe_wr);
	popen_close_pipe(pipe_er);

	if (data) {
		if (data->devnull_fd >= 0)
			close(data->devnull_fd);
		free(data);
	}
	data = NULL;

	goto on_cleanup;
	unreachable();
}

ssize_t
popen_new(va_list ap)
{
	char **argv = va_arg(ap, char **);
	char **envp = va_arg(ap, char **);
	int stdin_fd = va_arg(ap, int);
	int stdout_fd = va_arg(ap, int);
	int stderr_fd = va_arg(ap, int);
	struct popen_handle **handle = va_arg(ap, struct popen_handle **);

	*handle = popen_new_impl(argv, envp, stdin_fd, stdout_fd, stderr_fd);
	return (*handle) ? 0 : -1;
}

static void
popen_close_handles(struct popen_handle *data)
{
	for(int i = 0; i < 3; ++i) {
		if (data->fd[i] >= 0) {
			close(data->fd[i]);
			data->fd[i] = -1;
		}
	}
	if (data->devnull_fd >= 0) {
		close(data->devnull_fd);
		data->devnull_fd = -1;
	}
}

int
popen_destroy(struct popen_handle *fh)
{
	assert(fh);

	popen_lock_data_list();
	popen_close_handles(fh);
	popen_exclude_from_list(fh);
	popen_unlock_data_list();

	free(fh);
	return 0;
}

/**
 * Check if an errno, returned from a sio function, means a
 * non-critical error: EAGAIN, EWOULDBLOCK, EINTR.
 */
static inline bool
popen_wouldblock(int err)
{
	return err == EAGAIN || err == EWOULDBLOCK || err == EINTR;
}

static int
popen_do_read(struct popen_handle *data, void *buf, size_t count, int *source_id)
{
	/*
	 * STDERR has higher priority, read it first.
	 */
	int rc = 0;
	errno = 0;
	int fd_count = 0;
	if (data->fd[STDERR_FILENO] >= 0) {
		++fd_count;
		rc = read(data->fd[STDERR_FILENO], buf, count);

		if (rc >= 0)
			*source_id = STDERR_FILENO;
		if (rc > 0)
			return rc;

		if (rc < 0 && !popen_wouldblock(errno))
			return rc;

	}

	/*
	 * STDERR is not available or not ready, try STDOUT.
	 */
	if (data->fd[STDOUT_FILENO] >= 0) {
		++fd_count;
		rc = read(data->fd[STDOUT_FILENO], buf, count);

		if (rc >= 0) {
			*source_id = STDOUT_FILENO;
			return rc;
		}
	}

	if (!fd_count) {
		/*
		 * There are no open handles for reading.
		 */
		errno = EBADF;
		rc = -1;
	}
	return rc;
}

static void
popen_coio_create(struct ev_io *coio, int fd)
{
	coio->data = fiber();
	ev_init(coio, (ev_io_cb) fiber_schedule_cb);
	coio->fd = fd;
}

int
popen_read(struct popen_handle *fh, void *buf, size_t count,
	size_t *read_bytes, int *source_id,
	ev_tstamp timeout)
{
	assert(fh);
	if (timeout < 0.0)
		timeout = DBL_MAX;

	ev_tstamp start, delay;
	evio_timeout_init(loop(), &start, &delay, timeout);

	struct ev_io coio_rd;
	struct ev_io coio_er;
	popen_coio_create(&coio_er, fh->fd[STDERR_FILENO]);
	popen_coio_create(&coio_rd, fh->fd[STDOUT_FILENO]);

	int result = 0;

	while (true) {
		int rc = popen_do_read(fh, buf, count, source_id);
		if (rc >= 0) {
			*read_bytes = rc;
			break;
		}

		if (!popen_wouldblock(errno)) {
			result = -1;
			break;
		}

		/*
		 * The handlers are not ready, yield.
		 */
		if (!ev_is_active(&coio_rd) &&
		     fh->fd[STDOUT_FILENO] >= 0) {
			ev_io_set(&coio_rd, fh->fd[STDOUT_FILENO], EV_READ);
			ev_io_start(loop(), &coio_rd);
		}
		if (!ev_is_active(&coio_er) &&
		    fh->fd[STDERR_FILENO] >= 0) {
			ev_io_set(&coio_er, fh->fd[STDERR_FILENO], EV_READ);
			ev_io_start(loop(), &coio_er);
		}
		/*
		 * Yield control to other fibers until the
		 * timeout is reached.
		 */
		bool is_timedout = fiber_yield_timeout(delay);
		if (is_timedout) {
			errno = ETIMEDOUT;
			result = -1;
			break;
		}

		if (fiber_is_cancelled()) {
			errno = EINTR;
			result = -1;
			break;
		}

		evio_timeout_update(loop(), &start, &delay);
	}

	ev_io_stop(loop(), &coio_er);
	ev_io_stop(loop(), &coio_rd);
	return result;
}

int
popen_write(struct popen_handle *fh, const void *buf, size_t count,
	size_t *written, ev_tstamp timeout)
{
	assert(fh);
	if (count == 0) {
		*written = 0;
		return  0;
	}

	if (timeout < 0.0)
		timeout = DBL_MAX;

	if (fh->fd[STDIN_FILENO] < 0) {
		*written = 0;
		errno = EBADF;
		return -1;
	}

	ev_tstamp start, delay;
	evio_timeout_init(loop(), &start, &delay, timeout);

	struct ev_io coio;
	popen_coio_create(&coio, fh->fd[STDIN_FILENO]);
	int result = 0;

	while(true) {
		ssize_t rc = write(fh->fd[STDIN_FILENO], buf, count);
		if (rc < 0 && !popen_wouldblock(errno)) {
			result = -1;
			break;
		}

		size_t urc = (size_t)rc;

		if (urc == count) {
			*written = count;
			break;
		}

		if (rc > 0) {
			buf += rc;
			count -= urc;
		}

		/*
		 * The handlers are not ready, yield.
		 */
		if (!ev_is_active(&coio)) {
			ev_io_set(&coio, fh->fd[STDIN_FILENO], EV_WRITE);
			ev_io_start(loop(), &coio);
		}

		/*
		 * Yield control to other fibers until the
		 * timeout is reached.
		 */
		bool is_timedout = fiber_yield_timeout(delay);
		if (is_timedout) {
			errno = ETIMEDOUT;
			result = -1;
			break;
		}

		if (fiber_is_cancelled()) {
			errno = EINTR;
			result = -1;
			break;
		}

		evio_timeout_update(loop(), &start, &delay);
	}

	ev_io_stop(loop(), &coio);
	return result;
}

int
popen_kill(struct popen_handle *fh, int signal_id)
{
	assert(fh);
	return kill(fh->pid, signal_id);
}

int
popen_wait(struct popen_handle *fh, ev_tstamp timeout, int *exit_code)
{
	assert(fh);
	if (timeout < 0.0)
		timeout = DBL_MAX;

	ev_tstamp start, delay;
	evio_timeout_init(loop(), &start, &delay, timeout);

	int result = 0;

	while (true) {
		/* Wait for SIGCHLD */
		int code = 0;

		int rc = popen_get_status(fh, &code);
		if (rc != POPEN_RUNNING) {
			*exit_code = (rc == POPEN_EXITED) ? code
							  : -code;
			break;
		}

		/*
		 * Yield control to other fibers until the
		 * timeout is reached.
		 * Let's sleep for 20 msec.
		 */
		fiber_yield_timeout(0.02);

		if (fiber_is_cancelled()) {
			errno = EINTR;
			result = -1;
			break;
		}

		evio_timeout_update(loop(), &start, &delay);
		bool is_timedout = (delay == 0.0);
		if (is_timedout) {
			errno = ETIMEDOUT;
			result = -1;
			break;
		}
	}

	return result;
}

int
popen_get_std_file_handle(struct popen_handle *fh, int file_no)
{
	assert(fh);
	if (file_no < STDIN_FILENO || STDERR_FILENO < file_no){
		errno = EINVAL;
		return -1;
	}

	errno = 0;
	return fh->fd[file_no];
}

int
popen_get_status(struct popen_handle *fh, int *exit_code)
{
	assert(fh);
	errno = 0;

	if (exit_code)
		*exit_code = fh->exit_code;

	return fh->status;
}

/*
 * evio data to control SIGCHLD
 */
static ev_child cw;

static void
popen_sigchld_cb(ev_loop *loop, ev_child *watcher, int revents)
{
	(void)loop;
	(void)revents;

	popen_lock_data_list();

	struct popen_handle *data = popen_lookup_data_by_pid(watcher->rpid);
	if (data) {
		if (WIFEXITED(watcher->rstatus)) {
			data->exit_code = WEXITSTATUS(watcher->rstatus);
			data->status = POPEN_EXITED;
		} else if (WIFSIGNALED(watcher->rstatus)) {
			data->exit_code = WTERMSIG(watcher->rstatus);

			if (WCOREDUMP(watcher->rstatus))
				data->status = POPEN_DUMPED;
			else
				data->status = POPEN_KILLED;
		} else {
			/*
			 * The status is not determined, treat as EXITED
			 */
			data->exit_code = EX_SOFTWARE;
			data->status = POPEN_EXITED;
		}

		/*
		 * We shouldn't close file descriptors here.
		 * The child process may exit earlier than
		 * the parent process finishes reading data.
		 * In this case the reading fails.
		 */
	}

	popen_unlock_data_list();
}

void
popen_setup_sigchld_handler()
{
	ev_child_init (&cw, popen_sigchld_cb, 0/*pid*/, 0);
	ev_child_start(loop(), &cw);

}

void
popen_reset_sigchld_handler()
{
	ev_child_stop(loop(), &cw);
}
