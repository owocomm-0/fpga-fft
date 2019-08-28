/*
 * Use this to test the mipmap hierarchy data reorderers;
 * see "mipmapHierarchy / read raw samples" in diagram sdr5_data_order.xml
 * To use this you must bypass the mipmap generator (e.g. by removing it from
 * vivado block design and connecting the axi pipes together)
 * 
 * */

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

#define MYFLAG_BTRANSPOSE (1<<2)
#define MYFLAG_TRANSPOSE0 (1<<3)
#define MYFLAG_WSPLIT (1<<5)
#define MYFLAG_TRANSPOSE1 (1<<6)


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
static const int W = 256, H = 512;

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

OwOComm::AXIPipe* axiPipe;

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


int myLog2(int n) {
	int res = (int)ceil(log2(n));
	assert(int(pow(2, res)) == n);
	return res;
}

inline uint32_t xyToNumber(int x, int y) {
	return x + (y << 16);
}
inline uint64_t upsizeWord(uint32_t a) {
	int16_t re = (a & 0xFFFF);
	int16_t im = a >> 16;
	int32_t re1 = re, im1 = im;
	uint32_t x = re1, y = im1;
	return (uint64_t(y) << 32) | x;
}

// tests dma memory copy
void test1() {
	volatile uint64_t* srcArray = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstArray = (volatile uint64_t*)(reservedMem + sz);

	int inFlags = AXIPIPE_FLAG_INTERLEAVE
				| AXIPIPE_FLAG_TRANSPOSE
				| MYFLAG_BTRANSPOSE
				| MYFLAG_TRANSPOSE0
				| MYFLAG_WSPLIT
				| MYFLAG_TRANSPOSE1;
	int outFlags = 0;

	volatile uint32_t* srcMatrix = (volatile uint32_t*)srcArray;
	int Imask = (W>H) ? (H-1) : (W-1);
	int Ibits = ((W>H) ? myLog2(H) : myLog2(W)) - 1;
	for(int X=0; X<W; X++) {
		uint32_t X1 = (expandBits(X&Imask) | ((X & (~Imask)) << Ibits));
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = (expandBits(Y&Imask) | ((Y & (~Imask)) << Ibits)) << 1;
			uint32_t addr = (X1 | Y1) * burstLength*2;

			int val = Y*8 + X*H*8;
			int xOff = X*4;
			int yOff = Y*2;

			srcMatrix[addr + 0] = xyToNumber(xOff + 0, yOff + 0);
			srcMatrix[addr + 1] = xyToNumber(xOff + 1, yOff + 0);
			srcMatrix[addr + 2] = xyToNumber(xOff + 0, yOff + 1);
			srcMatrix[addr + 3] = xyToNumber(xOff + 1, yOff + 1);
			srcMatrix[addr + 4] = xyToNumber(xOff + 2, yOff + 0);
			srcMatrix[addr + 5] = xyToNumber(xOff + 3, yOff + 0);
			srcMatrix[addr + 6] = xyToNumber(xOff + 2, yOff + 1);
			srcMatrix[addr + 7] = xyToNumber(xOff + 3, yOff + 1);
		}
	}

	for(int i=0; i<N; i++)
		dstArray[i] = 123;

	
	struct timespec startTime, endTime;
	clock_gettime(CLOCK_MONOTONIC, &startTime);
	fprintf(stderr, "dma start\n");

	auto marker = axiPipe->submitRW(srcArray, dstArray, sz, sz*2, inFlags, outFlags);
	
	clock_gettime(CLOCK_MONOTONIC, &endTime);
	fprintf(stderr, "dma end\n");
	fprintf(stderr, "total time %lld us\n", (endTime-startTime)/1000);

	// check results
	int errors = 0;
	for(int i=0; i<(1024*1024); i++) {
		int x = i/1024;
		int y = i - x*1024;
		uint64_t result = dstArray[i];
		uint64_t expected = upsizeWord(xyToNumber(x, y));
		if(result != expected && (errors++) < 10) {
			printf("index %d: expected %lld, got %lld\n", i, expected, result);
		}
	}
}


int main(int argc, char** argv) {
	if(mapReservedMem() < 0) {
		return 1;
	}
	axiPipe = new OwOComm::AXIPipe(0x43C20000, "/dev/uio2");
	axiPipe->reservedMem = reservedMem;
	axiPipe->reservedMemEnd = reservedMemEnd;
	axiPipe->reservedMemAddr = reservedMemAddr;

	test1();
	
	return 0;
}
