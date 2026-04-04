#include <stdio.h>

#include "cstring.h"

int main() {
    string blank_string = string_create_blank(); // creates a new blank string object (struct)
    string from_literal = string_create_from("Hello world!", 13); // creates a new string object from string-literal with fixed length

    string_set(&blank_string, "Blank string!"); // sets a text to the blank string
    printf("%s\n", blank_string.data); // prints raw data (char* pointer)
    printf("%s\n", from_literal.data);

    string_swap(&blank_string, &from_literal); // function to swap 2 strings (str1, str2 = str2, str1 like that)
    printf("%s\n", blank_string.data);
    printf("%s\n", from_literal.data);

    string_destroy(&blank_string); // destructor for string (frees allocated memeory)
    string_destroy(&from_literal);
}
