#include <cstdlib>
#include <cstring>
#include <iostream>

#include <list>

#include <ccr/message.h>
#include <ccr/mailbox.h>

#include <tbb/atomic.h>
#include <tbb/concurrent_queue.h>
#include <tbb/queuing_rw_mutex.h>

#include "register.h"
#include "ccr.h"

extern "C"
{
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
}


using namespace std;
using namespace tbb;

#define THR_SIZE 3

static void* worker(void *arg);

// Thread pool
static list<pthread_t> thr_pool;
// Queue with the process in the PS_READY state
static concurrent_queue<process_t*> prc_ready;

// Numbers of threads to kill
static atomic<unsigned int> free_workers;
// Flag indication that threads need be killed
static atomic<bool> free_flag;

void prc_upref(process_t *proc)
{
    proc->counter.fetch_and_increment();
}


void prc_free(process_t *proc)
{
    if (proc->counter.fetch_and_decrement() == 1)
    {
        mbx_free(proc->mbox);
        delete proc;
    }
}


int ccr_rawsend(process_t *proc, message_t *msg)
{
    queuing_rw_mutex::scoped_lock rlock;
    rlock.acquire(proc->lock, false);
    if (mbx_put(proc->mbox, msg))
    {
        if (proc->status.compare_and_swap(PS_READY, PS_BLOCKED) == PS_BLOCKED)
            prc_ready.push(proc);
        rlock.release();
        return 1;
    }
    rlock.release();
    return 0;
}


static int ccr_self(lua_State *L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);
    process_t **ref = (process_t**)lua_newuserdata(L, sizeof(process_t*));
    if (!ref)
    {
        lua_pushnil(L);
        lua_pushstring(L, "could not create process reference");
        return 2;
    }
    prc_upref(proc);
    *ref = proc;
    luaL_getmetatable(L, CCR_PROCESS);
    lua_setmetatable(L, -2);
    return 1;
}


static int ccr_ismain(lua_State *L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);
    lua_pushboolean(L, proc->main);
    return 1;
}


static int ccr_hasdata(lua_State *L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);
    lua_pushboolean(L, !mbx_isempty(proc->mbox));
    return 1;
}


static int ccr_send(lua_State *L)
{
    process_t **proc = (process_t**)luaL_checkudata(L, 1, CCR_PROCESS);
    char *str = (char*)lua_tostring(L, 2);
    size_t size = lua_objlen(L, 2);
    message_t *msg = msg_create(str, size, STR_COPY);
    if (!msg)
    {
        lua_pushboolean(L, 0);
        lua_pushstring(L, "could not create the message");
        return 2;
    }
    if (ccr_rawsend(*proc, msg))
    {
        lua_pushboolean(L, 1);
        return 1;
    }
    msg_free(msg);
    lua_pushboolean(L, 0);
    lua_pushstring(L, "closed");
    return 2;
}


static int ccr_recv(lua_State *L)
{
    message_t *msg;
    process_t *proc;
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    proc = (process_t*)lua_touserdata(L, -1);
    msg = mbx_get(proc->mbox);
    if (msg)
    {
        lua_pushlstring(L, msg_data(msg), msg_size(msg));
        msg_free(msg);
        return 1;
    }
    lua_pushnil(L);
    lua_pushstring(L, "closed");
    return 2;
}


static int ccr_tryrecv(lua_State *L)
{
    int closed;
    message_t *msg;
    process_t *proc;
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    proc = (process_t*)lua_touserdata(L, -1);
    msg = mbx_tryget(proc->mbox, &closed);
    if (msg)
    {
        lua_pushlstring(L, msg_data(msg), msg_size(msg));
        msg_free(msg);
        return 1;
    }
    lua_pushnil(L);
    return 1;
}


static int ccr_yield(lua_State *L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);
    if (!proc->main)
    {
        // Worker will release the lock
        proc->wlock.acquire(proc->lock, true);
        proc->status = mbx_isempty(proc->mbox) ? PS_BLOCKING : PS_READY;
    }
    return lua_yield(L, 0);
}


static const luaL_Reg ccr_libs[] =
{
    {"", luaopen_base},
    {LUA_LOADLIBNAME, luaopen_package},
    {LUA_TABLIBNAME, luaopen_table},
    {LUA_IOLIBNAME, luaopen_io},
    {LUA_OSLIBNAME, luaopen_os},
    {LUA_STRLIBNAME, luaopen_string},
    {LUA_MATHLIBNAME, luaopen_math},
    {LUA_DBLIBNAME, luaopen_debug},
    {NULL, NULL}
};

static void ccr_openlibs(lua_State *L)
{
    const luaL_Reg *ptr = ccr_libs;
    for (; ptr->func; ptr++)
    {
        lua_pushcfunction(L, ptr->func);
        lua_pushstring(L, ptr->name);
        switch (lua_pcall(L, 1, 0, 0))
        {
            case LUA_ERRRUN:
                cerr << "LUA_ERRRUN\n";
                break;
            case LUA_ERRMEM:
                cerr << "LUA_ERRMEM\n";
                break;
            case LUA_ERRERR:
                cerr << "LUA_ERRERR\n";
                break;
        }
    }
}


static int ccr_spawn(lua_State *L)
{
    process_t *proc;
    const char *str = luaL_checkstring(L, 1);
    proc = new process_t();
    if (proc)
    {
        proc->main = 0;
        proc->counter = 1;
        proc->status = PS_READY;
        proc->mbox = mbx_create();
        if (proc->mbox)
        {
            proc->L = luaL_newstate();
            if (proc->L)
            {
                // luaL_openlibs(proc->L);
                ccr_openlibs(proc->L);
                lua_pushstring(proc->L, CCR_SELF);
                lua_pushlightuserdata(proc->L, proc);
                lua_rawset(proc->L, LUA_REGISTRYINDEX);
                if (!luaL_loadstring(proc->L, str))
                {
                    prc_ready.push(proc);
                    lua_pushboolean(L, 1);
                    return 1;
                }
                /*
                    TODO Retornar isto ao processo chamador
                */
                cerr << "[ERROR][CREATING LUA PROCESS] " << lua_tostring(proc->L, -1) << endl;
                lua_close(proc->L);
            }
            mbx_free(proc->mbox);
        }
        delete proc;
    }
    lua_pushboolean(L, 0);
    return 1;
}


static int ccr_finalize(lua_State *L)
{
    int i;
    process_t *proc;
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    proc = (process_t*)lua_touserdata(L, -1);
    if (proc->main)
    {
        for (i = 0; i < THR_SIZE; i++)
        {
            prc_ready.push(NULL);
        }

        for (list<pthread_t>::iterator thread = thr_pool.begin(); thread!=thr_pool.end(); ++thread)
        {
            pthread_join(*thread, NULL);
        }
    }
    return 0;
}


static int ccr_register(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    process_t **proc = (process_t**)luaL_checkudata(L, 2, CCR_PROCESS);
    reg_insert(name, *proc);
    return 0;
}


static int ccr_remove(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    reg_remove(name);
    return 0;
}


static int ccr_lookup(lua_State *L)
{
    process_t **proc;
    const char *name = luaL_checkstring(L, 1);
    process_t *tmp = (process_t*)reg_lookup(name);
    if (tmp)
    {
        process_t **proc = (process_t**)lua_newuserdata(L, sizeof(process_t*));
        if (!proc)
        {
            lua_pushnil(L);
            lua_pushstring(L, "could not create process reference");
            return 2;
        }
        prc_upref(tmp);
        *proc = tmp;
        luaL_getmetatable(L, CCR_PROCESS);
        lua_setmetatable(L, -2);
    }
    else
        lua_pushnil(L);
    return 1;
}


static int ccr_process_gc(lua_State *L)
{
    process_t **proc = (process_t**)lua_touserdata(L, 1);
    if (*proc) prc_free(*proc);
    return 0;
}


static void* ccr_worker(void *arg)
{
    int r, resume;
    process_t *proc;
    while (1)
    {
        // Checks if threads need to be killed and the the ready procces's queue is empty
        // That way only when the queue is empty the threads are killed
        // if ((free_flag.compare_and_swap(false, true)) && (prc_ready.empty()))
        if (free_flag.compare_and_swap(false, true))
        {
            pthread_t thread = pthread_self();
            // removes reference from the pool
            thr_pool.remove(thread);

            // checks if threre's more threads to kill and set the flag
            if (free_workers.fetch_and_decrement() > 1)
            {
                free_flag.compare_and_swap(true, false);
            }

            //kills the current thread
            pthread_exit(NULL);
        }
        prc_ready.pop(proc);
        if (!proc) return NULL;
        r = lua_resume(proc->L, 0);
        switch (r)
        {
            case  LUA_YIELD:
                //cerr << "Yield!\n";
                switch (proc->status)
                {
                    case PS_READY:
                        // releasing the lock acquired in ccr_yield
                        proc->wlock.release();
                        prc_ready.push(proc);
                        break;
                    case PS_BLOCKING:
                        proc->status = PS_BLOCKED;
                        // releasing the lock acquired in ccr_yield
                        proc->wlock.release();
                        break;
                }
                break;
            case LUA_ERRRUN:
            case LUA_ERRMEM:
            case LUA_ERRERR:
                cerr << "[ERROR][PROCESSING A LUA PROCESS] " << lua_tostring(proc->L, -1) << endl;
                // fall-through
            case 0:
                lua_close(proc->L);
                mbx_close(proc->mbox);
                prc_free(proc);
                break;
        }
    }
    return NULL;
}


// Creates a new worker thread
static int ccr_inc_workers(lua_State *L)
{
    int count = (int)luaL_checkinteger(L, 1);
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);

    // checks if the calling process is a main process
    if(proc->main)
    {
        for(int i = 0; i < count; ++i)
        {
            pthread_t new_thread;
            // creates news threads
            if (pthread_create(&new_thread, NULL, ccr_worker, NULL) > 0)
            {
                lua_pushinteger(L, 0);
                lua_pushstring(L, "error while creating a new thread");
                return 2;
            }

            thr_pool.push_back(new_thread);
        }
        // returns the current number of threads in the pool
        lua_pushinteger(L, (lua_Integer) thr_pool.size());
        return 1;
    }

    lua_pushnil(L);
    lua_pushstring(L, "only a main process could create a new thread");
    return 2;
}


// Finalizes a worker thread
static int ccr_dec_workers(lua_State *L)
{
    int count = (int)luaL_checkinteger(L, 1);
    lua_getfield(L, LUA_REGISTRYINDEX, CCR_SELF);
    process_t *proc = (process_t*)lua_touserdata(L, -1);

    // checks if the calling process is a main process
    if(proc->main)
    {
        if (thr_pool.size() - count < THR_SIZE)
        {
            lua_pushinteger(L, 0);
            lua_pushstring(L, "thread pool is already at the minimum size");
            return 2;
        }

        // sets the numbers threads to kill
        free_workers.fetch_and_add(count);
        // sets the flag indication to kill threads
        free_flag.compare_and_swap(true, false);
        // returns the current number of threads in the pool
        lua_pushinteger(L, (lua_Integer) thr_pool.size() - count);
        return 1;
    }
    lua_pushinteger(L, 0);
    lua_pushstring(L, "only a main process could free threads");
    return 2;
}


static luaL_Reg funcs[] =
{
    {"self",       ccr_self},
    {"ismain",     ccr_ismain},
    {"hasdata",    ccr_hasdata},
    {"send",       ccr_send},
    {"receive",    ccr_recv},
    {"tryreceive", ccr_tryrecv},
    {"spawn",      ccr_spawn},
    {"yield",      ccr_yield},
    {"finalize",   ccr_finalize},
    {"register",   ccr_register},
    {"remove",     ccr_remove},
    {"lookup",     ccr_lookup},

    {"inc_workers",     ccr_inc_workers},
    {"dec_workers",     ccr_dec_workers},
    {NULL,         NULL}
};

int luaopen_ccr_core(lua_State *L)
{
    lua_pushstring(L, CCR_SELF);
    lua_rawget(L, LUA_REGISTRYINDEX);
    if (lua_isnil(L, -1))
    {
        thr_pool = list<pthread_t>();
        free_workers = 0;
        free_flag = false;

        for (int i = 0; i < THR_SIZE; ++i)
        {
            pthread_t thread;
            pthread_create(&thread, NULL, ccr_worker, NULL);
            thr_pool.push_back(thread);
        }

        process_t *proc = new process_t();
        if (!proc)
        {
            lua_pushnil(L);
            return 1;
        }
        proc->mbox = mbx_create();
        if (!proc->mbox)
        {
            delete proc;
            lua_pushnil(L);
            return 1;
        }
        proc->L = L;
        proc->main = 1;
        proc->counter = 1;
        proc->status = PS_READY;
        lua_pushstring(L, CCR_SELF);
        lua_pushlightuserdata(L, proc);
        lua_rawset(L, LUA_REGISTRYINDEX);
    }
    luaL_newmetatable(L, CCR_PROCESS);
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, ccr_process_gc);
    lua_rawset(L, -3);
    // Module functions
    luaL_register(L, "ccr.core", funcs);
    return 1;
}
