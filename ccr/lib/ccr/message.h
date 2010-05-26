#ifndef CCR_MESSAGE_H
#define CCR_MESSAGE_H

/*=========================================================================*\ 
 * Message
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <tbb/atomic.h>

using namespace tbb;

enum StringFlag {STR_COPY, STR_LUA, STR_CONST};

typedef struct
{
    StringFlag flag;
    size_t size;
    char *data;
    atomic<int> *counter;
} message_t;

/**
 * Create a new message.
 *
 * Return:
 *   message - success
 *   NULL    - error
 *
 */
message_t* msg_create(char *ptr, size_t size, StringFlag flag);

/**
 * Decrease the message's reference counter.
 * If the counter reaches zero, the message is released.
 */
void msg_free(message_t *msg);

/**
 * Return the size of the message, that is applied only to
 * MSG_DATA message type.
 */
size_t msg_size(message_t *msg);

/**
 * Return the reference to message's content.
 */
char* msg_data(message_t *msg);
#endif                                            /* CCR_MESSAGE_H */
