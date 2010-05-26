#ifndef CCR_REGISTER_H
#define CCR_REGISTER_H

void reg_insert(const char *name, void *data);
void reg_remove(const char *name);
void* reg_lookup(const char *name);
#endif
