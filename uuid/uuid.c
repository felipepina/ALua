#include "uuid.h"
/*=========================================================================*\ 
 * UUID - Universally Unique Identifier
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

/*
 * Exported functions
 */
static int create(lua_State *L)
{
    uuid_t *uuid;
    uuid_fmt_t fmt;
    size_t len = 0;
    char *str = NULL;
    const char *ch = luaL_checkstring(L, 1);
    int flag = lua_toboolean(L, 2) ? UUID_MAKE_MC : 0;
    if (strncmp(ch, "bin", 3) == 0)
        fmt = UUID_FMT_BIN;
    else if (strncmp(ch, "str", 3) == 0)
        fmt = UUID_FMT_STR;
    else if (strncmp(ch, "txt", 3) == 0)
        fmt = UUID_FMT_TXT;
    else if (strncmp(ch, "siv", 3) == 0)
        fmt = UUID_FMT_SIV;
    else
    {
        lua_pushnil(L);
        lua_pushstring(L, "invalid format");
        return 2;
    }
    uuid_create(&uuid);
    uuid_make(uuid, UUID_MAKE_V1 | flag);
    uuid_export(uuid, fmt, &str, &len);
    uuid_destroy(uuid);
    if (fmt == UUID_FMT_BIN)
        lua_pushlstring(L, str, len);
    else
        lua_pushstring(L, str);
    free(str);
    return 1;
}


/*
 * List of the exported functions
 */
static luaL_Reg funcs[] =
{
    {"create", create},
    {NULL,     NULL}
};

/*
 * Function called by lua to registry the functions of the library
 */
int luaopen_uuid(lua_State *L)
{
    luaL_register(L, "uuid", funcs);
    return 1;
}
