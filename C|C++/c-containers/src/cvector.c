// use C23 for nullptr
#include <stdio.h>

#include "cvector.h"

vector vector_create(size_t itemSize, on_destroy onDestroy) {
    vector vec;

    size_t targetSize = 10 * itemSize;

    void* data = malloc(targetSize);
    if (!data) return vec;

    vec.data = data;
    vec.itemSize = itemSize;
    vec.onDestroy = onDestroy;
    vec.size = 0;
    vec.maxSize = targetSize;
    return vec;
}

void vector_destroy(vector* vec) {
    if (vec == nullptr) return;

    if (vec->data != nullptr) {
        if (vec->onDestroy != nullptr) {
            for (size_t i = 0; i < vec->size; i++) {
                void* item = (char*)vec->data + (i * vec->itemSize);
                vec->onDestroy(item);
            }
        }

        free(vec->data);
        vec->data = nullptr;
    }

    vec->size = 0;
    vec->maxSize = 0;
    vec->itemSize = 0;
}

void vector_clear(vector* vec) {
    if (vec == nullptr || vec->data == nullptr) return;

    size_t targetSize = 10 * vec->itemSize;
    void* target = malloc(targetSize);
    if (!target) return;

    if (vec->onDestroy) {
        for (size_t i = 0; i < vec->size; i++) {
            void* element = (char)vec->data + (i* vec->itemSize);

            if (element != nullptr) {
                vec->onDestroy(element);
            }
        }
    }

    free(vec->data);
    vec->size = 0;
    
    vec->data = target;
    vec->maxSize = targetSize;
}

void vector_set_at(vector* vec, size_t index, void* element) {
    if (vec == nullptr || vec->data == nullptr || element == nullptr) return;

    if (vec->size >= vec->maxSize) {
        if (!vector_internal_reallocate(vec)) {
            perror("Error code 3: Vector memory reallocation error");
            return;
        }
    }
    
    if (index > vec->size) {
        perror("Error code 1: Out of bounds\n");
        return;
    }

    void* target = (char*)vec->data + (index * vec->itemSize);

    if (target != nullptr) {
        if (vec->onDestroy) {
            vec->onDestroy(target);
        }
    }

    vec->size += 1;

    memcpy(target, element, vec->itemSize);
}

void* vector_get_at(vector* vec, size_t index) {
    if (vec == nullptr || vec->data == nullptr) return nullptr;

    if (index > vec->size) {
        perror("Error code 1: Out of bounds\n");
        return nullptr;
    }

    void* target = (char*)vec->data + (index * vec->itemSize);

    if (target != nullptr) {
        return target;
    }

    return nullptr;
}

const void* vector_get_at_const(const vector* vec, size_t index) {
    if (vec == nullptr || vec->data == nullptr) return nullptr;
    return (const void*)vector_get_at(vec, index);
}

void vector_foreach(const vector* vec, on_element callback, void* userData) {
    if (vec == nullptr || vec->data == nullptr) return;

    for (size_t i = 0; i < vec->size; i++) {
        void* element = (char*)vec->data + (i * vec->itemSize);

        if (element != nullptr) {
            callback(i, element, userData);
        }
    }
}

bool vector_internal_reallocate(vector* vec) {
    if (vec == nullptr || vec->data == nullptr) return false;

    size_t currentSize = vec->maxSize;
    size_t targetSize = currentSize * 2;

    void* newData = realloc(vec->data, targetSize);
    if (!newData) return false;

    vec->data = newData;
    vec->maxSize = targetSize;
    return true;
}
