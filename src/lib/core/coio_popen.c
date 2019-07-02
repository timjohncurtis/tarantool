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
#include <float.h>
#include <sysexits.h>
#include "evio.h"

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
	 * In any other cases they are set to -1.
	 */
	int fd[3];

	/* Set to true if the process has terminated. */
	bool terminated;

	/*
	 * If the process has terminated, this variable stores
	 * the exit code if the process exited normally, by
	 * calling exit(), or -signo if the process was killed
	 * by a signal.
	 */
	int status;

	/*
	 * popen_wait() waits for SIGCHLD within the variable.
	 */
	struct fiber_cond sigchld_cond;
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

static void
popen_setup_sigchld_handler();

static void
popen_reset_sigchld_handler();


static struct mh_popen_storage_t *popen_hash_table = NULL;

/*
 * A file descriptor to /dev/null
 * shared between all child processes
 */
static int popen_devnull_fd = -1;

void
popen_init()
{
	popen_hash_table = mh_popen_storage_new();
	popen_setup_sigchld_handler();
}

void
popen_free()
{
	popen_reset_sigchld_handler();

	mh_popen_storage_delete(popen_hash_table);
	popen_hash_table = NULL;

	if (popen_devnull_fd >= 0) {
		close(popen_devnull_fd);
		popen_devnull_fd = -1;
	}
}

static void
popen_append_to_list(struct popen_handle *handle)
{
	struct popen_handle **old = NULL;
	mh_int_t id = mh_popen_storage_put(popen_hash_table,
		(const struct popen_handle **)&handle, &old, NULL);
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

static struct popen_handle *
popen_data_new()
{
	struct popen_handle *handle =
		(struct popen_handle *)calloc(1, sizeof(*handle));

	if (handle == NULL) {
		diag_set(OutOfMemory, sizeof(*handle),
			 "calloc", "struct popen_handle");
		return NULL;
	}

	handle->fd[0] = -1;
	handle->fd[1] = -1;
	handle->fd[2] = -1;

	fiber_cond_create(&handle->sigchld_cond);
	return handle;
}

void
popen_data_free(struct popen_handle *handle)
{
	fiber_cond_destroy(&handle->sigchld_cond);
	free(handle);
}

static int
popen_get_devnull()
{
	if (popen_devnull_fd < 0) {
		popen_devnull_fd = open("/dev/null", O_RDWR | O_CLOEXEC);
	}

	return popen_devnull_fd;
}

enum pipe_end {
	PIPE_READ = 0,
	PIPE_WRITE = 1
};

static inline bool
popen_prepare_fd(int fd, int *pipe_pair, enum pipe_end parent_end)
{
	if (fd == FIO_PIPE) {
		if (pipe(pipe_pair) < 0 ||
		    fcntl(pipe_pair[parent_end], F_SETFL, O_NONBLOCK) < 0) {
			return false;
		}
	}
	return true;
}

static inline void
popen_setup_parent_fd(int std_fd, int *pipe_pair,
	int *saved_fd, enum pipe_end child_end)
{
	if (std_fd == FIO_PIPE) {
		/* Close child's end. */
		close(pipe_pair[child_end]);

		enum pipe_end parent_end = (child_end == PIPE_READ)
			? PIPE_WRITE
			: PIPE_READ;
		*saved_fd = pipe_pair[parent_end];
	}
}

static inline void
popen_cleanup_fd(int *pipe_pair)
{
	if (pipe_pair[0] >= 0) {
		close(pipe_pair[0]);
		close(pipe_pair[1]);
	}
}

static void
popen_disable_signals(sigset_t *prev)
{
	sigset_t sigset;
	sigfillset(&sigset);
	sigemptyset(prev);
	if (pthread_sigmask(SIG_BLOCK, &sigset, prev) == -1)
		say_syserror("sigprocmask off");
}

static void
popen_restore_signals(sigset_t *prev)
{
	if (pthread_sigmask(SIG_SETMASK, prev, NULL) == -1)
		say_syserror("sigprocmask on");
}

static void
popen_reset_signals()
{
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
}

struct popen_handle *
popen_new(char **argv, char **env,
	int stdin_fd, int stdout_fd, int stderr_fd)
{
	pid_t pid;
	int pipe_stdin[2] = {-1,-1};
	int pipe_stdout[2] = {-1,-1};
	int pipe_stderr[2] = {-1,-1};
	errno = 0;

	struct popen_handle *handle = popen_data_new();
	if (handle == NULL)
		return NULL;

	/*
	 * Setup a /dev/null if necessary.
	 */
	if (stdin_fd == FIO_DEVNULL)
		stdin_fd = popen_get_devnull();
	if (stdout_fd == FIO_DEVNULL)
		stdout_fd = popen_get_devnull();
	if (stderr_fd == FIO_DEVNULL)
		stderr_fd = popen_get_devnull();

	if (!popen_prepare_fd(stdin_fd, pipe_stdin, PIPE_WRITE))
		goto on_error;
	if (!popen_prepare_fd(stdout_fd, pipe_stdout, PIPE_READ))
		goto on_error;
	if (!popen_prepare_fd(stderr_fd, pipe_stderr, PIPE_READ))
		goto on_error;

	/*
	 * Prepare data for the child process.
	 * There must be no branches, to avoid compiler
	 * error: "argument ‘xxx’ might be clobbered by
	 * ‘longjmp’ or ‘vfork’ [-Werror=clobbered]".
	 */
	if (env == NULL)
		env = environ;

	/* Handles to be closed in child process */
	int close_fd[3] = {-1, -1, -1};
	/* Handles to be duplicated in child process */
	int dup_fd[3] = {-1, -1, -1};
	/* Handles to be closed after dup2 in child process */
	int close_after_dup_fd[3] = {-1, -1, -1};

	if (stdin_fd == FIO_PIPE) {
		close_fd[STDIN_FILENO] = pipe_stdin[PIPE_WRITE];
		dup_fd[STDIN_FILENO] = pipe_stdin[PIPE_READ];
	} else if (stdin_fd != STDIN_FILENO) {
		dup_fd[STDIN_FILENO] = stdin_fd;
		close_after_dup_fd[STDIN_FILENO] = stdin_fd;
	}

	if (stdout_fd == FIO_PIPE) {
		close_fd[STDOUT_FILENO] = pipe_stdout[PIPE_READ];
		dup_fd[STDOUT_FILENO] = pipe_stdout[PIPE_WRITE];
	} else if (stdout_fd != STDOUT_FILENO){
		dup_fd[STDOUT_FILENO] = stdout_fd;
		if (stdout_fd != STDERR_FILENO)
			close_after_dup_fd[STDOUT_FILENO] = stdout_fd;
	}

	if (stderr_fd == FIO_PIPE) {
		close_fd[STDERR_FILENO] = pipe_stderr[PIPE_READ];
		dup_fd[STDERR_FILENO] = pipe_stderr[PIPE_WRITE];
	} else if (stderr_fd != STDERR_FILENO) {
		dup_fd[STDERR_FILENO] = stderr_fd;
		if (stderr_fd != STDOUT_FILENO)
			close_after_dup_fd[STDERR_FILENO] = stderr_fd;
	}

	sigset_t prev_sigset;
	popen_disable_signals(&prev_sigset);

	pid = vfork();

	if (pid < 0)
		goto on_error;
	else if (pid == 0) /* child */ {
		popen_reset_signals();

		/* Setup stdin/stdout */
		for(int i = 0; i < 3; ++i) {
			if (close_fd[i] >= 0)
				close(close_fd[i]);
			if (dup_fd[i] >= 0)
				dup2(dup_fd[i], i);
			if (close_after_dup_fd[i] >= 0)
				close(close_after_dup_fd[i]);
		}

		execve( argv[0], argv, env);
		exit(EX_OSERR);
		unreachable();
	}

	popen_restore_signals(&prev_sigset);

	/* Parent process */
	popen_setup_parent_fd(stdin_fd, pipe_stdin,
			      &handle->fd[STDIN_FILENO], PIPE_READ);
	popen_setup_parent_fd(stdout_fd, pipe_stdout,
			      &handle->fd[STDOUT_FILENO], PIPE_WRITE);
	popen_setup_parent_fd(stderr_fd, pipe_stderr,
			      &handle->fd[STDERR_FILENO], PIPE_WRITE);

	handle->pid = pid;

on_cleanup:
	if (handle){
		popen_append_to_list(handle);
	}

	return handle;

on_error:
	popen_cleanup_fd(pipe_stdin);
	popen_cleanup_fd(pipe_stdout);
	popen_cleanup_fd(pipe_stderr);

	if (handle) {
		popen_data_free(handle);
	}
	handle = NULL;

	goto on_cleanup;
	unreachable();
}

static void
popen_close_fds(struct popen_handle *handle)
{
	for(int i = 0; i < 3; ++i) {
		if (handle->fd[i] >= 0) {
			close(handle->fd[i]);
			handle->fd[i] = -1;
		}
	}
}

int
popen_destroy(struct popen_handle *handle)
{
	assert(handle);

	popen_close_fds(handle);
	mh_popen_storage_remove(popen_hash_table,
				(const struct popen_handle **)&handle, NULL);

	popen_data_free(handle);
	return 0;
}

int
popen_close(struct popen_handle *handle, int fd)
{
	assert(handle);

	errno = 0;

	if (fd < 0)
		popen_close_fds(handle);
	else if (STDIN_FILENO <= fd && fd <= STDERR_FILENO){
		if (handle->fd[fd] >= 0) {
			close(handle->fd[fd]);
			handle->fd[fd] = -1;
		}

	} else {
		errno = EINVAL;
		return -1;
	}

	return 0;
}

/**
 * Check if an errno, returned from a io functions, means a
 * non-critical error: EAGAIN, EWOULDBLOCK, EINTR.
 */
static inline bool
popen_wouldblock(int err)
{
	return err == EAGAIN || err == EWOULDBLOCK || err == EINTR;
}

static ssize_t
popen_do_read(struct popen_handle *handle, void *buf, size_t count,
	int *source_id)
{
	/*
	 * STDERR has higher priority, read it first.
	 */
	ssize_t rc = 0;
	errno = 0;
	int fd_count = 0;
	if (handle->fd[STDERR_FILENO] >= 0) {
		++fd_count;
		rc = read(handle->fd[STDERR_FILENO], buf, count);

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
	if (handle->fd[STDOUT_FILENO] >= 0) {
		++fd_count;
		rc = read(handle->fd[STDOUT_FILENO], buf, count);

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

static inline void
popen_coio_create(struct ev_io *coio)
{
	coio->data = fiber();
	ev_init(coio, (ev_io_cb) fiber_schedule_cb);
}

ssize_t
popen_read(struct popen_handle *handle, void *buf, size_t count,
	int *source_id,
	double timeout)
{
	assert(handle);
	assert (timeout >= 0.0);

	ev_tstamp start, delay;
	evio_timeout_init(loop(), &start, &delay, timeout);

	struct ev_io coio_stdout;
	struct ev_io coio_stderr;
	popen_coio_create(&coio_stderr);
	popen_coio_create(&coio_stdout);

	int result = 0;

	while (true) {
		ssize_t rc = popen_do_read(handle, buf, count, source_id);
		if (rc >= 0) {
			result = rc;
			break;
		}

		if (!popen_wouldblock(errno)) {
			result = -1;
			break;
		}

		/*
		 * The descriptors are not ready, yield.
		 */
		if (!ev_is_active(&coio_stdout) &&
		     handle->fd[STDOUT_FILENO] >= 0) {
			ev_io_set(&coio_stdout, handle->fd[STDOUT_FILENO],
				EV_READ);
			ev_io_start(loop(), &coio_stdout);
		}
		if (!ev_is_active(&coio_stderr) &&
		    handle->fd[STDERR_FILENO] >= 0) {
			ev_io_set(&coio_stderr, handle->fd[STDERR_FILENO],
				EV_READ);
			ev_io_start(loop(), &coio_stderr);
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
			diag_set(FiberIsCancelled);
			result = -1;
			break;
		}

		evio_timeout_update(loop(), &start, &delay);
	}

	ev_io_stop(loop(), &coio_stderr);
	ev_io_stop(loop(), &coio_stdout);
	return result;
}

int
popen_write(struct popen_handle *handle, const void *buf, size_t count,
	size_t *written, double timeout)
{
	assert(handle);
	assert(timeout >= 0.0);

	if (count == 0) {
		*written = 0;
		return  0;
	}

	if (handle->fd[STDIN_FILENO] < 0) {
		*written = 0;
		errno = EBADF;
		return -1;
	}

	ev_tstamp start, delay;
	evio_timeout_init(loop(), &start, &delay, timeout);

	struct ev_io coio;
	popen_coio_create(&coio);
	int result = 0;

	while(true) {
		ssize_t rc = write(handle->fd[STDIN_FILENO], buf, count);
		if (rc < 0 && !popen_wouldblock(errno)) {
			result = -1;
			break;
		}

		if (rc > 0) {
			buf += rc;
			*written += rc;
			count -= rc;
			if (count == 0)
				break;
		}

		/*
		 * The descriptors are not ready, yield.
		 */
		if (!ev_is_active(&coio)) {
			ev_io_set(&coio, handle->fd[STDIN_FILENO], EV_WRITE);
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
			diag_set(FiberIsCancelled);
			result = -1;
			break;
		}

		evio_timeout_update(loop(), &start, &delay);
	}

	ev_io_stop(loop(), &coio);
	return result;
}

int
popen_kill(struct popen_handle *handle, int signal_id)
{
	assert(handle);
	if (handle->terminated){
		errno = ESRCH;
		return -1;
	}

	return kill(handle->pid, signal_id);
}

int
popen_wait(struct popen_handle *handle, double timeout)
{
	assert(handle);
	assert(timeout >= 0.0);

	while(!fiber_is_cancelled())
	{
		if (popen_get_status(handle, NULL))
			return 0;

		if (fiber_cond_wait_timeout(&handle->sigchld_cond,
			timeout) != 0) {
			errno = ETIMEDOUT;
			return -1;
		}
	}
	diag_set(FiberIsCancelled);
	return -1;
}

int
popen_get_std_file_handle(struct popen_handle *handle, int file_no)
{
	assert(handle);
	if (file_no < STDIN_FILENO || STDERR_FILENO < file_no){
		errno = EINVAL;
		return -1;
	}

	errno = 0;
	return handle->fd[file_no];
}

bool
popen_get_status(struct popen_handle *handle, int *status)
{
	assert(handle);
	errno = 0;

	if (status)
		*status = handle->status;

	return handle->terminated;
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

	struct popen_handle *handle = popen_lookup_data_by_pid(watcher->rpid);
	if (handle) {
		if (WIFEXITED(watcher->rstatus)) {
			handle->status = WEXITSTATUS(watcher->rstatus);
		} else if (WIFSIGNALED(watcher->rstatus)) {
			handle->status = -WTERMSIG(watcher->rstatus);
		} else {
			/*
			 * The status is not determined, treat as exited
			 */
			handle->status = EX_SOFTWARE;
		}
		handle->terminated = true;
		fiber_cond_broadcast(&handle->sigchld_cond);

		/*
		 * We shouldn't close file descriptors here.
		 * The child process may exit earlier than
		 * the parent process finishes reading data.
		 * In this case the reading fails.
		 */
	}
}

static void
popen_setup_sigchld_handler()
{
	ev_child_init (&cw, popen_sigchld_cb, 0/*pid*/, 0);
	ev_child_start(loop(), &cw);

}

static void
popen_reset_sigchld_handler()
{
	ev_child_stop(loop(), &cw);
}
