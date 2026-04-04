// cstring.h, lightweight "safe" strings (made by 1 hour)
// #pramga once to ensure header file is included only once (alternative to include-guards)
#pragma once 

#include <string.h>
#include <stdlib.h>

struct string_t {
    char* data;
    size_t size;
};

typedef struct string_t string;

string string_create_blank();
string string_create_from(const char* ch, int len);

void string_destroy(string* str);

size_t string_size(string* str);
size_t string_get_raw_size(string* str);

void string_fix(string* str);
void string_set(string* str, const char* literal);
void string_copy(string* source, string* destination);
void string_swap(string* str1, string* str2);
