#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static int al_sleep(lua_State* L)
{
    unsigned int v = (unsigned int)luaL_checkint(L, 1);
    sleep(v);
    return 0;
}


static int al_platform(lua_State* L)
{
    lua_pushstring(L, "unix");
    return 1;
}


static int al_execute(lua_State *L)
{
    int i;
    int max;
    char **argv;
    pid_t child;
    const char *prog;

    /* Check for invalid arguments */
    max = lua_gettop(L);
    for (i = 1; i <= max; i++)
        luaL_checkstring(L, i);

    child = fork();

    /* Error */
    if (child == -1)
    {
        lua_pushboolean(L, 0);
        return 1;
    }
    /* Parent */
    if (child != 0)
    {
        lua_pushboolean(L, 1);
        return 1;
    }

    /* Child */
    /* Create a new session for the child */
    if (setsid() == -1)
        _exit(1);

    /* Retrieve the program name */
    prog = lua_tostring(L, 1);
    /* Arguments */
    argv =  malloc((max+1) * sizeof(char*));
    if (argv == NULL)
        _exit(1);
    argv[0] = (char*) prog;
    for (i = 1; i < max; i++)
        argv[i] = (char*) lua_tostring(L, i+1);
    argv[max] = NULL;

    /* Launch the program */
    execvp(prog, argv);

    /* execvp() error -> nothing to do */
    _exit(1);
}


static luaL_Reg funcs[] =
{
    {"sleep",    al_sleep},
    {"execute",  al_execute},
    {"platform", al_platform},
    {NULL, NULL}
};

int luaopen_alua_core(lua_State *L)
{
    signal(SIGCHLD, SIG_IGN);
    luaL_register(L, "alua.core", funcs);
    return 1;
}
