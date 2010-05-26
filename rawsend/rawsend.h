#ifndef RAWSEND_H
#define RAWSEND_H

/*=========================================================================*\ 
 * Rawsend
 * Library to help send messages through shared sockets and manage sockets
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <iostream>
#include "register.h"

extern "C"
{
    #include <errno.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <sys/socket.h>
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
    #include <pthread.h>
    #include <string.h>

    int luaopen_rawsend(lua_State *L);
}


using namespace std;

typedef struct
{
    int sock;
    pthread_mutex_t lock;
} strsock;

#define WAITFD_R        1
#define WAITFD_W        2
#define WAITFD_C        (WAITFD_R|WAITFD_W)

/*
 * Sends a message through socket
 * @param string dst The destination's name
 * @param string msg Message to be send to destination especified in the
 *                   name parameter
 *
 * @return Return 0 if the message was sent successfully.
 *         Return -1 when no connection to the correspondent socket was able 
 *         to be made or the destination
 * name wasn't registered.
 */
static int sck_send(lua_State *L);

/*
 * Register a destination to a socket
 * @param string dst The destination's name
 * @param int socketfd The socket (socket file descriptor)
 *
 * @return There is no return
 */
static int sck_setfd(lua_State *L);
#endif                                            /* RAWSEND_H */
