#ifndef CCR_ALLOC_H
#define CCR_ALLOC_H

/*=========================================================================*\ 
 * Alloc
 *
 * Library to
 *
 * version 1.0 2010/03/01
\*=========================================================================*/

#include <cstddef>
#include <tbb/atomic.h>

using namespace std;
using namespace tbb;

#define ALC_MEMORY_LIMIT 1024

atomic<int>* alc_counter(char *ptr, size_t size);

/*
 *
 *
 */
void *alc_normalize(char *ptr);

/*
 *
 *
 */

void *alc_alloc(void *ud, void *ptr, size_t osize, size_t nsize);
#endif                                            /* CCR_ALLOC_H */
