/*=========================================================================*\ 
 * Rawsend
 * Library to help send messages through shared sockets and manage sockets
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include "rawsend.h"

/*
 * Auxiliary functions
 */

/*
 * Wait for the socket
 */
static int sck_waitfd(int sock, int sw)
{
    int ret;
    fd_set rfds, wfds, *rp, *wp;
    do
    {
        /* must set bits within loop, because select may have modifed them */
        rp = wp = NULL;
        if (sw & WAITFD_R) { FD_ZERO(&rfds); FD_SET(sock, &rfds); rp = &rfds; }
        if (sw & WAITFD_W) { FD_ZERO(&wfds); FD_SET(sock, &wfds); wp = &wfds; }
        ret = select(sock+1, rp, wp, NULL, NULL);
    } while (ret == -1 && errno == EINTR);
    if (ret == -1) return errno;
    if (ret == 0) return -2;
    if (sw == WAITFD_C && FD_ISSET(sock, &rfds)) return -2;
    return -1;
}


/*
 * Function to send data through a socket
 *
 * @param sock The socket id
 * @param data The data that will be send
 * @param count The data size
 *
 * @return 0 when sucessfully sent the data or the erro code (ERRORCODE > 0)
 */
static int rawsend(int sock, const char *data, size_t count)
{
    int err;
    ssize_t pos = 0;
    for ( ;; )
    {
        long put = (long) send(sock, (data+pos), count, 0);
        err = errno;
        if (put > 0)
        {
            count -= put;
            if (count == 0)
            {
                return 0;
            }
            pos += put;
        }
        if (put == 0 || err == EPIPE) { printf("PIPE\n"); return -1; }
        if (err == EINTR) continue;
        if (err != EAGAIN && err != EWOULDBLOCK &&
            err != EINPROGRESS && err != ENOENT)
        {
            printf("ERRO %s (%d)\n", strerror(err), err);
            return err;
        }
        if ((err = sck_waitfd(sock, WAITFD_W)) != -1) return err;
    }
    /* can't reach here */
    return -1;
}


/*
 * Exported functions
 */

/* See header file */
static int sck_send(lua_State *L)
{
    int res;
    strsock *tmp;
    const char *name = lua_tostring(L, 1);
    const char *data = lua_tostring(L, 2);
    size_t size = lua_objlen(L, 2);
    tmp = (strsock*)sck_lookup(name);
    // If the name was not found return
    if (!tmp)
    {
        lua_pushnumber(L, -1);
        return 1;
    }
    // cout << "Sending " << name << endl;
    // acquire the write lock of the socket
    pthread_mutex_lock(&tmp->lock);
    res = rawsend(tmp->sock, data, size);
    pthread_mutex_unlock(&tmp->lock);
    lua_pushnumber(L, res);
    return 1;
}


/* See header file */
static int sck_setfd(lua_State *L)
{
    strsock *tmp;
    const char *name = lua_tostring(L, 1);
    tmp = new strsock;
    pthread_mutex_init(&tmp->lock, NULL);
    tmp->sock = lua_tonumber(L, 2);
    sck_insert(name, tmp);
    return 0;
}


/*
 * List of the exported functions
 */
static luaL_Reg funcs[] =
{
    {"send",  sck_send},
    {"setfd", sck_setfd},
    {NULL, NULL}
};

/*
 * Function called by lua to registry the functions of the library
 */
int luaopen_rawsend(lua_State *L)
{
    luaL_register(L, "rawsend", funcs);
    return 1;
}
