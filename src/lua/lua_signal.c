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
#define PUSHTABLE(name, method, value)	{	\
	lua_pushliteral(L, name);		\
	method(L, value);			\
	lua_settable(L, -3);			\
}
#endif /*PUSHTABLE*/

void
tarantool_lua_signal_init(struct lua_State *L)
{
	static const struct luaL_Reg signal_methods[] = {
		{ NULL,	NULL }
	};

	luaL_register_module(L, "signal", signal_methods);

	lua_pushliteral(L, "c");
	lua_newtable(L);

	lua_pushliteral(L, "signals");
	lua_newtable(L);

#ifdef SIGINT
	PUSHTABLE("SIGINT", lua_pushinteger, SIGINT);
#endif
#ifdef SIGILL
	PUSHTABLE("SIGILL", lua_pushinteger, SIGILL);
#endif
#ifdef SIGABRT
	PUSHTABLE("SIGABRT", lua_pushinteger, SIGABRT);
#endif
#ifdef SIGFPE
	PUSHTABLE("SIGFPE", lua_pushinteger, SIGFPE);
#endif
#ifdef SIGSEGV
	PUSHTABLE("SIGSEGV", lua_pushinteger, SIGSEGV);
#endif
#ifdef SIGTERM
	PUSHTABLE("SIGTERM", lua_pushinteger, SIGTERM);
#endif

#ifdef SIGHUP
	PUSHTABLE("SIGHUP", lua_pushinteger, SIGHUP);
#endif
#ifdef SIGQUIT
	PUSHTABLE("SIGQUIT", lua_pushinteger, SIGQUIT);
#endif
#ifdef SIGTRAP
	PUSHTABLE("SIGTRAP", lua_pushinteger, SIGTRAP);
#endif
#ifdef SIGKILL
	PUSHTABLE("SIGKILL", lua_pushinteger, SIGKILL);
#endif
#ifdef SIGBUS
	PUSHTABLE("SIGBUS", lua_pushinteger, SIGBUS);
#endif
#ifdef SIGSYS
	PUSHTABLE("SIGSYS", lua_pushinteger, SIGSYS);
#endif
#ifdef SIGPIPE
	PUSHTABLE("SIGPIPE", lua_pushinteger, SIGPIPE);
#endif
#ifdef SIGALRM
	PUSHTABLE("SIGALRM", lua_pushinteger, SIGALRM);
#endif

#ifdef SIGURG
	PUSHTABLE("SIGURG", lua_pushinteger, SIGURG);
#endif
#ifdef SIGSTOP
	PUSHTABLE("SIGSTOP", lua_pushinteger, SIGSTOP);
#endif
#ifdef SIGTSTP
	PUSHTABLE("SIGTSTP", lua_pushinteger, SIGTSTP);
#endif
#ifdef SIGCONT
	PUSHTABLE("SIGCONT", lua_pushinteger, SIGCONT);
#endif
#ifdef SIGCHLD
	PUSHTABLE("SIGCHLD", lua_pushinteger, SIGCHLD);
#endif
#ifdef SIGTTIN
	PUSHTABLE("SIGTTIN", lua_pushinteger, SIGTTIN);
#endif
#ifdef SIGTTOU
	PUSHTABLE("SIGTTOU", lua_pushinteger, SIGTTOU);
#endif
#ifdef SIGPOLL
	PUSHTABLE("SIGPOLL", lua_pushinteger, SIGPOLL);
#endif
#ifdef SIGXCPU
	PUSHTABLE("SIGXCPU", lua_pushinteger, SIGXCPU);
#endif
#ifdef SIGXFSZ
	PUSHTABLE("SIGXFSZ", lua_pushinteger, SIGXFSZ);
#endif
#ifdef SIGVTALRM
	PUSHTABLE("SIGVTALRM", lua_pushinteger, SIGVTALRM);
#endif
#ifdef SIGPROF
	PUSHTABLE("SIGPROF", lua_pushinteger, SIGPROF);
#endif
#ifdef SIGUSR1
	PUSHTABLE("SIGUSR1", lua_pushinteger, SIGUSR1);
#endif
#ifdef SIGUSR2
	PUSHTABLE("SIGUSR2", lua_pushinteger, SIGUSR2);
#endif
	lua_settable(L, -3); /* "signals" */

	lua_settable(L, -3); /* "c" */
	lua_pop(L, 1);
}
