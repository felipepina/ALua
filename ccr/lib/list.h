#ifndef CCR_LIST_H
#define CCR_LIST_H

typedef struct list_st
{
    void *data;
    struct list_st *next;
} list_t;

/*
 * This is a very simple implementation of linked list.
 * In the operations 'insert', 'append', and 'remove', you must
 * reassign the list to the variable because it can be changed.
 *
 * Ex:
 *    lst = lst_insert(lst, d1);
 *    lst = lst_append(lst, d2);
 *    lst = lst_remove(lst, d3);
 */

/**
 * Insert the data as first element.
 */
list_t* lst_insert(list_t *lst, void *dt);

/**
 * Add the element in the end of the list.
 */
list_t* lst_append(list_t *lst, void *dt);

/**
 * Remove the element from the list.
 */
list_t* lst_remove(list_t *lst, void *dt);

/**
 * Free the memory of the single node of the list. (do not affect the others)
 * This function do not free the data in the node.
 */
void lst_free(list_t *lst);

/**
 * Destroy all the list.
 * This function do not free the data in the nodes.
 */
void lst_destroy(list_t *lst);
#endif
