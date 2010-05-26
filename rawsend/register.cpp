/*=========================================================================*\ 
 * Register
 *
 * Auxiliary functions to manage sockets and their names
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include "register.h"

#include <string>
#include <tbb/concurrent_hash_map.h>

using namespace std;
using namespace tbb;

class StrCompare
{
    public:
        bool equal(const string &k1, const string &k2) const
        {
            return k1==k2;
        }

        size_t hash(const string &key) const
        {
            size_t h;
            int i, size;
            unsigned char *str;
            h = size = key.size();
            str = (unsigned char*)key.c_str();
            for (i = 0; i < size; i++)
                h = h ^ ((h<<5)+(h>>2)+str[i]);
            return h;
        }
};

// Hash table to register the sockets
typedef concurrent_hash_map<string, void*, StrCompare> StringTable;
static StringTable regdata;

void sck_insert(const char *name, void *data)
{
    string str(name);
    StringTable::accessor a;
    regdata.insert(a, str);
    a->second = data;
    a.release();
}


void sck_remove(const char *name)
{
    string str(name);
    // regdata.erase(str);
    StringTable::accessor a;
    regdata.find(a, str);
    a->second = NULL;
    regdata.erase(a);
}


void* sck_lookup(const char *name)
{
    void *data = NULL;
    string str(name);
    StringTable::const_accessor a;
    if (regdata.find(a, str))
        data = a->second;
    a.release();
    return data;
}
