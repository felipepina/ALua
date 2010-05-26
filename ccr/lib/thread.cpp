/*=========================================================================*\ 
 * Thread
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstdlib>
// #include <pthread.h>

#include "ccr/thread.h"

using namespace std;

typedef struct thrarg_st
{
    BubFunc func;
    void *arg;
} thrarg_t;

static void *spawn(void *arg)
{
    thrarg_t *param = (thrarg_t*)arg;
    param->func(param->arg);
    free(param);
    return NULL;
}


/*
 * See header
 */
thread_t *thr_create(BubFunc func, void *arg)
{
    thrarg_t *param;
    pthread_t *pid = (pthread_t*)malloc(sizeof(pthread_t));
    if (!pid) return NULL;
    param = (thrarg_t*)malloc(sizeof(thrarg_t));
    if (!param)
    {
        free(pid);
        return NULL;
    }
    param->func = func;
    param->arg = arg;
    if (pthread_create(pid, NULL, spawn, (void*)param))
    {
        free(pid);
        free(param);
        return NULL;
    }
    return pid;
}


/*
 * See header
 */
void thr_join(thread_t *pid)
{
    pthread_join(*pid, NULL);
}


/*
 * See header
 */
void thr_free(thread_t *pid)
{
    free(pid);
}


/*
 * See header
 */
void thr_detach(thread_t *pid)
{
    pthread_detach(*pid);
}
