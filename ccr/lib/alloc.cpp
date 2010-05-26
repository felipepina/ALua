/*=========================================================================*\ 
 * Alloc
 * 
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstdlib>
#include <cstring>

#include "ccr/alloc.h"

extern "C"
{
    #include "ltypes.h"
}


using namespace std;

#define ALC_LIMIT (ALC_MEMORY_LIMIT+sizeof(TString))

#define alc_align      sizeof(L_Umaxalign)
#define alc_padding(s) ((s)%alc_align ? alc_align-((s)%alc_align) : 0)
#define alc_size(s)    ((s)+alc_padding(s)+sizeof(atomic<int>**))

static atomic<int>** alc_ptrcounter(void *ptr, size_t size)
{
    return (atomic<int>**)((char*)ptr+(size+alc_padding(size)));
}


atomic<int>* alc_counter(char *ptr, size_t size)
{
    return *(alc_ptrcounter(ptr, size));
}


void *alc_normalize(char *ptr)
{
    return ptr-sizeof(TString);
}


void *alc_alloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
    atomic<int> **counter;
    if (osize == 0 && nsize == 0)
        return NULL;
    if (nsize == 0)
    {
        if (osize < ALC_LIMIT)
            free(ptr);
        else
        {
            counter = alc_ptrcounter(ptr, osize);
            if ((*counter)->fetch_and_decrement() == 1)
            {
                delete *counter;
                free(ptr);
            }
        }
        return NULL;
    }
    if (!ptr)
    {
        if (nsize < ALC_LIMIT)
            ptr = malloc(nsize);
        else
        {
            ptr = malloc(alc_size(nsize));
            if (ptr)
            {
                counter = alc_ptrcounter(ptr, nsize);
                *counter = new atomic<int>;
                **counter = 1;
            }
        }
    }
    else
    {
        if (osize < ALC_LIMIT)
        {
            if (nsize < ALC_LIMIT)
                ptr = realloc(ptr, nsize);
            else
            {
                ptr = realloc(ptr, alc_size(nsize));
                if (ptr)
                {
                    counter = alc_ptrcounter(ptr, nsize);
                    *counter = new atomic<int>;
                    **counter = 1;
                }
            }
        }
        else
        {
            counter = alc_ptrcounter(ptr, osize);
            if (nsize < ALC_LIMIT)
            {
                delete *counter;
                ptr = realloc(ptr, nsize);
            }
            else
            {
                atomic<int> *tmp = *counter;
                ptr = realloc(ptr, alc_size(nsize));
                if (ptr)
                {
                    counter = alc_ptrcounter(ptr, nsize);
                    *counter = tmp;
                }
            }
        }
    }
    return ptr;
}
