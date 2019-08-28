#include <owocomm/axi_pipe.H>
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

// axi pipe hardware parameters

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
static const int sz = N*8;

int MAXERRORS = 50;

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

// the data returned by the mipmap hardware is a depth first listing of the
// chunk tree. we need to calculate the index within the chunks array given
// the level in the tree (0 being leaf level) and the index among that level.
int locateMipmapChunk(int level, int index) {
	static constexpr int LEVELS = 4;
	int levelSteps[LEVELS] = {4,4,4,256};
	int levelSizes[LEVELS];
	int levelIndex[LEVELS];

	// calculate the total chunk count of each level's nodes, including of its children
	levelSizes[0] = 1;
	for(int i=1; i<LEVELS; i++) {
		levelSizes[i] = levelSizes[i-1]*levelSteps[i-1] + 1;
		printf("level %3d size %10d\n", i, levelSizes[i]);
	}

	// calculate the local indexes (index among children of the same parent node)
	// of the ancestors of the chunk node we are after.
	int currIndex = index;
	for(int i=level; i<LEVELS; i++) {
		levelIndex[i] = currIndex % levelSteps[i];
		currIndex /= levelSteps[i];
		printf("level %3d index %10d\n", i, levelIndex[i]);
	}

	// calculate the total number of chunks in the stream before the chunk we are after
	int ret = 0;
	for(int i=level; i<LEVELS; i++)
		ret += levelIndex[i] * levelSizes[i];

	// if we have selected a chunk that is not a leaf, we have to also
	// skip over all our children to get to the correct chunk.
	if(level > 0)
		ret += levelSteps[level-1] * levelSizes[level-1];

	return ret;
}


// mipmapChunkFinder calculates the absolute chunk array index given
// the mipmap level and the logical chunk index (offset) within that level.
// usage:
// 1. fill out levelSteps with the compression factor of each mipmap level of the hardware
// 2. call init()
// 3. use goToChunk() and/or advanceChunk() as needed, which both set currIndex to the
//    absolute chunk index of the requested chunk.
// 4. repeat (3) as needed
template<int LEVELS>
struct mipmapChunkFinder {
	int levelSteps[LEVELS] = {};
	int levelSizes[LEVELS] = {};
	int levelIndex[LEVELS] = {};
	int currLevel = 0;
	int currIndex = 0;

	void init() {
		// calculate the total chunk count of each level's nodes, including of its children
		levelSizes[0] = 1;
		for(int i=1; i<LEVELS; i++) {
			levelSizes[i] = levelSizes[i-1]*levelSteps[i-1] + 1;
		}
	}

	// jump to the specified chunk index at the specified level
	void goToChunk(int level, int index) {
		currLevel = level;

		// calculate the local indexes (index among children of the same parent node)
		// of the ancestors of the chunk node we are after.
		int tmpIndex = index;
		for(int i=level; i<LEVELS; i++) {
			levelIndex[i] = tmpIndex % levelSteps[i];
			tmpIndex /= levelSteps[i];
		}

		// calculate the total number of chunks in the stream before the chunk we are after
		currIndex = 0;
		for(int i=level; i<LEVELS; i++)
			currIndex += levelIndex[i] * levelSizes[i];

		// if we have selected a chunk that is not a leaf, we have to also
		// skip over all our children to get to the correct chunk.
		if(level > 0)
			currIndex += levelSteps[level-1] * levelSizes[level-1];
	}

	// move to the next chunk in the same level
	void advanceChunk() {
		int level = currLevel;
		currIndex += levelSizes[level];
		if(levelIndex[level] == (levelSteps[level]-1)) {
			for(int i=level+1; i<LEVELS; i++) {
				currIndex++;
				if(levelIndex[i] != (levelSteps[i]-1)) {
					levelIndex[i]++;
					break;
				}
				levelIndex[i] = 0;
			}
			levelIndex[level] = 0;
		} else {
			levelIndex[level]++;
		}
	}
};

void verifyMipmapChunk(int& errors, volatile uint64_t* arr, int& offs, int lower, int step, int count) {
	int stride = 2;
	volatile uint64_t* chunk = arr+offs*stride;
	for(int i=0; i<count; i++) {
		int expectLower = lower + i*step;
		int expectUpper = lower + (i+1)*step - 1;
		int lower = chunk[i*stride] & 0xffffffff;
		int upper = (chunk[i*stride] >> 32) & 0xffffffff;
		if(lower != expectLower && (errors++) < MAXERRORS) {
			fprintf(stderr, "index %d, expected .lower %d, got %d\n", i+offs, expectLower, lower);
		}
		if(upper != expectUpper && (errors++) < MAXERRORS) {
			fprintf(stderr, "index %d, expected .upper %d, got %d\n", i+offs, expectUpper, upper);
		}
	}
	offs += count;
}

void test1() {
	volatile uint64_t* srcArray = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstArray = (volatile uint64_t*)(reservedMem + sz);
	volatile uint64_t* chaffArray = (volatile uint64_t*)(reservedMem + sz*2);

	for(int i=0; i<N; i++)
		chaffArray[i] = rand();

	for(int i=0; i<N; i++)
		srcArray[i] = i;

	for(int i=0; i<N; i++)
		dstArray[i] = 123;

	
	fprintf(stderr, "dma start\n");
	struct timespec startTime, endTime;
	clock_gettime(CLOCK_MONOTONIC, &startTime);


	for(int i=0; i<100; i++)
		axiPipe->waitWrite(axiPipe->submitRW(chaffArray, dstArray, sz, sz, 0, 0));

	axiPipe->submitRW(chaffArray, dstArray, sz, sz, 0, 0);
	axiPipe->waitWrite(axiPipe->submitRW(srcArray, dstArray, sz, sz, 0, 0));


	clock_gettime(CLOCK_MONOTONIC, &endTime);
	fprintf(stderr, "dma end\n");
	fprintf(stderr, "total time %lld us\n", (endTime-startTime)/1000);


	// check results
	int errors = 0;
	int lower = 0, upper = 0;
	int chunkSize = 16;
	int offs = 0;
	for(int h=0; h<256; h++) {
		int lower3 = lower;
		for(int i=0; i<4; i++) {
			int lower2 = lower;
			for(int j=0; j<4; j++) {
				int lower1 = lower;
				for(int k=0; k<4; k++) {
					upper = lower + 4*chunkSize;
					verifyMipmapChunk(errors, dstArray, offs, lower, 4, chunkSize);
					lower = upper;
				}
				verifyMipmapChunk(errors, dstArray, offs, lower1, 4*4, chunkSize);
			}
			verifyMipmapChunk(errors, dstArray, offs, lower2, 4*4*4, chunkSize);
		}
		verifyMipmapChunk(errors, dstArray, offs, lower3, 4*4*4*4, chunkSize);
	}


	mipmapChunkFinder<4> chunkFinder;
	chunkFinder.levelSteps[0] = 4;
	chunkFinder.levelSteps[1] = 4;
	chunkFinder.levelSteps[2] = 4;
	chunkFinder.levelSteps[3] = 256;
	chunkFinder.init();
	chunkFinder.goToChunk(2, 0);
	for(int i=0; i<126; i++)
		chunkFinder.advanceChunk();

	int stride = 2;
	int chunkIndex = chunkFinder.currIndex;
	int elementIndex = chunkIndex*chunkSize*stride;
	for(int i=0; i<chunkSize; i++) {
		uint64_t element = dstArray[elementIndex + i*stride];
		int lower = int(element & 0xffffffff);
		int upper = int((element >> 32) & 0xffffffff);
		printf("%10d %10d\n", lower, upper);
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
