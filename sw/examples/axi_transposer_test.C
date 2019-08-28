#include <owocomm/axi_fft.H>
#include "copy_array.H"

#include <stdio.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdexcept>
#include <complex>
#include <vector>

using namespace std;

#define MYFLAG_ROWTRANSPOSE (1<<5)
#define MYFLAG_INVERSE = (1<<6)


typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint8_t u8;
typedef uint64_t u64;

static const long reservedMemAddr = 0x20000000;
static const long reservedMemSize = 0x10000000;
volatile uint8_t* reservedMem = NULL;
volatile uint8_t* reservedMemEnd = NULL;

// axi fft hardware parameters

typedef u64 fftWord;

// the width (cols) and height (rows) of the matrix in bursts
static const int W = 512, H = 512;

// the width and height of each burst in elements
static const int w = 2, h = 2;

// the size of the matrix in elements
static const int rows = H*h, cols = W*w;

// the total number of elements in the matrix
static const int N = rows*cols;

// the number of elements in each burst
static const int burstLength = w*h;

// the number of bytes occupied by the matrix
static const int sz = N*sizeof(fftWord);

OwOComm::AXIFFT* fft;

int mapReservedMem() {
	int memfd;
	if((memfd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		perror("open");
		printf( "ERROR: could not open /dev/mem\n" );
		return -1;
	}
	reservedMem = (volatile uint8_t*) mmap(NULL, reservedMemSize, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, reservedMemAddr);
	if(reservedMem == NULL) {
		perror("mmap");
		printf( "ERROR: could not map reservedMem\n" );
		return -1;
	}
	reservedMemEnd = reservedMem + reservedMemSize;
	close(memfd);
	return 0;
}

static inline uint64_t timespec_to_ns(const struct timespec *tv)
{
	return (uint64_t(tv->tv_sec) * 1000000000)
		+ (uint64_t)tv->tv_nsec;
}
int64_t operator-(const timespec& t1, const timespec& t2) {
	return int64_t(timespec_to_ns(&t1)-timespec_to_ns(&t2));
}


inline uint32_t ptrToAddr(void* ptr) {
	uint8_t* ptr1 = (uint8_t*)ptr;
	uint8_t* maxBuf = (uint8_t*)reservedMemEnd - sz;
	assert(ptr1 >= reservedMem && ptr <= maxBuf);
	return reservedMemAddr + uint32_t(ptr1-reservedMem);
}

int myLog2(int n) {
	int res = (int)ceil(log2(n));
	assert(int(pow(2, res)) == n);
	return res;
}


void printMatrix(volatile uint64_t* matrix, int subW, int subH) {
	for(int Y=0;Y<subH;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<subW; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);
			
			uint64_t data = matrix[addr];
			int32_t re = int32_t(data);
			int32_t im = int32_t(data>>32);
			printf("%9d,", re);
		}
		printf("\n");
	}
}

// tests converting a linear ordered matrix to a transposed row/col interleaved matrix.
void test_axiTransposer_linear2interleaved() {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);

	fft->pass1InFlags = MYFLAG_ROWTRANSPOSE; // | (1<<2);
	//fft->pass1OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIFFT_FLAG_BURST_TRANSPOSE;
	fft->pass1OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIPIPE_FLAG_TRANSPOSE;

	/*for(int i=0; i<N; i++)
		srcMatrix[i] = (uint64_t(i)*i*i) % uint64_t(-1);
	fft->waitFFT(fft->submitFFT(srcMatrix, dstMatrix, false));*/

	for(int i=0; i<N; i++)
		srcMatrix[i] = i;

	for(int i=0; i<N; i++)
		dstMatrix[i] = 123;

	fft->waitFFT(fft->submitFFT(srcMatrix, dstMatrix, false));

	// check results
	int errors = 0;
	for(int Y=0;Y<rows;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<cols; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);

			uint64_t result = dstMatrix[addr];
			uint64_t expected = X*cols + Y;
			if(result != expected && (errors++) < 10) {
				printf("row %d col %d: expected %llu, got %llu\n", Y, X, expected, result);
			}
		}
	}
	printMatrix(dstMatrix, 16, 16);

	for(int i=0; i<16; i++) {
		uint64_t tmp = dstMatrix[i];
		int32_t a = (int32_t) tmp;
		int32_t b = (int32_t) (tmp >> 32);
		printf("index %d: %10d %10d\n", i, a, b);
	}
}


int main(int argc, char** argv) {
	if(mapReservedMem() < 0) {
		return 1;
	}
	// the AXIFFT class can be used for any block processor attached to an axiPipe
	fft = new OwOComm::AXIFFT(0x43C20000, "/dev/uio2", 512,512,2,2);
	fft->reservedMem = reservedMem;
	fft->reservedMemEnd = reservedMemEnd;
	fft->reservedMemAddr = reservedMemAddr;


	test_axiTransposer_linear2interleaved();
	
	return 0;
}
