#include <cstddef>
#include <cstdlib>

extern "C" {

void* __wrap_new8(std::size_t size) {
    void* ptr = nullptr;

    if (posix_memalign(&ptr, 8, size) != 0) {
        return nullptr;
    }
    return ptr;
}

void __wrap_delete8(void* ptr) {
    free(ptr);
}

}

