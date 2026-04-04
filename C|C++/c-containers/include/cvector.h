// lightweight vector-object made in 2 hours on pure C

#include <string.h>
#include <stdlib.h>

typedef void (*on_destroy)(void* element);
typedef void (*on_element)(size_t index, void* element, void* userData);

struct vector_t {
    void* data;
    size_t size;
    size_t maxSize;
    size_t itemSize;
    on_destroy onDestroy;
};

typedef struct vector_t vector;

vector vector_create(size_t itemSize, on_destroy onDestroy);
void vector_destroy(vector* vec);
void vector_clear(vector* vec);
void vector_set_at(vector* vec, size_t index, void* element);
void* vector_get_at(vector* vec, size_t index);
const void* vector_get_at_const(const vector* vec, size_t index);

void vector_foreach(const vector* vec, on_element callback, void* userData);

bool vector_internal_reallocate(vector* vec);
