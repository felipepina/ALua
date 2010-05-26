/*=========================================================================*\ 
 * Register
 *
 * Auxiliary functions to manage sockets and their names
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#ifndef SOCK_REGISTER_H
#define SOCK_REGISTER_H

/**
 * Registers a pair (key, data)
 *
 * @param name The key
 * @param data The data
 */
void sck_insert(const char *name, void *data);

/**
 * Removes pair (key, data)
 *
 * @param name The look up key
 */
void sck_remove(const char *name);

/**
 * Looks up a name
 *
 * param name The look up key
 */
void* sck_lookup(const char *name);
#endif                                            /* SOCK_REGISTER_H */
