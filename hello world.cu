#include <stdio.h>

__global__ void helloWorld() {
    printf("Hello, World from thread %d!\n", threadIdx.x);
}

int main() {
    helloWorld<<<1, 10>>>();
    cudaDeviceSynchronize();
    return 0;
}
