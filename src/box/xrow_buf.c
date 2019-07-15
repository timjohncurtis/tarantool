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
#include "xrow_buf.h"
#include "fiber.h"

/* Xrow buffer chunk options (empirical values). */
enum {
	/* Chunk row info array capacity increment */
	XROW_BUF_CAPACITY_INCREMENT = 16384,
	/* Initial size for raw data storage. */
	XROW_BUF_INITIAL_SIZE = 65536,
	/* How many rows we will place in one buffer. */
	XROW_BUF_ROW_COUNT_THRESHOLD = 8192,
	/* How many data we will place in one buffer. */
	XROW_BUF_SIZE_THRESHOLD = 1 << 19,
};

/*
 * Save the current xrow buffer's chunk state which consists of
 * two values: index and position where the next xrow header and
 * data would be placed. This state is used to track the next
 * transaction starting boundary.
 */
static inline void
xrow_buf_save_state(struct xrow_buf *buf)
{
	struct xrow_buf_chunk *chunk = buf->chunk +
		buf->last_chunk_index % XROW_BUF_CHUNK_COUNT;
	buf->saved_row_count = chunk->row_count;
	buf->saved_obuf = obuf_create_svp(&chunk->data);
}

void
xrow_buf_create(struct xrow_buf *buf)
{
	for (int i = 0; i < XROW_BUF_CHUNK_COUNT; ++i) {
		buf->chunk[i].row_info = NULL;
		buf->chunk[i].row_capacity = 0;
		buf->chunk[i].row_count = 0;
		obuf_create(&buf->chunk[i].data, &cord()->slabc,
			    XROW_BUF_INITIAL_SIZE);
	}
	buf->last_chunk_index = 0;
	buf->first_chunk_index = 0;
	xrow_buf_save_state(buf);
}

void
xrow_buf_destroy(struct xrow_buf *buf)
{
	struct xrow_buf_chunk *chunk = buf->chunk;
	struct xrow_buf_chunk *end = buf->chunk + XROW_BUF_CHUNK_COUNT;
	for (; chunk < end; ++chunk) {
		free(chunk->row_info);
		obuf_destroy(&chunk->data);
	}
}

void
xrow_buf_tx_begin(struct xrow_buf *buf, const struct vclock *vclock)
{
	/*
	 * Xrow buffer fits a transaction in one chunk and does
	 * not rotate the chunk while the transaction is in
	 * progress. Check current chunk thresholds and rotate if
	 * required before the transaction is started.
	 */
	struct xrow_buf_chunk *chunk = buf->chunk +
		buf->last_chunk_index % XROW_BUF_CHUNK_COUNT;

	if (chunk->row_count >= XROW_BUF_ROW_COUNT_THRESHOLD ||
	    obuf_size(&chunk->data) >= XROW_BUF_SIZE_THRESHOLD) {
		++buf->last_chunk_index;
		chunk = buf->chunk +
			buf->last_chunk_index % XROW_BUF_CHUNK_COUNT;
		if (buf->last_chunk_index - buf->first_chunk_index >=
		    XROW_BUF_CHUNK_COUNT) {
			chunk->row_count = 0;
			obuf_reset(&chunk->data);
			++buf->first_chunk_index;
		}
	}
	/*
	 * Each chunk stores vclock of the first row in it to
	 * simplify search by a cursor. It should be updated each
	 * time a chunk is emptied and is going to accept new
	 * rows.
	 */
	vclock_copy(&chunk->vclock, vclock);
	xrow_buf_save_state(buf);
}

void
xrow_buf_tx_rollback(struct xrow_buf *buf)
{
	struct xrow_buf_chunk *chunk = buf->chunk +
		buf->last_chunk_index % XROW_BUF_CHUNK_COUNT;
	chunk->row_count = buf->saved_row_count;
	obuf_rollback_to_svp(&chunk->data, &buf->saved_obuf);
}

void
xrow_buf_tx_commit(struct xrow_buf *buf)
{
	(void) buf;
	/*
	 * Nop. The method is added for consistency with
	 * begin/rollback.
	 */
}

int
xrow_buf_write_row(struct xrow_buf *buf, struct xrow_header *row,
		   struct iovec *iov)
{
	struct xrow_buf_chunk *chunk = buf->chunk +
		buf->last_chunk_index % XROW_BUF_CHUNK_COUNT;
	struct obuf_svp data_svp = obuf_create_svp(&chunk->data);
	size_t size;
	size_t new_row_count = chunk->row_count + 1;
	if (new_row_count > chunk->row_capacity) {
		/*
		 * Allocation up to XROW_BUF_CAPACITY_INCREMENT.
		 */
		const int inc = XROW_BUF_CAPACITY_INCREMENT;
		uint32_t new_capacity =
			inc * ((new_row_count + inc - 1) / inc);
		size = sizeof(chunk->row_info[0]) * new_capacity;
		struct xrow_buf_row_info *new_info =
			(struct xrow_buf_row_info *)
				realloc(chunk->row_info, size);
		if (new_info == NULL) {
			diag_set(OutOfMemory, size, "realloc", "new_info");
			goto error;
		}
		chunk->row_info = new_info;
		chunk->row_capacity = new_capacity;
	}
	char *data = obuf_reserve(&chunk->data, xrow_approx_len(row));
	if (data == NULL) {
		diag_set(OutOfMemory, xrow_approx_len(row), "obuf_reserve",
			 "data");
		goto error;
	}
	int iov_count = xrow_header_encode(row, 0, iov, 0);
	if (iov_count < 0)
		goto error;

	struct xrow_buf_row_info *row_info = chunk->row_info + chunk->row_count;
	struct iovec *target_iov = row_info->xrow.body;
	struct iovec *iov_end = iov + iov_count;
	row_info->xrow = *row;
	/*
	 * The header is copied into the buffer, but is not used
	 * so far.
	 */
	assert(XROW_HEADER_IOVMAX == 1);
	assert(iov_count >= 1);
	data = obuf_alloc(&chunk->data, iov->iov_len);
	memcpy(data, iov->iov_base, iov->iov_len);
	++iov;

	for (; iov < iov_end; ++iov, ++target_iov) {
		data = obuf_alloc(&chunk->data, iov->iov_len);
		memcpy(data, iov->iov_base, iov->iov_len);
		/* Remap region pointers to obuf. */
		target_iov->iov_base = data;
	}
	chunk->row_count = new_row_count;
	return iov_count;
error:
	obuf_rollback_to_svp(&chunk->data, &data_svp);
	return -1;
}
