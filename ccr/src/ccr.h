#ifndef CCR_H
#define CCR_H

#include <tbb/atomic.h>
#include <tbb/concurrent_queue.h>
#include <tbb/queuing_rw_mutex.h>

#include <ccr/message.h>
#include <ccr/mailbox.h>

extern "C"
{
    #include <lua.h>

    int luaopen_ccr_core(lua_State *L);
}


using namespace tbb;

#define CCR_SELF    "CCR:Self"
#define CCR_PROCESS "CCR:Process"

enum ProcessStatus {PS_READY, PS_BLOCKING, PS_BLOCKED};

typedef struct
{
    lua_State *L;
    mailbox_t *mbox;
    atomic<int> counter;
    atomic<int> status;
    int main;
    queuing_rw_mutex lock;
    queuing_rw_mutex::scoped_lock wlock;
} process_t;

void prc_upref(process_t *proc);
void prc_free(process_t *proc);
int  ccr_rawsend(process_t *proc, message_t *msg);
#endif
