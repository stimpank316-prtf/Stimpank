#include <stdio.h>

#include "cvector.h"

void foreach(size_t index, void* element, void* userData) {
    int* el = (int*)element; // cast back to int pointer
    printf("%d : %d\n", index, *el); // print it;
    printf("----------<%s>----------\n", (const char*)userData); // passed user data, for this case string
}

int main() {
    vector vec = vector_create(sizeof(int), nullptr); // creates a new vector (vector_t)
    int element = 413; // some elements to insert
    int element2 = 9431;
    int element3 = 31413;
    int element4 = 134;

    vector_set_at(&vec, 0, &element); // function to add element to the vector
    vector_set_at(&vec, 1, &element2);
    vector_set_at(&vec, 2, &element3);
    vector_set_at(&vec, 3, &element4);
    vector_set_at(&vec, 4, &element2);

    const char* message = "Hello world!";
    
    vector_foreach(&vec, foreach, message); // function to iterate over a vector, requires callback function and optional userData (void*)
    vector_destroy(&vec); // destroys vector (free the memory)
}
