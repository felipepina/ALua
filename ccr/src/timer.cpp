#include <cstdlib>
#include <cstring>
#include <cmath>
#include <iostream>

#include <tbb/atomic.h>
#include <ccr/message.h>
#include "ccr.h"

extern "C"
{
    #include <unistd.h>
    #include <pthread.h>
    #include <sys/time.h>
    #include <lua.h>
    #include <lauxlib.h>

    LUALIB_API int luaopen_ccr_timer_core(lua_State *L);
}


using namespace std;
using namespace tbb;

#define MAXSIZE 10
#define TICK    10000

typedef struct tmlist_st
{
    process_t *proc;
    unsigned long long time;
    struct tmlist_st *next;
} tmlist_t;

typedef struct
{
    tmlist_t *head;
    pthread_mutex_t lock;
} timer_node_t;

static char *fmt;
static atomic<unsigned long long> ticks;
static timer_node_t timers[MAXSIZE];
static pthread_t pid;
static int inited = 0;
static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

static int tm_now(lua_State *L)
{
    struct timeval tm;
    if (gettimeofday(&tm, NULL))
        return 0;
    lua_pushnumber(L, tm.tv_sec);
    lua_pushnumber(L, tm.tv_usec);
    return 2;
}


static int tm_setfmt(lua_State *L)
{
    const char *str = luaL_checkstring(L, 1);
    free(fmt);
    fmt = strdup(str);
    return 0;
}


static int tm_settimer(lua_State *L)
{
    int n;
    tmlist_t *node;
    unsigned long long tm;
    process_t **proc = (process_t**)lua_touserdata(L, 1);
    tm = (unsigned long long)ceilf((1e6*luaL_checknumber(L, 2))/(double)TICK)
        + ticks;
    n = (int)(tm % MAXSIZE);
    node = new tmlist_t;
    if (node)
    {
        node->time = tm;
        node->proc = *proc;
        prc_upref(*proc);
        pthread_mutex_lock(&timers[n].lock);
        node->next = timers[n].head;
        timers[n].head = node;
        pthread_mutex_unlock(&timers[n].lock);
        lua_pushnumber(L, tm);
    }
    else
        lua_pushnil(L);
    return 1;
}


static void* tm_worker(void *arg)
{
    char str[128];
    int n;
    message_t *msg;
    tmlist_t *head, *tmp, *prev;
    pthread_detach(pthread_self());
    while (1)
    {
        usleep(TICK);
        ticks++;
        prev = NULL;
        n = (int)(ticks % MAXSIZE);
        pthread_mutex_lock(&timers[n].lock);
        head = timers[n].head;
        while (head)
        {
            if (head->time <= ticks)
            {
                snprintf(str, sizeof(str), fmt, head->time);
                msg = msg_create(str, strlen(str), STR_COPY);
                if(!ccr_rawsend(head->proc, msg))
                    msg_free(msg);
                prc_free(head->proc);
                if (prev)
                    prev->next = head->next;
                else
                    timers[n].head = head->next;
                tmp = head;
                head = head->next;
                free(tmp);
            }
            else
            {
                prev = head;
                head = head->next;
            }
        }
        pthread_mutex_unlock(&timers[n].lock);
    }
    return NULL;
}


static luaL_Reg funcs[] =
{
    {"now",      tm_now},
    {"setfmt",   tm_setfmt},
    {"settimer", tm_settimer},
    {NULL,       NULL}
};

LUALIB_API int luaopen_ccr_timer_core(lua_State *L)
{
    int i;
    pthread_mutex_lock(&lock);
    if (!inited)
    {
        inited = 1;
        ticks = 0;
        fmt = strdup("timer->trigger (%llu)");
        for (i = 0; i < MAXSIZE; i++)
        {
            timers[i].head = NULL;
            pthread_mutex_init(&timers[i].lock, NULL);
        }
        if(pthread_create(&pid, NULL, tm_worker, NULL))
            cerr << "[ERRO] Timer not initialized" << endl;
    }
    pthread_mutex_unlock(&lock);
    luaL_register(L, "ccr.timer.core", funcs);
    return 1;
}
