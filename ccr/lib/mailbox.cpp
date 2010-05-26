/*=========================================================================*\ 
 * Alloc
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstdlib>

#include "ccr/mailbox.h"

using namespace std;

/* see header */
mailbox_t* mbx_create()
{
    mailbox_t *mbox = new mailbox_t;
    if (!mbox) return NULL;
    mbox->closed = 0;
    mbox->counter = 1;
    return mbox;
}


/* see header */
void mbx_upref(mailbox_t *mbox)
{
    mbox->counter++;
}


/* see header */
int mbx_free(mailbox_t *mbox)
{
    message_t *msg;
    if (mbox->counter.fetch_and_decrement() == 1)
    {
        while (mbox->messages.pop_if_present(msg))
            msg_free(msg);
        delete mbox;
        return 1;
    }
    return 0;
}


/* see header */
void mbx_close(mailbox_t *mbox)
{
    message_t *msg;
    mbox->closed = 1;
    while (mbox->messages.pop_if_present(msg))
        msg_free(msg);
}


/* see header */
int mbx_put(mailbox_t *mbox, message_t *msg)
{
    if (mbox->closed) return 0;
    mbox->messages.push(msg);
    return 1;
}


/* see header */
message_t* mbx_get(mailbox_t *mbox)
{
    message_t *msg = NULL;
    if (!mbox->closed)
        mbox->messages.pop(msg);
    return msg;
}


/* see header */
message_t* mbx_tryget(mailbox_t *mbox, int *closed)
{
    message_t *msg;
    if (mbox->messages.pop_if_present(msg))
    {
        *closed = 0;
        return msg;
    }
    *closed = mbox->closed;
    return NULL;
}


/* see header */
int mbx_isempty(mailbox_t *mbox)
{
    return !mbox->closed && mbox->messages.empty();
}


/* see header */
int mbx_isclosed(mailbox_t *mbox)
{
    return mbox->closed;
}
