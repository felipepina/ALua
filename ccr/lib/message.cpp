/*=========================================================================*\ 
 * Alloc
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstdlib>
#include <cstring>
#include <cstdio>

#include "ccr/alloc.h"
#include "ccr/message.h"

using namespace std;

message_t* msg_create(char *ptr, size_t size, StringFlag flag)
{
    message_t *msg = (message_t*)malloc(sizeof(message_t));
    if (!msg)
        return NULL;
    msg->size = size;
    if (flag == STR_COPY || (flag == STR_LUA && size < ALC_MEMORY_LIMIT))
    {
        msg->data = (char*)malloc(size);
        if (!msg->data)
        {
            free(msg);
            return NULL;
        }
        memcpy(msg->data, ptr, size);
        msg->counter = NULL;
        msg->flag = STR_COPY;
    }
    else if (flag == STR_LUA)
    {
        msg->data = ptr;
        msg->counter = alc_counter(ptr, (size+1));
        msg->counter->fetch_and_increment();
        msg->flag = STR_LUA;
    }
    else
    {
        msg->counter = NULL;
        msg->data = ptr;
        msg->flag = STR_CONST;
    }
    return msg;
}


/*
 * See header
 */
void msg_free(message_t *msg)
{
    if (msg->flag == STR_COPY)
        free(msg->data);
    else if (msg->flag == STR_LUA)
    {
        if (msg->counter->fetch_and_decrement() == 1)
            free(alc_normalize(msg->data));
    }
    free(msg);
}


/*
 * See header
 */
size_t msg_size(message_t *msg)
{
    return msg->size;
}


/*
 * See header
 */
char* msg_data(message_t *msg)
{
    return msg->data;
}
