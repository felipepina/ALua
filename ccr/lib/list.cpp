#include <cstdlib>

#include "list.h"

using namespace std;

/* see header */
list_t* lst_insert(list_t *lst, void *dt)
{
    list_t *tmp = (list_t*)malloc(sizeof(list_t));
    tmp->data = dt;
    tmp->next = lst;
    return tmp;
}


/* see header */
list_t* lst_append(list_t *lst, void *dt)
{
    list_t *ptr;
    list_t *tmp = (list_t*)malloc(sizeof(list_t));
    tmp->data = dt;
    tmp->next = NULL;
    ptr = lst;
    while (ptr && ptr->next)
        ptr = ptr->next;
    if (!ptr)
        return tmp;
    ptr->next = tmp;
    return lst;
}


/* see header */
list_t* lst_remove(list_t *lst, void *dt)
{
    list_t *ptr, *prev = NULL;
    ptr = lst;
    while (ptr)
    {
        if (ptr->data == dt)
        {
            if (prev)
                prev->next = ptr->next;
            else
                lst = ptr->next;
            free(ptr);
            break;
        }
        prev = ptr;
        ptr = ptr->next;
    }
    return lst;
}


/* see header */
void lst_free(list_t *lst)
{
    free(lst);
}


/* see header */
void lst_destroy(list_t *lst)
{
    list_t *tmp;
    while (lst)
    {
        tmp = lst;
        lst = lst->next;
        free(tmp);
    }
}
