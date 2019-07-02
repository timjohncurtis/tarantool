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

#include "lua/lua_signal.h"
#include <sys/types.h>
#include <signal.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "lua/utils.h"

#ifndef PUSHTABLE
#define PUSHTABLE(name, value)	{	\
	lua_pushstring(L, name);	\
	lua_pushinteger(L, value);	\
	lua_rawset(L, -3);		\
}
#endif /*PUSHTABLE*/

void
tarantool_lua_signal_init(struct lua_State *L)
{
	static const struct luaL_Reg internal_methods[] = {
		{ NULL,			NULL			}
	};

	luaL_register_module(L, "signal", internal_methods);

#ifdef SIGINT
	PUSHTABLE("SIGINT", SIGINT);
#endif
#ifdef SIGILL
	PUSHTABLE("SIGILL", SIGILL);
#endif
#ifdef SIGABRT
	PUSHTABLE("SIGABRT", SIGABRT);
#endif
#ifdef SIGFPE
	PUSHTABLE("SIGFPE", SIGFPE);
#endif
#ifdef SIGSEGV
	PUSHTABLE("SIGSEGV", SIGSEGV);
#endif
#ifdef SIGTERM
	PUSHTABLE("SIGTERM", SIGTERM);
#endif

#ifdef SIGHUP
	PUSHTABLE("SIGHUP", SIGHUP);
#endif
#ifdef SIGQUIT
	PUSHTABLE("SIGQUIT", SIGQUIT);
#endif
#ifdef SIGTRAP
	PUSHTABLE("SIGTRAP", SIGTRAP);
#endif
#ifdef SIGKILL
	PUSHTABLE("SIGKILL", SIGKILL);
#endif
#ifdef SIGBUS
	PUSHTABLE("SIGBUS", SIGBUS);
#endif
#ifdef SIGSYS
	PUSHTABLE("SIGSYS", SIGSYS);
#endif
#ifdef SIGPIPE
	PUSHTABLE("SIGPIPE", SIGPIPE);
#endif
#ifdef SIGALRM
	PUSHTABLE("SIGALRM", SIGALRM);
#endif

#ifdef SIGURG
	PUSHTABLE("SIGURG", SIGURG);
#endif
#ifdef SIGSTOP
	PUSHTABLE("SIGSTOP", SIGSTOP);
#endif
#ifdef SIGTSTP
	PUSHTABLE("SIGTSTP", SIGTSTP);
#endif
#ifdef SIGCONT
	PUSHTABLE("SIGCONT", SIGCONT);
#endif
#ifdef SIGCHLD
	PUSHTABLE("SIGCHLD", SIGCHLD);
#endif
#ifdef SIGTTIN
	PUSHTABLE("SIGTTIN", SIGTTIN);
#endif
#ifdef SIGTTOU
	PUSHTABLE("SIGTTOU", SIGTTOU);
#endif
#ifdef SIGPOLL
	PUSHTABLE("SIGPOLL", SIGPOLL);
#endif
#ifdef SIGXCPU
	PUSHTABLE("SIGXCPU", SIGXCPU);
#endif
#ifdef SIGXFSZ
	PUSHTABLE("SIGXFSZ", SIGXFSZ);
#endif
#ifdef SIGVTALRM
	PUSHTABLE("SIGVTALRM", SIGVTALRM);
#endif
#ifdef SIGPROF
	PUSHTABLE("SIGPROF", SIGPROF);
#endif
#ifdef SIGUSR1
	PUSHTABLE("SIGUSR1", SIGUSR1);
#endif
#ifdef SIGUSR2
	PUSHTABLE("SIGUSR2", SIGUSR2);
#endif

	lua_pop(L, 1); /* signal */
}
