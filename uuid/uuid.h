#ifndef UUID_H
#define UUID_H

/*=========================================================================*\ 
 * UUID - Universally Unique Identifier
 * Library to create uuid (Universally Unique Identifier). Interface to the
 * OSSP uuid library.
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <stdlib.h>
#include <string.h>
#include <ossp/uuid.h>
#include <openssl/sha.h>
#include <lua.h>
#include <lauxlib.h>

/**
 * Creates a uuid.
 * @param type The type of uuid to create. Possible options are:
 *  bin for binary representation
 *  str for string representation
 *  txt for textual description
 *  siv for integer value
 *
 * @return The uuid created
 */
static int create(lua_State *L);

/**
 * Generates a hash
 * @param id
 *
 * @return The uuid hash
 */
static int hash(lua_State *L);
#endif                                            /* UUID_H */
