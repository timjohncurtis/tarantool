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

#include "evio.h"
#include <stdarg.h>

/**
 * Special values of the file descriptors passed to fio.popen
 * */
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
 * Possible status of the process started via fio.popen
 **/
enum popen_status {

	/**
	 * The process is alive and well.
	 */
	POPEN_RUNNING = 1,

	/**
	 * The process exited.
	 */
	POPEN_EXITED = 2,

	/**
	 * The process terminated by a signal.
	 */
	POPEN_KILLED = 3,

	/**
	 * The process terminated abnormally.
	 */
	POPEN_DUMPED = 4
};

/**
 * Initializes inner data of fio.popen
 * */
void
popen_initialize();

ssize_t
popen_new(va_list ap);

/**
 * The function releases allocated resources.
 * The function doesn't wait for the associated process
 * to terminate.
 *
 * @param fh handle returned by fio.popen.
 *
 * @return 0 if the process is terminated
 * @return -1 for an error
 */
int
popen_destroy(struct popen_handle *fh);

/**
 * The function reads up to count bytes from the handle
 * associated with the child process.
 * Returns immediately
 *
 * @param fd handle returned by fio.popen.
 * @param buf a buffer to be read into
 * @param count size of buffer in bytes
 * @param read_bytes A pointer to the
 * variable that receives the number of bytes read.
 * @param source_id A pointer to the variable that receives a
 * source stream id, 1 - for STDOUT, 2 - for STDERR.
 *
 * @return 0 data were successfully read
 * @return -1 an error occurred, see errno for error code
 *
 * If there is nothing to read yet function returns -1
 * and errno set no EAGAIN.
 */
int
popen_read(struct popen_handle *fh, void *buf, size_t count,
	size_t *read_bytes, int *source_id,
	ev_tstamp timeout);

/**
 * The function writes up to count bytes to the handle
 * associated with the child process.
 * Tries to write as much as possible without blocking
 * and immediately returns.
 *
 * @param fd handle returned by fio.popen.
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
 * If the writing can block, function returns -1
 * and errno set no EAGAIN.
 */
int
popen_write(struct popen_handle *fh, const void *buf, size_t count,
	size_t *written, ev_tstamp timeout);


/**
 * The function send the specified signal
 * to the associated process.
 *
 * @param fd - handle returned by fio.popen.
 *
 * @return 0 on success
 * @return -1 an error occurred, see errno for error code
 */
int
popen_kill(struct popen_handle *fh, int signal_id);

/**
 * Wait for the associated process to terminate.
 * The function doesn't release the allocated resources.
 *
 * @param fd handle returned by fio.popen.
 *
 * @param timeout number of second to wait before function exit with error.
 * If function exited due to timeout the errno equals to ETIMEDOUT.
 *
 * @exit_code On success contains the exit code as a positive number
 * or signal id as a negative number.

 * @return On success function returns 0, and -1 on error.
 */
int
popen_wait(struct popen_handle *fh, ev_tstamp timeout, int *exit_code);

/**
 * Returns descriptor of the specified file.
 *
 * @param fd - handle returned by fio.popen.
 * @param file_no accepts one of the
 * following values:
 * STDIN_FILENO,
 * STDOUT_FILENO,
 * STDERR_FILENO
 *
 * @return file descriptor or -1 if not available
 */
int
popen_get_std_file_handle(struct popen_handle *fh, int file_no);


/**
 * Returns status of the associated process.
 *
 * @param fd - handle returned by fio.popen.
 *
 * @param exit_code - if not NULL accepts the exit code
 * if the process terminated normally or signal id
 * if process was termianted by signal.
 *
 * @return one of the following values:
 * POPEN_RUNNING if the process is alive
 * POPEN_EXITED if the process was terminated normally
 * POPEN_KILLED if the process was terminated by a signal
 */
int
popen_get_status(struct popen_handle *fh, int *exit_code);

void
popen_setup_sigchld_handler();
void
popen_reset_sigchld_handler();

#if defined(__cplusplus)
} /* extern "C" */
#endif /* defined(__cplusplus) */

#endif /* TARANTOOL_LIB_CORE_COIO_POPEN_H_INCLUDED */
