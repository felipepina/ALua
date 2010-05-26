#ifndef __LTYPES_H__
#define __LTYPES_H__

#include <stdarg.h>
#include <limits.h>
#include <stddef.h>

#include <lua.h>

/* 
 * lszio.h
 */

typedef struct Zio ZIO;

typedef struct Mbuffer
{
    char *buffer;
    size_t n;
    size_t buffsize;
} Mbuffer;

struct Zio
{
    size_t n;                                     /* bytes still unread */
    const char *p;                                /* current position in buffer */
    lua_Reader reader;
    void* data;                                   /* additional data */
    lua_State *L;                                 /* Lua state (for reader) */
};

/*
 * llimits.h
 */

typedef LUAI_UINT32 lu_int32;

typedef LUAI_UMEM lu_mem;

typedef LUAI_MEM l_mem;

/* chars used as small naturals (so that `char' is reserved for characters) */
typedef unsigned char lu_byte;

/* type to ensure maximum alignment */
typedef LUAI_USER_ALIGNMENT_T L_Umaxalign;

/* result of a `usual argument conversion' over lua_Number */
typedef LUAI_UACNUMBER l_uacNumber;

/*
 ** type for virtual-machine instructions
 ** must be an unsigned with (at least) 4 bytes (see details in lopcodes.h)
 */
typedef lu_int32 Instruction;

/*
 * lobject.h
 */

/* tags for values visible from Lua */
#define LAST_TAG        LUA_TTHREAD

#define NUM_TAGS        (LAST_TAG+1)

/*
 ** Extra tags for non-values
 */
#define LUA_TPROTO      (LAST_TAG+1)
#define LUA_TUPVAL      (LAST_TAG+2)
#define LUA_TDEADKEY    (LAST_TAG+3)

/*
 ** Union of all collectable objects
 */
typedef union GCObject GCObject;

/*
 ** Common Header for all collectable objects (in macro form, to be
 ** included in other objects)
 */
#define CommonHeader    GCObject *next; lu_byte tt; lu_byte marked

/*
 ** Common header in struct form
 */
typedef struct GCheader
{
    CommonHeader;
} GCheader;

/*
 ** Union of all Lua values
 */
typedef union
{
    GCObject *gc;
    void *p;
    lua_Number n;
    int b;
} Value;

/*
 ** Tagged Values
 */

#define TValuefields    Value value; int tt

typedef struct lua_TValue
{
    TValuefields;
} TValue;

typedef TValue *StkId;                            /* index to stack elements */

/*
 ** String headers for string table
 */
typedef union TString
{
    L_Umaxalign dummy;                            /* ensures maximum alignment for strings */
    struct
    {
        CommonHeader;
        lu_byte reserved;
        unsigned int hash;
        size_t len;
    } tsv;
} TString;

typedef union Udata
{
    L_Umaxalign dummy;                            /* ensures maximum alignment for `local' udata */
    struct
    {
        CommonHeader;
        struct Table *metatable;
        struct Table *env;
        size_t len;
    } uv;
} Udata;

/*
 ** Function Prototypes
 */
typedef struct Proto
{
    CommonHeader;
    TValue *k;                                    /* constants used by the function */
    Instruction *code;
    struct Proto **p;                             /* functions defined inside the function */
    int *lineinfo;                                /* map from opcodes to source lines */
    struct LocVar *locvars;                       /* information about local variables */
    TString **upvalues;                           /* upvalue names */
    TString  *source;
    int sizeupvalues;
    int sizek;                                    /* size of `k' */
    int sizecode;
    int sizelineinfo;
    int sizep;                                    /* size of `p' */
    int sizelocvars;
    int linedefined;
    int lastlinedefined;
    GCObject *gclist;
    lu_byte nups;                                 /* number of upvalues */
    lu_byte numparams;
    lu_byte is_vararg;
    lu_byte maxstacksize;
} Proto;

typedef struct LocVar
{
    TString *varname;
    int startpc;                                  /* first point where variable is active */
    int endpc;                                    /* first point where variable is dead */
} LocVar;

/*
 ** Upvalues
 */

typedef struct UpVal
{
    CommonHeader;
    TValue *v;                                    /* points to stack or to its own value */
    union
    {
        TValue value;                             /* the value (when closed) */
        struct                                    /* double linked list (when open) */
        {
            struct UpVal *prev;
            struct UpVal *next;
        } l;
    } u;
} UpVal;

/*
 ** Closures
 */

#define ClosureHeader \
    CommonHeader; lu_byte isC; lu_byte nupvalues; GCObject *gclist; \
    struct Table *env

typedef struct CClosure
{
    ClosureHeader;
    lua_CFunction f;
    TValue upvalue[1];
} CClosure;

typedef struct LClosure
{
    ClosureHeader;
    struct Proto *p;
    UpVal *upvals[1];
} LClosure;

typedef union Closure
{
    CClosure c;
    LClosure l;
} Closure;

/*
 ** Tables
 */

typedef union TKey
{
    struct
    {
        TValuefields;
        struct Node *next;                        /* for chaining */
    } nk;
    TValue tvk;
} TKey;

typedef struct Node
{
    TValue i_val;
    TKey i_key;
} Node;

typedef struct Table
{
    CommonHeader;
    lu_byte flags;                                /* 1<<p means tagmethod(p) is not present */
    lu_byte lsizenode;                            /* log2 of size of `node' array */
    struct Table *metatable;
    TValue *array;                                /* array part */
    Node *node;
    Node *lastfree;                               /* any free position is before this position */
    GCObject *gclist;
    int sizearray;                                /* size of `array' array */
} Table;

/*
 * ltm.h
 */

/*
 * WARNING: if you change the order of this enumeration,
 * grep "ORDER TM"
 */
typedef enum
{
    TM_INDEX,
    TM_NEWINDEX,
    TM_GC,
    TM_MODE,
    TM_EQ,                                        /* last tag method with `fast' access */
    TM_ADD,
    TM_SUB,
    TM_MUL,
    TM_DIV,
    TM_MOD,
    TM_POW,
    TM_UNM,
    TM_LEN,
    TM_LT,
    TM_LE,
    TM_CONCAT,
    TM_CALL,
    TM_N                                          /* number of elements in the enum */
} TMS;

/*
 * lstate.h
 */

struct lua_longjmp;                               /* defined in ldo.c */

typedef struct stringtable
{
    GCObject **hash;
    lu_int32 nuse;                                /* number of elements */
    int size;
} stringtable;

/*
 ** informations about a call
 */
typedef struct CallInfo
{
    StkId base;                                   /* base for this function */
    StkId func;                                   /* function index in the stack */
    StkId top;                                    /* top for this function */
    const Instruction *savedpc;
    int nresults;                                 /* expected number of results from this function */
    int tailcalls;                                /* number of tail calls lost under this entry */
} CallInfo;

/*
 ** `global state', shared by all threads of this state
 */
typedef struct global_State
{
    stringtable strt;                             /* hash table for strings */
    lua_Alloc frealloc;                           /* function to reallocate memory */
    void *ud;                                     /* auxiliary data to `frealloc' */
    lu_byte currentwhite;
    lu_byte gcstate;                              /* state of garbage collector */
    int sweepstrgc;                               /* position of sweep in `strt' */
    GCObject *rootgc;                             /* list of all collectable objects */
    GCObject **sweepgc;                           /* position of sweep in `rootgc' */
    GCObject *gray;                               /* list of gray objects */
    GCObject *grayagain;                          /* list of objects to be traversed atomically */
    GCObject *weak;                               /* list of weak tables (to be cleared) */
    GCObject *tmudata;                            /* last element of list of userdata to be GC */
    Mbuffer buff;                                 /* temporary buffer for string concatentation */
    lu_mem GCthreshold;
    lu_mem totalbytes;                            /* number of bytes currently allocated */
    lu_mem estimate;                              /* an estimate of number of bytes actually in use */
    lu_mem gcdept;                                /* how much GC is `behind schedule' */
    int gcpause;                                  /* size of pause between successive GCs */
    int gcstepmul;                                /* GC `granularity' */
    lua_CFunction panic;                          /* to be called in unprotected errors */
    TValue l_registry;
    struct lua_State *mainthread;
    UpVal uvhead;                                 /* head of double-linked list of all open upvalues */
    struct Table *mt[NUM_TAGS];                   /* metatables for basic types */
    TString *tmname[TM_N];                        /* array with tag-method names */
} global_State;

/*
 ** `per thread' state
 */
struct lua_State
{
    CommonHeader;
    lu_byte status;
    StkId top;                                    /* first free slot in the stack */
    StkId base;                                   /* base of current function */
    global_State *l_G;
    CallInfo *ci;                                 /* call info for current function */
    const Instruction *savedpc;                   /* `savedpc' of current function */
    StkId stack_last;                             /* last free slot in the stack */
    StkId stack;                                  /* stack base */
    CallInfo *end_ci;                             /* points after end of ci array*/
    CallInfo *base_ci;                            /* array of CallInfo's */
    int stacksize;
    int size_ci;                                  /* size of array `base_ci' */
    unsigned short nCcalls;                       /* number of nested C calls */
    unsigned short baseCcalls;                    /* nested C calls when resuming coroutine */
    lu_byte hookmask;
    lu_byte allowhook;
    int basehookcount;
    int hookcount;
    lua_Hook hook;
    TValue l_gt;                                  /* table of globals */
    TValue env;                                   /* temporary place for environments */
    GCObject *openupval;                          /* list of open upvalues in this stack */
    GCObject *gclist;
    struct lua_longjmp *errorJmp;                 /* current error recover point */
    ptrdiff_t errfunc;                            /* current error handling function (stack index) */
};

/*
 ** Union of all collectable objects
 */
union GCObject
{
    GCheader gch;
    union TString ts;
    union Udata u;
    union Closure cl;
    struct Table h;
    struct Proto p;
    struct UpVal uv;
    struct lua_State th;                          /* thread */
};
#endif
