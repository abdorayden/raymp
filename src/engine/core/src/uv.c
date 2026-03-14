/****************************************************************************************/
/*  Copyright (c) 2025 Ray Den                                                         */
/*                                                                                      */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy        */
/*  of this software and associated documentation files (the "Software"), to deal       */
/*  in the Software without restriction, including without limitation the rights        */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell           */
/*  copies of the Software, and to permit persons to whom the Software is               */
/*  furnished to do so, subject to the following conditions:                            */
/*                                                                                      */
/*  The above copyright notice and this permission notice shall be included in          */
/*  all copies or substantial portions of the Software.                                 */
/*                                                                                      */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR           */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,            */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE        */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER              */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,       */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN           */
/*  THE SOFTWARE.                                                                       */
/*                                                                                      */
/****************************************************************************************/

#include "simply.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#include "../../lua/include/lua.h"
#include "../../lua/include/lauxlib.h"

#include "../../../third_party/libuv-package/include/uv.h"

#define UV_TIMER_MT "RmpUVTimer"

typedef struct {
    uv_timer_t handle;
    lua_State *L;
    int cb_ref;
    int self_ref;
    int closed;
} UVTimer;

static void uv_push_error(lua_State *L, const char *prefix, int err) {
    const char *msg = uv_strerror(err);
    if (prefix) {
        lua_pushfstring(L, "%s: %s", prefix, msg);
    } else {
        lua_pushstring(L, msg);
    }
}

static void uv_timer_cleanup(UVTimer *t) {
    if (!t || t->closed) {
        return;
    }
    t->closed = 1;
    if (t->cb_ref != LUA_NOREF) {
        luaL_unref(t->L, LUA_REGISTRYINDEX, t->cb_ref);
        t->cb_ref = LUA_NOREF;
    }
    if (t->self_ref != LUA_NOREF) {
        luaL_unref(t->L, LUA_REGISTRYINDEX, t->self_ref);
        t->self_ref = LUA_NOREF;
    }
}

static void uv_timer_on_close(uv_handle_t *h) {
    UVTimer *t = (UVTimer *)h->data;
    uv_timer_cleanup(t);
}

static void uv_timer_on_fire(uv_timer_t *h) {
    UVTimer *t = (UVTimer *)h->data;
    if (!t || t->closed) {
        return;
    }

    lua_State *L = t->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, t->cb_ref);
    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        fprintf(stderr, "[uv] timer callback error: %s\n", err ? err : "unknown error");
        lua_pop(L, 1);
    }

    uv_timer_stop(&t->handle);
    uv_close((uv_handle_t *)&t->handle, uv_timer_on_close);
}

static UVTimer *uv_check_timer(lua_State *L, int idx) {
    return (UVTimer *)luaL_checkudata(L, idx, UV_TIMER_MT);
}

ALWAYS_INT uv_timer_start_lua(STATE) {
    int ms = (int)luaL_checkinteger(L, 1);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    UVTimer *t = (UVTimer *)lua_newuserdata(L, sizeof(UVTimer));
    memset(t, 0, sizeof(UVTimer));
    t->L = L;
    t->cb_ref = LUA_NOREF;
    t->self_ref = LUA_NOREF;
    t->closed = 0;

    luaL_setmetatable(L, UV_TIMER_MT);

    lua_pushvalue(L, 2);
    t->cb_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    lua_pushvalue(L, -1);
    t->self_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    uv_timer_init(uv_default_loop(), &t->handle);
    t->handle.data = t;

    int rc = uv_timer_start(&t->handle, uv_timer_on_fire, (uint64_t)ms, 0);
    if (rc < 0) {
        uv_timer_cleanup(t);
        return luaL_error(L, "uv_timer_start failed: %s", uv_strerror(rc));
    }

    return 1;
}

ALWAYS_INT uv_timer_stop_lua(STATE) {
    UVTimer *t = uv_check_timer(L, 1);
    if (!t->closed) {
        uv_timer_stop(&t->handle);
        uv_close((uv_handle_t *)&t->handle, uv_timer_on_close);
    }
    return 0;
}

ALWAYS_INT uv_timer_close_lua(STATE) {
    UVTimer *t = uv_check_timer(L, 1);
    if (!t->closed) {
        uv_close((uv_handle_t *)&t->handle, uv_timer_on_close);
    }
    return 0;
}

ALWAYS_INT uv_timer_gc(STATE) {
    UVTimer *t = (UVTimer *)lua_touserdata(L, 1);
    if (t && !t->closed) {
        uv_timer_stop(&t->handle);
        uv_close((uv_handle_t *)&t->handle, uv_timer_on_close);
    }
    return 0;
}

ALWAYS_INT uv_run_lua(STATE) {
    const char *mode = luaL_optstring(L, 1, "default");
    uv_run_mode m = UV_RUN_DEFAULT;
    if (strcmp(mode, "default") == 0) {
        m = UV_RUN_DEFAULT;
    } else if (strcmp(mode, "once") == 0) {
        m = UV_RUN_ONCE;
    } else if (strcmp(mode, "nowait") == 0) {
        m = UV_RUN_NOWAIT;
    } else {
        return luaL_error(L, "invalid run mode: %s", mode);
    }

    int rc = uv_run(uv_default_loop(), m);
    lua_pushinteger(L, rc);
    return 1;
}

ALWAYS_INT uv_stop_lua(STATE) {
    (void)L;
    uv_stop(uv_default_loop());
    return 0;
}

ALWAYS_INT uv_now_lua(STATE) {
    uv_update_time(uv_default_loop());
    uint64_t now = uv_now(uv_default_loop());
    lua_pushinteger(L, (lua_Integer)now);
    return 1;
}

/* ------------------ FS helpers ------------------ */

typedef enum {
    UV_FS_STAGE_OPEN = 1,
    UV_FS_STAGE_FSTAT,
    UV_FS_STAGE_READ,
    UV_FS_STAGE_CLOSE,
    UV_FS_STAGE_WRITE
} uv_fs_stage_t;

typedef struct {
    lua_State *L;
    int cb_ref;
    uv_fs_t req;
    uv_file file;
    uv_buf_t buf;
    char *data;
    size_t size;
    uv_fs_stage_t stage;
} UVFsReq;

static void uv_fs_req_cleanup_all(UVFsReq *ctx) {
    if (!ctx) {
        return;
    }
    uv_fs_req_cleanup(&ctx->req);
    if (ctx->cb_ref != LUA_NOREF) {
        luaL_unref(ctx->L, LUA_REGISTRYINDEX, ctx->cb_ref);
        ctx->cb_ref = LUA_NOREF;
    }
    if (ctx->data) {
        free(ctx->data);
        ctx->data = NULL;
    }
    free(ctx);
}

static void uv_fs_call_cb_error(UVFsReq *ctx, const char *prefix, int err) {
    lua_State *L = ctx->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ctx->cb_ref);
    uv_push_error(L, prefix, err);
    lua_pushnil(L);
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
}

static void uv_fs_call_cb_read(UVFsReq *ctx, ssize_t nread) {
    lua_State *L = ctx->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ctx->cb_ref);
    lua_pushnil(L);
    if (nread < 0) {
        lua_pushnil(L);
    } else if (ctx->data && nread > 0) {
        lua_pushlstring(L, ctx->data, (size_t)nread);
    } else {
        lua_pushliteral(L, "");
    }
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
}

static void uv_fs_call_cb_write(UVFsReq *ctx, ssize_t nwritten) {
    lua_State *L = ctx->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ctx->cb_ref);
    if (nwritten < 0) {
        uv_push_error(L, "write", (int)nwritten);
        lua_pushnil(L);
        if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
            lua_pop(L, 1);
        }
        return;
    }
    lua_pushnil(L);
    lua_pushinteger(L, (lua_Integer)nwritten);
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
}

static void uv_fs_readfile_cb(uv_fs_t *req) {
    UVFsReq *ctx = (UVFsReq *)req->data;
    int result = (int)req->result;

    if (result < 0) {
        uv_fs_call_cb_error(ctx, "readfile", result);
        uv_fs_req_cleanup_all(ctx);
        return;
    }

    if (ctx->stage == UV_FS_STAGE_OPEN) {
        ctx->file = (uv_file)req->result;
        uv_fs_req_cleanup(req);
        ctx->stage = UV_FS_STAGE_FSTAT;
        int rc = uv_fs_fstat(uv_default_loop(), &ctx->req, ctx->file, uv_fs_readfile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "fstat", rc);
            uv_fs_req_cleanup_all(ctx);
        }
        return;
    }

    if (ctx->stage == UV_FS_STAGE_FSTAT) {
        ctx->size = (size_t)req->statbuf.st_size;
        uv_fs_req_cleanup(req);

        if (ctx->size == 0) {
        ctx->stage = UV_FS_STAGE_CLOSE;
        int rc = uv_fs_close(uv_default_loop(), &ctx->req, ctx->file, uv_fs_readfile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "close", rc);
            uv_fs_req_cleanup_all(ctx);
        }
        return;
    }

        ctx->data = (char *)malloc(ctx->size);
        if (!ctx->data) {
            uv_fs_call_cb_error(ctx, "malloc", UV_ENOMEM);
            uv_fs_req_cleanup_all(ctx);
            return;
        }
        ctx->buf = uv_buf_init(ctx->data, (unsigned int)ctx->size);
        ctx->stage = UV_FS_STAGE_READ;
        int rc = uv_fs_read(uv_default_loop(), &ctx->req, ctx->file, &ctx->buf, 1, 0, uv_fs_readfile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "read", rc);
            uv_fs_req_cleanup_all(ctx);
        }
        return;
    }

    if (ctx->stage == UV_FS_STAGE_READ) {
        ssize_t nread = req->result;
        uv_fs_req_cleanup(req);
        ctx->stage = UV_FS_STAGE_CLOSE;
        int rc = uv_fs_close(uv_default_loop(), &ctx->req, ctx->file, uv_fs_readfile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "close", rc);
            uv_fs_req_cleanup_all(ctx);
            return;
        }
        ctx->size = (size_t)((nread < 0) ? 0 : nread);
        return;
    }

    if (ctx->stage == UV_FS_STAGE_CLOSE) {
        uv_fs_req_cleanup(req);
        uv_fs_call_cb_read(ctx, (ssize_t)ctx->size);
        uv_fs_req_cleanup_all(ctx);
        return;
    }
}

ALWAYS_INT uv_fs_readfile_lua(STATE) {
    const char *path = luaL_checkstring(L, 1);
    luaL_checktype(L, 2, LUA_TFUNCTION);

    UVFsReq *ctx = (UVFsReq *)calloc(1, sizeof(UVFsReq));
    if (!ctx) {
        return luaL_error(L, "failed to allocate request");
    }
    ctx->L = L;
    ctx->cb_ref = LUA_NOREF;
    ctx->data = NULL;
    ctx->size = 0;
    ctx->stage = UV_FS_STAGE_OPEN;

    lua_pushvalue(L, 2);
    ctx->cb_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    ctx->req.data = ctx;
    int rc = uv_fs_open(uv_default_loop(), &ctx->req, path, O_RDONLY, 0, uv_fs_readfile_cb);
    if (rc < 0) {
        uv_fs_call_cb_error(ctx, "open", rc);
        uv_fs_req_cleanup_all(ctx);
        return 0;
    }

    return 0;
}

static void uv_fs_writefile_cb(uv_fs_t *req) {
    UVFsReq *ctx = (UVFsReq *)req->data;
    int result = (int)req->result;

    if (result < 0) {
        uv_fs_call_cb_error(ctx, "writefile", result);
        uv_fs_req_cleanup_all(ctx);
        return;
    }

    if (ctx->stage == UV_FS_STAGE_OPEN) {
        ctx->file = (uv_file)req->result;
        uv_fs_req_cleanup(req);
        ctx->stage = UV_FS_STAGE_WRITE;
        int rc = uv_fs_write(uv_default_loop(), &ctx->req, ctx->file, &ctx->buf, 1, 0, uv_fs_writefile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "write", rc);
            uv_fs_req_cleanup_all(ctx);
        }
        return;
    }

    if (ctx->stage == UV_FS_STAGE_WRITE) {
        ssize_t nwritten = req->result;
        uv_fs_req_cleanup(req);
        ctx->stage = UV_FS_STAGE_CLOSE;
        int rc = uv_fs_close(uv_default_loop(), &ctx->req, ctx->file, uv_fs_writefile_cb);
        if (rc < 0) {
            uv_fs_call_cb_error(ctx, "close", rc);
            uv_fs_req_cleanup_all(ctx);
            return;
        }
        ctx->size = (size_t)((nwritten < 0) ? 0 : nwritten);
        return;
    }

    if (ctx->stage == UV_FS_STAGE_CLOSE) {
        uv_fs_req_cleanup(req);
        uv_fs_call_cb_write(ctx, (ssize_t)ctx->size);
        uv_fs_req_cleanup_all(ctx);
        return;
    }
}

ALWAYS_INT uv_fs_writefile_lua(STATE) {
    const char *path = luaL_checkstring(L, 1);
    size_t len = 0;
    const char *data = luaL_checklstring(L, 2, &len);
    luaL_checktype(L, 3, LUA_TFUNCTION);

    UVFsReq *ctx = (UVFsReq *)calloc(1, sizeof(UVFsReq));
    if (!ctx) {
        return luaL_error(L, "failed to allocate request");
    }
    ctx->L = L;
    ctx->cb_ref = LUA_NOREF;
    ctx->data = NULL;
    ctx->size = len;
    ctx->stage = UV_FS_STAGE_OPEN;

    ctx->data = (char *)malloc(len);
    if (!ctx->data) {
        uv_fs_req_cleanup_all(ctx);
        return luaL_error(L, "failed to allocate buffer");
    }
    memcpy(ctx->data, data, len);
    ctx->buf = uv_buf_init(ctx->data, (unsigned int)len);

    lua_pushvalue(L, 3);
    ctx->cb_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    ctx->req.data = ctx;
    int rc = uv_fs_open(uv_default_loop(), &ctx->req, path, O_WRONLY | O_CREAT | O_TRUNC, 0644, uv_fs_writefile_cb);
    if (rc < 0) {
        uv_fs_call_cb_error(ctx, "open", rc);
        uv_fs_req_cleanup_all(ctx);
        return 0;
    }

    return 0;
}

/* ------------------ Spawn helpers ------------------ */

typedef struct {
    lua_State *L;
    int cb_ref;
    int on_stdout_ref;
    int on_stderr_ref;
    uv_process_t process;
    uv_pipe_t stdout_pipe;
    uv_pipe_t stderr_pipe;
    int capture;
    int exited;
    int stdout_closed;
    int stderr_closed;
    int stdout_eof;
    int stderr_eof;
    int callback_done;
    int process_closed;
    int64_t exit_status;
    int term_signal;
    char *stdout_buf;
    size_t stdout_len;
    size_t stdout_cap;
    char *stderr_buf;
    size_t stderr_len;
    size_t stderr_cap;
    char **args;
    int argc;
} UVProcess;

static void uv_process_append(char **buf, size_t *len, size_t *cap, const char *data, size_t n) {
    size_t need = *len + n;
    if (need + 1 > *cap) {
        size_t newcap = (*cap == 0) ? 4096 : (*cap * 2);
        while (newcap < need + 1) {
            newcap *= 2;
        }
        char *nb = (char *)realloc(*buf, newcap);
        if (!nb) {
            return;
        }
        *buf = nb;
        *cap = newcap;
    }
    if (*buf && *cap >= need + 1) {
        memcpy(*buf + *len, data, n);
        *len = need;
    }
}

static void uv_process_free(UVProcess *proc) {
    if (!proc) {
        return;
    }
    if (proc->args) {
        for (int i = 0; i < proc->argc; i++) {
            free(proc->args[i]);
        }
        free(proc->args);
        proc->args = NULL;
    }
    if (proc->cb_ref != LUA_NOREF) {
        luaL_unref(proc->L, LUA_REGISTRYINDEX, proc->cb_ref);
        proc->cb_ref = LUA_NOREF;
    }
    if (proc->on_stdout_ref != LUA_NOREF) {
        luaL_unref(proc->L, LUA_REGISTRYINDEX, proc->on_stdout_ref);
        proc->on_stdout_ref = LUA_NOREF;
    }
    if (proc->on_stderr_ref != LUA_NOREF) {
        luaL_unref(proc->L, LUA_REGISTRYINDEX, proc->on_stderr_ref);
        proc->on_stderr_ref = LUA_NOREF;
    }
    if (proc->stdout_buf) {
        free(proc->stdout_buf);
        proc->stdout_buf = NULL;
    }
    if (proc->stderr_buf) {
        free(proc->stderr_buf);
        proc->stderr_buf = NULL;
    }
    free(proc);
}

static void uv_process_maybe_free(UVProcess *proc) {
    if (!proc) {
        return;
    }
    if (proc->process_closed && proc->stdout_closed && proc->stderr_closed) {
        uv_process_free(proc);
    }
}

static void uv_process_on_close(uv_handle_t *handle) {
    UVProcess *proc = (UVProcess *)handle->data;
    proc->process_closed = 1;
    uv_process_maybe_free(proc);
}

static void uv_process_finalize(UVProcess *proc);

static void uv_pipe_on_close(uv_handle_t *handle) {
    UVProcess *proc = (UVProcess *)handle->data;
    if (handle == (uv_handle_t *)&proc->stdout_pipe) {
        proc->stdout_closed = 1;
    } else if (handle == (uv_handle_t *)&proc->stderr_pipe) {
        proc->stderr_closed = 1;
    }
    if (proc->exited && proc->stdout_closed && proc->stderr_closed) {
        uv_process_finalize(proc);
    }
    uv_process_maybe_free(proc);
}

static void uv_process_finalize(UVProcess *proc) {
    if (proc->callback_done) {
        return;
    }
    proc->callback_done = 1;
    lua_State *L = proc->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, proc->cb_ref);
    lua_pushnil(L);
    lua_pushinteger(L, (lua_Integer)proc->exit_status);
    lua_pushinteger(L, (lua_Integer)proc->term_signal);
    if (proc->capture) {
        if (proc->stdout_buf) {
            lua_pushlstring(L, proc->stdout_buf, proc->stdout_len);
        } else {
            lua_pushliteral(L, "");
        }
        if (proc->stderr_buf) {
            lua_pushlstring(L, proc->stderr_buf, proc->stderr_len);
        } else {
            lua_pushliteral(L, "");
        }
    } else {
        lua_pushnil(L);
        lua_pushnil(L);
    }
    if (lua_pcall(L, 5, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
}

static void uv_alloc_cb_impl(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    (void)handle;
    buf->base = (char *)malloc(suggested_size);
    buf->len = suggested_size;
}

static void uv_process_on_stdout_read(uv_stream_t *stream, ssize_t nread, const uv_buf_t *buf) {
    UVProcess *proc = (UVProcess *)stream->data;
    if (nread > 0) {
        if (proc->on_stdout_ref != LUA_NOREF) {
            lua_State *L = proc->L;
            lua_rawgeti(L, LUA_REGISTRYINDEX, proc->on_stdout_ref);
            lua_pushlstring(L, buf->base, (size_t)nread);
            if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
                lua_pop(L, 1);
            }
        }
        if (proc->capture) {
            uv_process_append(&proc->stdout_buf, &proc->stdout_len, &proc->stdout_cap, buf->base, (size_t)nread);
        }
    } else if (nread < 0) {
        if (!proc->stdout_eof) {
            proc->stdout_eof = 1;
            uv_close((uv_handle_t *)&proc->stdout_pipe, uv_pipe_on_close);
        }
    }
    if (buf && buf->base) {
        free(buf->base);
    }
}

static void uv_process_on_stderr_read(uv_stream_t *stream, ssize_t nread, const uv_buf_t *buf) {
    UVProcess *proc = (UVProcess *)stream->data;
    if (nread > 0) {
        if (proc->on_stderr_ref != LUA_NOREF) {
            lua_State *L = proc->L;
            lua_rawgeti(L, LUA_REGISTRYINDEX, proc->on_stderr_ref);
            lua_pushlstring(L, buf->base, (size_t)nread);
            if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
                lua_pop(L, 1);
            }
        }
        if (proc->capture) {
            uv_process_append(&proc->stderr_buf, &proc->stderr_len, &proc->stderr_cap, buf->base, (size_t)nread);
        }
    } else if (nread < 0) {
        if (!proc->stderr_eof) {
            proc->stderr_eof = 1;
            uv_close((uv_handle_t *)&proc->stderr_pipe, uv_pipe_on_close);
        }
    }
    if (buf && buf->base) {
        free(buf->base);
    }
}

static void uv_process_on_exit(uv_process_t *handle, int64_t exit_status, int term_signal) {
    UVProcess *proc = (UVProcess *)handle->data;
    proc->exited = 1;
    proc->exit_status = exit_status;
    proc->term_signal = term_signal;

    if (proc->stdout_closed && proc->stderr_closed) {
        uv_process_finalize(proc);
    }
    uv_close((uv_handle_t *)handle, uv_process_on_close);
}

ALWAYS_INT uv_spawn_lua(STATE) {
    const char *file = luaL_checkstring(L, 1);
    int arg_index = 2;
    int options_index = 0;

    if (lua_type(L, arg_index) == LUA_TTABLE) {
        options_index = arg_index;
        arg_index++;
    }
    luaL_checktype(L, arg_index, LUA_TFUNCTION);

    UVProcess *proc = (UVProcess *)calloc(1, sizeof(UVProcess));
    if (!proc) {
        return luaL_error(L, "failed to allocate process");
    }
    proc->L = L;
    proc->cb_ref = LUA_NOREF;
    proc->on_stdout_ref = LUA_NOREF;
    proc->on_stderr_ref = LUA_NOREF;
    proc->capture = 0;
    proc->exited = 0;
    proc->stdout_closed = 1;
    proc->stderr_closed = 1;
    proc->stdout_eof = 1;
    proc->stderr_eof = 1;
    proc->callback_done = 0;
    proc->process_closed = 0;
    proc->exit_status = 0;
    proc->term_signal = 0;
    proc->stdout_buf = NULL;
    proc->stdout_len = 0;
    proc->stdout_cap = 0;
    proc->stderr_buf = NULL;
    proc->stderr_len = 0;
    proc->stderr_cap = 0;
    proc->args = NULL;
    proc->argc = 0;

    lua_pushvalue(L, arg_index);
    proc->cb_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    int is_opts = 0;
    int has_args = 0;
    int argc = 1;

    if (options_index != 0) {
        lua_getfield(L, options_index, "capture");
        if (!lua_isnil(L, -1)) {
            is_opts = 1;
        }
        proc->capture = lua_toboolean(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, options_index, "on_stdout");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            is_opts = 1;
            proc->on_stdout_ref = luaL_ref(L, LUA_REGISTRYINDEX);
        } else {
            lua_pop(L, 1);
        }

        lua_getfield(L, options_index, "on_stderr");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            is_opts = 1;
            proc->on_stderr_ref = luaL_ref(L, LUA_REGISTRYINDEX);
        } else {
            lua_pop(L, 1);
        }

        lua_getfield(L, options_index, "args");
        if (lua_type(L, -1) == LUA_TTABLE) {
            is_opts = 1;
            has_args = 1;
            argc += (int)lua_rawlen(L, -1);
        }
        lua_pop(L, 1);
    }

    if (!is_opts && lua_type(L, 2) == LUA_TTABLE) {
        has_args = 1;
        argc += (int)lua_rawlen(L, 2);
    }

    proc->args = (char **)calloc((size_t)argc + 1, sizeof(char *));
    if (!proc->args) {
        uv_process_free(proc);
        return luaL_error(L, "failed to allocate args");
    }

    proc->args[0] = strdup(file);
    if (!proc->args[0]) {
        uv_process_free(proc);
        return luaL_error(L, "failed to allocate args");
    }

    int out = 1;
    if (has_args) {
        int args_index = 2;
        if (is_opts) {
            lua_getfield(L, options_index, "args");
            args_index = lua_gettop(L);
        }
        for (int i = 1; i <= (int)lua_rawlen(L, args_index); i++) {
            lua_rawgeti(L, args_index, i);
            const char *arg = luaL_checkstring(L, -1);
            proc->args[out] = strdup(arg);
            lua_pop(L, 1);
            if (!proc->args[out]) {
                if (is_opts) {
                    lua_pop(L, 1);
                }
                uv_process_free(proc);
                return luaL_error(L, "failed to allocate args");
            }
            out++;
        }
        if (is_opts) {
            lua_pop(L, 1);
        }
    }

    proc->argc = out;
    proc->args[out] = NULL;

    uv_process_options_t options;
    memset(&options, 0, sizeof(options));
    options.file = file;
    options.args = proc->args;
    options.exit_cb = uv_process_on_exit;

    int want_stdio = (proc->capture || proc->on_stdout_ref != LUA_NOREF || proc->on_stderr_ref != LUA_NOREF);
    uv_stdio_container_t stdio[3];
    if (want_stdio) {
        proc->stdout_closed = 0;
        proc->stderr_closed = 0;
        proc->stdout_eof = 0;
        proc->stderr_eof = 0;

        uv_pipe_init(uv_default_loop(), &proc->stdout_pipe, 0);
        uv_pipe_init(uv_default_loop(), &proc->stderr_pipe, 0);
        proc->stdout_pipe.data = proc;
        proc->stderr_pipe.data = proc;

        stdio[0].flags = UV_IGNORE;
        stdio[1].flags = UV_CREATE_PIPE | UV_WRITABLE_PIPE;
        stdio[1].data.stream = (uv_stream_t *)&proc->stdout_pipe;
        stdio[2].flags = UV_CREATE_PIPE | UV_WRITABLE_PIPE;
        stdio[2].data.stream = (uv_stream_t *)&proc->stderr_pipe;

        options.stdio = stdio;
        options.stdio_count = 3;
    }

    proc->process.data = proc;

    int rc = uv_spawn(uv_default_loop(), &proc->process, &options);
    if (rc < 0) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, proc->cb_ref);
        uv_push_error(L, "spawn", rc);
        lua_pushnil(L);
        lua_pushnil(L);
        lua_pushnil(L);
        lua_pushnil(L);
        if (lua_pcall(L, 5, 0, 0) != LUA_OK) {
            lua_pop(L, 1);
        }
        uv_process_free(proc);
        return 0;
    }

    if (want_stdio) {
        uv_read_start((uv_stream_t *)&proc->stdout_pipe, uv_alloc_cb_impl, uv_process_on_stdout_read);
        uv_read_start((uv_stream_t *)&proc->stderr_pipe, uv_alloc_cb_impl, uv_process_on_stderr_read);
    }

    return 0;
}

static const luaL_Reg uv_timer_methods[] = {
    {"stop", uv_timer_stop_lua},
    {"close", uv_timer_close_lua},
    {NULL, NULL}
};

static const luaL_Reg uv_timer_meta[] = {
    {"__gc", uv_timer_gc},
    {NULL, NULL}
};

static const luaL_Reg uv_lib[] = {
    {"run", uv_run_lua},
    {"stop", uv_stop_lua},
    {"now", uv_now_lua},
    {"timer_start", uv_timer_start_lua},
    {"fs_readfile", uv_fs_readfile_lua},
    {"fs_writefile", uv_fs_writefile_lua},
    {"spawn", uv_spawn_lua},
    // TODO: add more APIs (tcp socket etc.)
    // and update it in promises as well
    {NULL, NULL}
};

int luaopen_rmp_uv(STATE) {
    luaL_newmetatable(L, UV_TIMER_MT);
    luaL_setfuncs(L, uv_timer_methods, 0);
    luaL_setfuncs(L, uv_timer_meta, 0);
    lua_pop(L, 1);

    luaL_newlib(L, uv_lib);
    return 1;
}
