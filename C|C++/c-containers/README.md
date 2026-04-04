# 📦C-lightweight Containers📦
# It is just a C analog of C++ STL containers made in 2-3 hours
# ⚡Motivation⚡
# Why am i even made this? Answer is simple - test my skills in pointer arithmetic, knowledge of pointers, and just for fun
# ✨Features✨
# string:
  # string create_string_blank() - creates a new blank string struct (object)
  # string create_string_from(const char* ch, size_t size) - creates a new string object from string literal or already existing c-string with fixed size
  # void string_destroy(string* str) - destructor for string object(s): deallocates memory, and sets size to -1
  # size_t string_size(string* str) - returns string size (calls string_get_raw_size() in body)
  # size_t string_get_raw_size(string* str) - returns raw c-string size (not including null-termination)
  # void string_fix(string* str) - fixes a broken string (only if its internal pointer is valid)
  # void string_set(string* str, const char* literal) - sets new text to the string object (deallocates old memory)
  # void string_copy(string* source, string* destination) - copies source contents to the destination string
  # void string_swap(string* str1, string* str2) - swaps 2 strings (str1, str2 = str2, str1, like that)
# vector:
  # typedef void (*on_destroy)(void* element) - type alias for the function pointer (used by destructor to destroy objects)
  # typedef void (*on_element)(size_t index, void* element, void* userData) - type alias for the function pointer (used by vector_foreach() function)
  # vector vector_create(size_t itemSize) - creates a new vector
  # void vector_destroy(vector* vec) - destructor for a vector object; iterates over a vector, if it has callback function binded
  # void vector_clear(vector* vec) - clears vector; destroying all elements with onDestroy callback (if binded)
  # void vector_set_at(vector* vec, size_t index, void* element) - inserts new element on provided index; if index is larger than current size, with throw an error (Out of bounds)
  # void* vector_get_at(vector* vec, size_t index) - returns an element from a vector, if it'is not a nullptr.
  # void* vector_get_at_const(const vector* vec, size_t index) - returns an element from a vector as const, if it'is not a nullptr.
  # void vector_foreach(vector* vec, on_element callback, void* userData) - basic algorithm (std::foreach() analog, but without iterators) to iterate over a vector
  # |void vector_internal_reallocate(vector* vec) - internal function; reallocates a vector, if it's reached size limit
