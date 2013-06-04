#ifndef TARANTOOL_BOX_TREE_INDEX_H_INCLUDED
#define TARANTOOL_BOX_TREE_INDEX_H_INCLUDED
/*
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

#include "index.h"

#include <third_party/sptree.h>

/**
 * Instantiate sptree definitions
 */
SPTREE_DEF(index, realloc);

typedef int (*tree_cmp_t)(const void *, const void *, void *);

class TreeIndex: public Index {
public:
	static TreeIndex *
	factory(struct key_def *key_def, struct space *space);

	virtual void beginBuild();
	virtual void buildNext(struct tuple *tuple);
	virtual void endBuild();
	virtual void build(Index *pk);
	virtual size_t size() const;
	virtual struct tuple *min() const;
	virtual struct tuple *max() const;
	virtual struct tuple *random(u32 rnd) const;
	virtual struct tuple *findByKey(const void *key, u32 part_count) const;
	virtual struct tuple *findByTuple(struct tuple *tuple) const;
	virtual struct tuple *replace(struct tuple *old_tuple,
				      struct tuple *new_tuple,
				      enum dup_replace_mode mode);

	virtual struct iterator *allocIterator() const;
	virtual void initIterator(struct iterator *iterator,
				  enum iterator_type type,
				  const void *key, u32 part_count) const;

// protected:
	/* Needed by iterators */
	virtual size_t node_size() const = 0;
	virtual tree_cmp_t node_cmp() const = 0;
	virtual tree_cmp_t dup_node_cmp() const = 0;
	virtual tree_cmp_t key_node_cmp() const= 0;

	virtual void fold(void *node, struct tuple *tuple) const = 0;
	virtual struct tuple *unfold(const void *node) const = 0;

	sptree_index tree;

protected:
	TreeIndex(struct key_def *key_def, struct space *space);
	virtual ~TreeIndex();
};

#endif /* TARANTOOL_BOX_TREE_INDEX_H_INCLUDED */
