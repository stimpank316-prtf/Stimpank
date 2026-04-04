// use C23 for nullptr support
#include "cstring.h"

struct string_t {
    char* data;
    size_t size;
};

string string_create_blank() {
    string str;

    char* blank = malloc(1);
    if (!blank) return str;

    blank[0] = '\0';

    str.data = blank;
    str.size = 1;

    return str;
}

string string_create_from(const char* ch, int len) {
    if (ch != nullptr && len > 0) {
        char* buf = malloc(len);
        if (!buf) return string_create_blank();

        memcpy(buf, ch, len);
        string str;
        
        str.data = buf;
        str.size = len;

        return str;
    }
    else {
        return string_create_blank();
    }
}

void string_destroy(string* str) {
    if (str == nullptr) return;

    if (str->data != nullptr) {
        free(str->data);
        str->data = nullptr;
    }
    
    str->size = -1;
}

size_t string_get_raw_size(string* str) {
    if (str == nullptr || str->data == nullptr) return -1;

    size_t count = 0;
    char* current = str->data;

    while (*current != '\0') {
        count += 1;
        current = current + 1;
    }

    return count;
}

size_t string_size(string* str) {
    // including null-termination
    return string_get_raw_size(str) + 1;
}

void string_fix(string* str) {
    if (str == nullptr || str->data == nullptr) return;

    if (str->size != string_size(str)) {
        str->size = string_size(str);
    }
}

void string_set(string* str, const char* literal) {
    if (str != nullptr && str->data != nullptr) {
        size_t size = strlen(literal) + 1;

        char* buf = malloc(size);
        if (!buf) return;

        free(str->data);

        memcpy(buf, literal, size);
        
        str->data = buf;
        str->size = size;
    }
}

void string_copy(string* source, string* destination) {
    if (source == nullptr || destination == nullptr) return;
    if (source == destination) return;
    if (source->data == nullptr) return;

    string_set(destination, source->data);
}

void string_swap(string* str1, string* str2) {
    if (str1 == nullptr || str2 == nullptr) return;
    if (str1 == str2) return;
    if (str1->data == nullptr || str2->data == nullptr) return;

    char* temp = str1->data;
    size_t tempSize = str1->size;

    str1->data = str2->data;
    str2->data = temp;

    str1->size = str2->size;
    str2->size = tempSize;
}
