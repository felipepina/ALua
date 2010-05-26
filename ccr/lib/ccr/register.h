#ifndef CCR_REGISTER_H
#define CCR_REGISTER_H

/*=========================================================================*\ 
 * Register
 *
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <ccr/mailbox.h>

/**
 * Register the mailbox with the given name.
 *
 * Return:
 *   0 - The name already exists
 *   1 - Success
 */
int reg_insert(const char *name, mailbox_t *mbox);

/**
 * Unregister the mailbox.
 */
void reg_remove(const char *name);

/**
 * Return the mailbox registered with the given name.
 *
 * Return:
 *   channel - Success
 *   NULL    - Not found
 *
 * Note: the mailbox's reference counter is increased, free the
 *   returned mailbox after use it.
 */
mailbox_t *reg_lookup(const char *name);
#endif                                            /* CCR_REGISTER_H */
