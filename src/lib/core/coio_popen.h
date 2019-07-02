#ifndef TARANTOOL_LIB_CORE_COIO_POPEN_H_INCLUDED
#define TARANTOOL_LIB_CORE_COIO_POPEN_H_INCLUDED
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

#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */

#include <stdarg.h>
#include <sys/types.h>
#include <stdbool.h>

/**
 * Special values of the file descriptors passed to fio.popen
 */
enum {
	/**
	 * Tells fio.popen to open a handle for
	 * direct reading/writing.
	 */
	FIO_PIPE = -2,

	/**
	 * Tells fio.popen to redirect the given standard
	 * stream into /dev/null.
	 */
	FIO_DEVNULL = -3
};

struct popen_handle;

/**
 * Initializes inner data of fio.popen
 */
void
popen_init();

/**
 * Release resources acquired by fio.popen
 */
void
popen_free();

/**
 * The function opens a process by creating a pipe
 * forking.
 *
 * @param argv - is an array of character pointers
 * to the arguments terminated by a null pointer.
 *
 * @param env - is the pointer to an array
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
struct popen_handle *
popen_new(char **argv, char **env,
	int stdin_fd, int stdout_fd, int stderr_fd);

/**
 * The function releases allocated resources.
 * The function doesn't wait for the associated process
 * to terminate.
 *
 * @param handle - a handle returned by fio.popen.
 *
 * @return 0 if the process is terminated
 * @return -1 for an error
 */
int
popen_destroy(struct popen_handle *handle);

/**
 * The function closes the specified file descriptor.
 *
 * @param handle a handle returned by fio.popen.
 * @param fd file descriptor to be closed.
 * If fd = -1 then all open descriptors are
 * being closed.
 * The function doesn't change the state of
 * the associated process.
 *
 * @return 0 on success
 * @return -1 if input parameters are wrong.
 */
int
popen_close(struct popen_handle *handle, int fd);


/**
 * The function reads up to count bytes from the handle
 * associated with the child process.
 * Returns immediately
 *
 * @param handle a handle returned by fio.popen.
 * @param buf a buffer to be read into
 * @param count size of buffer in bytes
 * @param source_id A pointer to the variable that receives a
 * source stream id, 1 - for STDOUT, 2 - for STDERR.
 *
 * @return on success returns number of bytes read (>= 0)
 * @return -1 on error, see errno for error code
 *
 * On timeout function returns -1
 * and errno set to ETIMEDOUT.
 */
ssize_t
popen_read(struct popen_handle *handle, void *buf, size_t count,
	int *source_id,
	double timeout);

/**
 * The function writes up to count bytes to the handle
 * associated with the child process.
 * Tries to write as much as possible without blocking
 * and immediately returns.
 *
 * @param handle a handle returned by fio.popen.
 * @param buf a buffer to be written from
 * @param count size of buffer in bytes
 * @param written A pointer to the
 * variable that receives the number of bytes actually written.
 * If function fails the number of written bytes is undefined.
 *
 * @return 0 data were successfully written
 * Compare values of <count> and <written> to check
 * whether all data were written or not.
 * @return -1 an error occurred, see errno for error code
 *
 * On timeout, function returns -1
 * and errno set no ETIMEDOUT. The 'written' contains number
 * of written bytes before timeout.
 */
int
popen_write(struct popen_handle *handle, const void *buf, size_t count,
	size_t *written, double timeout);


/**
 * The function send the specified signal
 * to the associated process.
 *
 * @param handle a handle returned by fio.popen.
 *
 * @return 0 on success
 * @return -1 an error occurred, see errno for error code
 */
int
popen_kill(struct popen_handle *handle, int signal_id);

/**
 * Wait for the associated process to terminate.
 * The function doesn't release the allocated resources.
 *
 * If associated process is terminated the function returns immediately.
 *
 * @param handle a handle returned by fio.popen.
 *
 * @param timeout number of second to wait before function exit with error.
 * If function exited due to timeout the errno equals to ETIMEDOUT.
 *
 * @return On success function returns 0, and -1 on error.
 */
int
popen_wait(struct popen_handle *handle, double timeout);

/**
 * Returns descriptor of the specified file.
 *
 * @param handle a handle returned by fio.popen.
 * @param file_no accepts one of the
 * following values:
 * STDIN_FILENO,
 * STDOUT_FILENO,
 * STDERR_FILENO
 *
 * @return file descriptor or -1 if not available
 */
int
popen_get_std_file_handle(struct popen_handle *handle, int file_no);


/**
 * Returns status of the associated process.
 *
 * @param handle a handle returned by fio.popen.
 *
 * @param status if not NULL accepts the exit code
 * if the process terminated normally or -signal id
 * if process was terminated by signal.
 *
 * @return false if process is alive and
 * true if process was terminated
 */
bool
popen_get_status(struct popen_handle *handle, int *status);

#if defined(__cplusplus)
} /* extern "C" */
#endif /* defined(__cplusplus) */

#endif /* TARANTOOL_LIB_CORE_COIO_POPEN_H_INCLUDED */
