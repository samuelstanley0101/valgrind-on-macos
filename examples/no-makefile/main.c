// this program intentionally causes a memory leak

#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int* arr = (int*)malloc(1000 * sizeof(int));
    if (arr == NULL) {
        perror("Failed to allocate memory");
        exit(1);
    }
    arr = NULL;  // this is a memory leak
    return 0;
}