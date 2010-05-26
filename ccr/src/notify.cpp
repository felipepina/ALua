#include <cstdlib>
#include <cstring>

#include <ccr/message.h>
#include "ccr.h"

extern "C"
{
    #include <stdio.h>
    #include <sys/select.h>
    #include <pthread.h>
    #include <lua.h>
    #include <lauxlib.h>

    LUALIB_API int luaopen_ccr_notify_core(lua_State *L);
}


using namespace std;
using namespace tbb;

enum ChannelFlags { CF_READ, CF_WRITE };

typedef struct notify_s
{
    int flag;
    int sock;
    process_t *proc;
    struct notify_s *next;
} notify_t;

typedef struct
{
    notify_t *first;
    notify_t *last;
    pthread_cond_t cond;
    pthread_mutex_t lock;
} ntfcontrol;

static pthread_t pid;
static char *fmt = NULL;
static pthread_once_t once = PTHREAD_ONCE_INIT;
static pthread_mutex_t fmtlock = PTHREAD_MUTEX_INITIALIZER;

#define NTFSIZE 3
static ntfcontrol ntf[NTFSIZE];

static int ntf_add(lua_State *L)
{
    int flags;
    notify_t *node;
    ntfcontrol *ctl;
    int sock = (int)lua_tonumber(L, 1);
    process_t **proc = (process_t**)lua_touserdata(L, 2);
    const char *ptr = lua_tostring(L, 3);
    node = new notify_t();
    if (*ptr == 'r')
        node->flag = CF_READ;
    else
        node->flag = CF_WRITE;
    prc_upref(*proc);
    node->proc = *proc;
    node->sock = sock;
    node->next = NULL;
    ctl = &ntf[sock%NTFSIZE];
    pthread_mutex_lock(&ctl->lock);
    if (ctl->last)
    {
        node->next = ctl->first;
        ctl->first = node;
    }
    else
        ctl->first = ctl->last = node;
    if (ctl->first == ctl->last)
        pthread_cond_signal(&ctl->cond);
    pthread_mutex_unlock(&ctl->lock);
    lua_pushboolean(L, 1);
    return 1;
}


static void* notifier(void *arg)
{
    int max;
    char str[128];
    message_t *msg;
    struct timeval tm;
    const char *evt;
    const char *revt = "r";
    const char *wevt = "w";
    fd_set rset, wset, *set;
    ntfcontrol *ctl;
    notify_t *tmp, *aux;
    notify_t *first = NULL;
    notify_t *last  = NULL;
    int *id = (int*)arg;
    ctl = &ntf[*id];
    pthread_detach(pthread_self());
    while (1)
    {
        pthread_mutex_lock(&ctl->lock);
        while (!ctl->first && !first)
            pthread_cond_wait(&ctl->cond, &ctl->lock);
        if (ctl->first)
        {
            if (last)
            {
                last->next = ctl->first;
                last = ctl->last;
            }
            else
            {
                first = ctl->first;
                last  = ctl->last;
            }
            ctl->first = ctl->last = NULL;
        }
        pthread_mutex_unlock(&ctl->lock);
        max = -1;
        tm.tv_sec = 0;
        tm.tv_usec = 30000;
        FD_ZERO(&rset);
        FD_ZERO(&wset);
        tmp = first;
        while (tmp)
        {
            set = (tmp->flag == CF_READ) ? &rset : &wset;
            FD_SET(tmp->sock, set);
            if (tmp->sock > max) max = tmp->sock;
            tmp = tmp->next;
        }
        max++;
        //if (select(max, &rset, &wset, NULL, &tm)  > 0) {
        int ret = select(max, &rset, &wset, NULL, &tm);
        if (ret == 0) continue;
        aux = NULL;
        tmp = first;
        while (tmp)
        {
            if (tmp->flag == CF_READ)
            {
                evt = revt;
                set = &rset;
            }
            else
            {
                evt = wevt;
                set = &wset;
            }
            if (FD_ISSET(tmp->sock, set))
            {
                snprintf(str, sizeof(str), fmt, tmp->sock, evt);
                msg = msg_create(str, strlen(str), STR_COPY);
                ccr_rawsend(tmp->proc, msg);
                if (aux)
                {
                    aux->next = tmp->next;
                    prc_free(tmp->proc);
                    delete tmp;
                    tmp = aux->next;
                }
                else
                {
                    if (tmp == first) first = tmp->next;
                    prc_free(tmp->proc);
                    tmp = first;
                }
            }
            else
            {
                aux = tmp;
                tmp = tmp->next;
            }
        }
        last = aux;
    }
    return NULL;
}


static int ntf_setfmt(lua_State *L)
{
    const char *tmp = luaL_checkstring(L, 1);
    pthread_mutex_lock(&fmtlock);
    free(fmt);
    fmt = strdup(tmp);
    pthread_mutex_unlock(&fmtlock);
    return 0;
}


static void ntf_init()
{
    int i, *arg;
    fmt = strdup("%d:%s");
    for (i = 0; i < NTFSIZE; i++)
    {
        ntf[i].first = NULL;
        ntf[i].last = NULL;
        pthread_cond_init(&ntf[i].cond, NULL);
        pthread_mutex_init(&ntf[i].lock, NULL);
        arg = new int;
        *arg = i;
        pthread_create(&pid, NULL, notifier, (void*)arg);
    }
}


static luaL_Reg funcs[] =
{
    {"add",       ntf_add},
    {"setformat", ntf_setfmt},
    {NULL, NULL}
};

LUALIB_API int luaopen_ccr_notify_core(lua_State *L)
{
    pthread_once(&once, ntf_init);
    luaL_register(L, "ccr.notify.core", funcs);
    return 1;
}
