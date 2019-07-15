#pragma once
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
#include "small/obuf.h"
#include "xrow.h"

enum {
	/**
	 * Xrow buffer contains some count of rotating data chunks.
	 * Every rotation has an estimated decrease in amount of
	 * stored rows at 1/(COUNT OF CHUNKS). A bigger value
	 * makes rotation more frequent, row count decrease
	 * smoother, and size of an xrow buffer more stable.
	 */
	XROW_BUF_CHUNK_COUNT = 16,
};

/**
 * Description of a row stored in an xrow buffer. The main
 * purpose - access to the not encoded header for filtering, and
 * keeping of pointers at encoded data in the buffer.
 */
struct xrow_buf_row_info {
	/**
	 * The original xrow, with encoded body pointing at a
	 * chunk in an xrow buffer.
	 */
	struct xrow_header xrow;
};

/** Chunk is a continuous sequence of xrows. */
struct xrow_buf_chunk {
	/**
	 * Vclock just before the first row in this chunk. It is
	 * used for fast search of a chunk by a known vclock.
	 */
	struct vclock vclock;
	/** Stored rows information array. */
	struct xrow_buf_row_info *row_info;
	/** Count of stored rows. */
	size_t row_count;
	/** Capacity of stored rows information array. */
	size_t row_capacity;
	/** Data storage for encoded rows data. */
	struct obuf data;
};

/**
 * Xrow buffer allows to encode and store continuous sequence of
 * xrows. Storage is organized as a range of globally indexed
 * chunks. New rows are appended to the last chunk (the youngest
 * one). If the last chunk is already full then a new chunk will
 * be used. Xrow_buffer maintains not more than
 * XROW_BUF_CHUNK_COUNT chunks so when the buffer becomes full, a
 * first one chunk is cleared and reused. All chunks are organized
 * in a ring  so a chunk in-ring index could be evaluated from the
 * chunk global index with the modulo operation.
 */
struct xrow_buf {
	/**
	 * Global index of the first used chunk (the oldest one).
	 */
	size_t first_chunk_index;
	/**
	 * Global index of the last used chunk (the youngest one).
	 */
	size_t last_chunk_index;
	/** Ring with chunks. */
	struct xrow_buf_chunk chunk[XROW_BUF_CHUNK_COUNT];
	/**
	 * A xrow_buf transaction is encoded into one chunk only.
	 * When transaction is started, current state of the
	 * buffer is saved in order to be able to rollback it if
	 * something goes wrong before the transaction is
	 * finished.
	 */
	uint32_t saved_row_count;
	/** The current transaction encoded data start svp. */
	struct obuf_svp saved_obuf;
};

/** Create xrow buffer. */
void
xrow_buf_create(struct xrow_buf *buf);

/** Destroy xrow buffer. */
void
xrow_buf_destroy(struct xrow_buf *buf);

/**
 * Begin an xrow buffer transaction. The buffer operates in
 * transactions. Transaction here means a contiguously encoded
 * sequence of xrows. Transactions are committed, when the encoded
 * buffers reach the disk. It protects from reading encoded but
 * not persisted rows.
 * Begin may rotate the last chunk and use the vclock parameter as
 * a new chunk's starting point.
 */
void
xrow_buf_tx_begin(struct xrow_buf *buf, const struct vclock *vclock);

/** Discard all the data was written after the last transaction. */
void
xrow_buf_tx_rollback(struct xrow_buf *buf);

/** Commit a xrow buffer transaction. */
void
xrow_buf_tx_commit(struct xrow_buf *buf);

/**
 * Append an xrow to the buffer memory. @a iov parameter is used
 * to encode the row on a region. The xrow buffer does not depend
 * on it, but @a iov can be used later by xlog to write it to its
 * own buffer without re-encoding of the row.
 *
 * @retval >0 Result size of @a iov.
 * @retval -1 Error.
 */
int
xrow_buf_write_row(struct xrow_buf *buf, struct xrow_header *row,
		   struct iovec *iov);
