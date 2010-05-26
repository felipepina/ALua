/*=========================================================================*\ 
 * Register
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstdlib>
#include <cstring>
#include <pthread.h>

#include "list.h"
#include "ccr/register.h"

using namespace std;

typedef struct
{
    char *name;
    mailbox_t *mbox;
} regnode_t;

static list_t *nodes = NULL;
static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

/*
 * See header
 */
int reg_insert(const char *name, mailbox_t *mbox)
{
    size_t len;
    list_t *ptr;
    regnode_t *node;
    pthread_mutex_lock(&lock);
    ptr = nodes;
    while (ptr)
    {
        node = (regnode_t*)ptr->data;
        if (!strcmp(node->name, name))
        {
            pthread_mutex_unlock(&lock);
            return 0;
        }
        ptr = ptr->next;
    }
    len = strlen(name);
    if (len == 0)
    {
        pthread_mutex_unlock(&lock);
        return 0;
    }
    node = (regnode_t*)malloc(sizeof(regnode_t));
    if (!node)
    {
        pthread_mutex_unlock(&lock);
        return 0;
    }
    node->name = (char*)malloc(len+1);
    if (!node->name)
    {
        free(node);
        pthread_mutex_unlock(&lock);
        return 0;
    }
    strncpy(node->name, name, len);
    node->name[len] = '\0';
    node->mbox = mbox;
    mbx_upref(mbox);                              /* increase the reference counter */
    nodes = lst_insert(nodes, (void*)node);
    pthread_mutex_unlock(&lock);
    return 1;
}


/*
 * See header
 */
void reg_remove(const char *name)
{
    regnode_t *node;
    list_t *ptr, *tmp = NULL;
    pthread_mutex_lock(&lock);
    ptr = nodes;
    while (ptr)
    {
        node = (regnode_t*)ptr->data;
        if (!strcmp(name, node->name))
        {
            if (tmp)
                tmp->next = ptr->next;
            else
                nodes = ptr->next;
            free(node->name);
            mbx_free(node->mbox);
            free(node);
            lst_free(ptr);
            break;
        }
        tmp = ptr;
        ptr = ptr->next;
    }
    pthread_mutex_unlock(&lock);
}


/*
 * See header
 */
mailbox_t *reg_lookup(const char *name)
{
    list_t *ptr;
    regnode_t *node;
    mailbox_t *mbox = NULL;
    pthread_mutex_lock(&lock);
    ptr = nodes;
    while (ptr)
    {
        node = (regnode_t*)ptr->data;
        if (!strcmp(name, node->name))
        {
            mbox = node->mbox;
            break;
        }
        ptr = ptr->next;
    }
    mbx_upref(mbox);
    pthread_mutex_unlock(&lock);
    return mbox;
}
