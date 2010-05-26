#ifndef CCR_THREAD_H
#define CCR_THREAD_H

/*=========================================================================*\ 
 * Thread
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <pthread.h>

typedef pthread_t thread_t;

typedef void (*BubFunc)(void *arg);

/**
 * Execute the script in a new Lua state in a dedicated thread.
 */
thread_t *thr_create(BubFunc func, void *arg);

/**
 * Wait all threads to finish.
 */
void thr_join(thread_t *pid);

/**
 * Release the thread id.
 */
void thr_free(thread_t *pid);

/**
 * Detach -- no more join.
 */
void thr_detach(thread_t *pid);
#endif                                            /* CCR_THREAD_H */
