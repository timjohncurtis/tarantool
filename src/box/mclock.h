#ifndef INCLUDES_TARANTOOL_MCLOCK_H
#define INCLUDES_TARANTOOL_MCLOCK_H
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
#include <stdlib.h>

#include "vclock.h"

#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */

/* Clock matrix. */
struct mclock {
	/* Map of attached replicas. */
	unsigned int row_map;
	/* Map of known replicas. */
	unsigned int col_map;
	struct vclock vclock[VCLOCK_MAX];
	uint8_t order[VCLOCK_MAX][VCLOCK_MAX];
};

void
mclock_create(struct mclock *mclock);

void
mclock_destroy(struct mclock *mclock);

int
mclock_attach(struct mclock *mclock, uint32_t id, const struct vclock *vclock);

void
mclock_detach(struct mclock *mclock, uint32_t id);

int
mclock_update(struct mclock *mclock, uint32_t id, const struct vclock *vclock);

#if defined(__cplusplus)
} /* extern "C" */
#endif /* defined(__cplusplus) */

#endif /* INCLUDES_TARANTOOL_MCLOCK_H */
