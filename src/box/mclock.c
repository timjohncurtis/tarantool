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
	uint32_t attached = __builtin_popcount(mclock->row_map);
	mclock->row_map |= 1 << id;
	/* Put given vclock in the last position. */
	struct bit_iterator col_map_it;
	bit_iterator_init(&col_map_it, &mclock->col_map, sizeof(mclock->col_map), true);
	for (size_t col_id = bit_iterator_next(&col_map_it); col_id < SIZE_MAX;
	     col_id = bit_iterator_next(&col_map_it)) {
		mclock->order[col_id][attached] = id;
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

int
mclock_update(struct mclock *mclock, uint32_t id, const struct vclock *vclock)
{
	uint32_t count = __builtin_popcount(mclock->row_map);
	struct vclock_iterator it;
	vclock_iterator_init(&it, vclock);
	vclock_foreach(&it, item) {
		if (vclock_get(mclock->vclock + id, item.id) == item.lsn)
			continue;
		uint32_t old_pos, new_pos = 0;
		if (!(mclock->col_map & (1 << item.id))) {
			struct bit_iterator row_map_it;
			bit_iterator_init(&row_map_it, &mclock->row_map, sizeof(mclock->row_map), true);
			for (size_t row_id = bit_iterator_next(&row_map_it), i = 0; row_id < SIZE_MAX;
			     row_id = bit_iterator_next(&row_map_it), ++i) {
				mclock->order[item.id][i] = row_id;
			}
			mclock->col_map |= (1 << item.id);
		}
		for (uint32_t i = 0; i < count; ++i) {
			uint32_t replica_id = mclock->order[item.id][i];
			if (replica_id == id)
				old_pos = i;
			if (vclock_get(mclock->vclock + replica_id, item.id) > item.lsn)
				new_pos = i;
		}
		if (old_pos == new_pos)
			continue;
		if (old_pos > new_pos) {
			memmove(mclock->order[item.id] + new_pos + 1,
				mclock->order[item.id] + new_pos,
				(old_pos - new_pos) * sizeof(**mclock->order));
		} else {
			memmove(mclock->order[item.id] + old_pos,
				mclock->order[item.id] + old_pos + 1,
				(new_pos - old_pos) * sizeof(**mclock->order));
		}
		mclock->order[item.id][new_pos] = id;
	}
	vclock_copy(&mclock->vclock[id], vclock);
	return 0;
}


