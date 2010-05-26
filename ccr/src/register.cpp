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

typedef concurrent_hash_map<string, void*, StrCompare> StringTable;
static StringTable regdata;

void reg_insert(const char *name, void *data)
{
    string str(name);
    StringTable::accessor a;
    regdata.insert(a, str);
    a->second = data;
    a.release();
}


void reg_remove(const char *name)
{
    string str(name);
    regdata.erase(str);
}


void* reg_lookup(const char *name)
{
    void *data = NULL;
    string str(name);
    StringTable::const_accessor a;
    if (regdata.find(a, str))
        data = a->second;
    a.release();
    return data;
}
