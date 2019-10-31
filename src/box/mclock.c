/*
 * Copyright 2010-2016, Tarantool AUTHORS, please see AUTHORS file.
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
#include "mclock.h"

void
mclock_create(struct mclock *mclock)
{
	memset(mclock, 0, sizeof(struct mclock));
}

void
mclock_destroy(struct mclock *mclock)
{
	memset(mclock, 0, sizeof(struct mclock));
}

int
mclock_attach(struct mclock *mclock, uint32_t id, const struct vclock *vclock)
{
	if (mclock->row_map & (1 << id)) {
		/* Replica is already attached. */
		return mclock_update(mclock, id, vclock);;
	}
	vclock_create(&mclock->vclock[id]);
	mclock->row_map |= 1 << id;
	uint32_t count = __builtin_popcount(mclock->row_map);
	struct bit_iterator col_map_it;
	bit_iterator_init(&col_map_it, &mclock->col_map, sizeof(mclock->col_map), true);
	for (size_t col_id = bit_iterator_next(&col_map_it); col_id < SIZE_MAX;
	     col_id = bit_iterator_next(&col_map_it)) {
		mclock->order[col_id][count - 1] = id;
	}
	mclock_update(mclock, id, vclock);
	return 0;
}

void
mclock_detach(struct mclock *mclock, uint32_t id)
{
	(void) mclock;
	(void) id;
}

static void
mclock_adjust_col_map(struct mclock *mclock, uint32_t id,
		      const struct vclock *vclock)
{
	uint32_t new_col_map = vclock->map & ~mclock->col_map;
	struct bit_iterator col_map_it;
	bit_iterator_init(&col_map_it, &new_col_map, sizeof(new_col_map), true);
	for (size_t col_id = bit_iterator_next(&col_map_it); col_id < SIZE_MAX;
	     col_id = bit_iterator_next(&col_map_it)) {
		mclock->col_map |= (1 << col_id);
		struct bit_iterator row_map_it;
		bit_iterator_init(&row_map_it, &mclock->row_map,
				  sizeof(mclock->row_map), true);
		for (size_t row_id = bit_iterator_next(&row_map_it), i = 1;
		     row_id < SIZE_MAX;
		     row_id = bit_iterator_next(&row_map_it)) {
			if (row_id != id)
				mclock->order[col_id][i++] = row_id;
		}
		mclock->order[col_id][0] = id;
	}
}

int
mclock_update(struct mclock *mclock, uint32_t id, const struct vclock *vclock)
{
	uint32_t count = __builtin_popcount(mclock->row_map);
	mclock_adjust_col_map(mclock, id, vclock);
	struct bit_iterator col_map_it;
	bit_iterator_init(&col_map_it, &mclock->col_map, sizeof(mclock->col_map), true);
	for (size_t col_id = bit_iterator_next(&col_map_it); col_id < SIZE_MAX;
	     col_id = bit_iterator_next(&col_map_it)) {
		int64_t new_lsn = vclock_get(vclock, col_id);
		if (vclock_get(mclock->vclock + id, col_id) == new_lsn)
			continue;
		int32_t old_pos = -1, new_pos = count - 1, pos = count;
		do {
			--pos;
			uint32_t replica_id = mclock->order[col_id][pos];
			if (replica_id == id)
				old_pos = pos;
			if (vclock_get(mclock->vclock + replica_id, col_id) <
			    new_lsn)
				new_pos = pos;
		} while (pos > 0);
		assert(old_pos != -1);
		if (old_pos == new_pos)
			continue;
		if (old_pos > new_pos) {
			memmove(mclock->order[col_id] + new_pos + 1,
				mclock->order[col_id] + new_pos,
				(old_pos - new_pos) * sizeof(**mclock->order));
		} else {
			memmove(mclock->order[col_id] + old_pos,
				mclock->order[col_id] + old_pos + 1,
				(new_pos - old_pos) * sizeof(**mclock->order));
		}
		mclock->order[col_id][new_pos] = id;
			continue;
	}
	vclock_copy(&mclock->vclock[id], vclock);
	return 0;
}

int
mclock_get(struct mclock *mclock, int32_t offset, struct vclock *vclock)
{
	int32_t count = __builtin_popcount(mclock->row_map);
	if (offset >= count || offset < -count) {
		vclock_clear(vclock);
		return -1;
	}
	offset = (offset + count) % count;
	vclock_create(vclock);
	struct bit_iterator col_map_it;
	bit_iterator_init(&col_map_it, &mclock->col_map, sizeof(mclock->col_map), true);
	for (size_t col_id = bit_iterator_next(&col_map_it); col_id < SIZE_MAX;
	     col_id = bit_iterator_next(&col_map_it)) {
		uint32_t row_id = mclock->order[col_id][offset];
		int64_t lsn = vclock_get(mclock->vclock + row_id, col_id);
		if (lsn > 0)
			vclock_follow(vclock, col_id, lsn);
	}
	return 0;
}

