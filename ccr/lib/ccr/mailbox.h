#ifndef CCR_MAILBOX_H
#define CCR_MAILBOX_H
#define TBB_DEPRECATED 1

/*=========================================================================*\ 
 * Alloc
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <pthread.h>
#include <tbb/atomic.h>
#include <tbb/concurrent_queue.h>

#include <ccr/message.h>

using namespace tbb;

typedef struct
{
    atomic<int> closed;
    atomic<int> counter;
    concurrent_queue<message_t*> messages;
} mailbox_t;

/**
 * Create a new mailbox.
 *
 * Return:
 *   mailbox - success
 *   NULL    - error
 */
mailbox_t* mbx_create();

/**
 * Increase the mailbox's reference counter.
 */
void mbx_upref(mailbox_t *mbox);

/**
 * Decrease the mailbox's reference counter.
 * If the counter reaches zero, the mailbox is released.
 *
 * Before to release the mailbox, the owner needs to close it.
 *
 * Return:
 *   0 - mailbox is still alive.
 *   1 - mailbox was released.
 */
int mbx_free(mailbox_t *mbox);

/**
 * Close the mailbox and erase all messages.
 *
 * Before to release the mailbox, the owner needs to close it.
 */
void mbx_close(mailbox_t *mbox);

/**
 * Put a message in the mailbox.
 *
 * Return:
 *   0 - Mailbox closed
 *   1 - Success
 */
int mbx_put(mailbox_t *mbox, message_t *msg);

/**
 * Get a message from the mailbox.
 *
 * Return:
 *   message - success
 *   NULL    - closed
 */
message_t* mbx_get(mailbox_t *mbox);

/**
 * Get a message from the mailbox.
 *
 * Return:
 *   message - success
 *   NULL    - empty or closed
 */
message_t* mbx_tryget(mailbox_t *mbox, int *closed);

/**
 * Check if there are messages in the mailbox.
 *
 * Return:
 *   0 - not empty
 *   1 - empty
 */
int mbx_isempty(mailbox_t *mbox);

/**
 * Check if the mailbox is closed.
 *
 * Return:
 *   0 - not closed
 *   1 - closed
 */
int mbx_isclosed(mailbox_t *mbox);
#endif                                            /* CCR_MAILBOX_H */
