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
#include <fftw3.h>
#include <math.h>

using namespace std;

// if the hardware is the sdr5 fft hierarchy then a custom address permutation
// module is used on the read side, so we need to use different flags
#define SDR5_FLAGS

// if set, uses 16 bit input values (sdr5 fft only)
//#define HALFWIDTH

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


void test1(bool simple) {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);
	
	
	// create input array
	vector<vector<complexd> > inData, outData;
	createArray(inData, W,H,w,h);
	createArray(outData, W,H,w,h);
	srand48(6536795);
	for(int y=0; y<rows; y++) {
		for(int x=0; x<cols; x++) {
			inData[y][x] = simple ? 0 : int((drand48()-0.5)*32767);
		}
	}
	if(simple)
		inData[2][9] = 30000;

#ifdef HALFWIDTH
	copyArraysToMemHalfWidth(inData, srcMatrix, 256,512);
#else
	copyArraysToMem(inData, srcMatrix, W,H,w,h);
#endif

	// submit buffer to hw
	uint32_t marker = fft->submitFFT(srcMatrix, dstMatrix);
	fprintf(stderr, "fft submitted\n");
	fft->waitFFT(marker);
	fprintf(stderr, "fft completed\n");


	copyArraysFromMem(dstMatrix, outData, W,H,w,h);
	
	
	// compute using fftw and compare
	fftw_plan plan;
	complexd* fftw_inp = (complexd*) fftw_malloc(cols*sizeof(complexd));
	complexd* fftw_outp = (complexd*) fftw_malloc(cols*sizeof(complexd));
	double fftw_scale = 1./32;
	assert(fftw_inp);
	assert(fftw_outp);
	assert(sizeof(fftw_complex) == sizeof(complexd));
	plan = fftw_plan_dft_1d(cols, (fftw_complex*)fftw_inp, (fftw_complex*)fftw_outp, FFTW_BACKWARD, 0);
	
	int errs = 0;
	for(int y=0; y<rows; y++) {
		memcpy(fftw_inp, &inData[y][0], cols*sizeof(complexd));
		fftw_execute(plan);
		// compare against hardware fft
		double maxError = 0, errorPower = 0;
		for(int x=0; x<cols; x++) {
			complexd correct = fftw_outp[x]*fftw_scale;
			complexd error = outData[y][x] - correct;
			errorPower += norm(error);
			double errorMag = abs(error);
			if(errorMag > maxError) {
				maxError = errorMag;
				if(errs < 10 && (errorMag > 10)) {
					printf("col %d index %d: should be %.1f, is %.1f\n", y, x, correct.real(), outData[y][x].real());
					errs++;
				}
			}
		}
		if(y < 10)
			printf("max error: %.1f LSB, rms error %.1f LSB\n", maxError, sqrt(errorPower/cols));
	}
	
	for(int Y=0;Y<16;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<16; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);
			
			uint64_t data = dstMatrix[addr];
			int32_t re = int32_t(data);
			int32_t im = int32_t(data>>32);
			printf("%9d,", re);
		}
		printf("\n");
	}
}


void test1_1() {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);
	
	memset((void*)srcMatrix, 0, sz);
	srcMatrix[5] = 30000;

	
	// submit buffer to hw
	struct timespec startTime, endTime;
	clock_gettime(CLOCK_MONOTONIC, &startTime);
	fprintf(stderr, "fft start\n");

	for(int i=0; i<100; i++) {
		uint32_t marker = 0;
		marker = fft->submitFFT(srcMatrix, dstMatrix);
		fft->waitFFT(marker);
	}
	
	clock_gettime(CLOCK_MONOTONIC, &endTime);
	fprintf(stderr, "fft end\n");
	fprintf(stderr, "total time %lld us\n", (endTime-startTime)/1000);


	for(int Y=0;Y<16;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<16; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);
			
			uint64_t data = dstMatrix[addr];
			int32_t re = int32_t(data);
			int32_t im = int32_t(data>>32);
			printf("%9d,", re);
		}
		printf("\n");
	}
}
void test2() {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* scratchMatrix = (volatile uint64_t*)(reservedMem + sz*2);
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);
	
	
	// create input array
	complexd* inData = (complexd*) fftw_malloc(N*sizeof(complexd));
	complexd* outData = (complexd*) fftw_malloc(N*sizeof(complexd));
	complexd* fftw_outp = (complexd*) fftw_malloc(N*sizeof(complexd));
	fftw_plan plan;
	assert(inData);
	assert(outData);
	assert(fftw_outp);
	assert(sizeof(fftw_complex) == sizeof(complexd));
	plan = fftw_plan_dft_1d(N, (fftw_complex*)inData, (fftw_complex*)fftw_outp, FFTW_BACKWARD, FFTW_ESTIMATE);
	
	srand48(6536795);

#ifdef HALFWIDTH
	for(int i=0; i<N; i++)
		inData[i] = round((drand48()-0.5)*30000);
#else
	for(int i=0; i<N; i++)
		inData[i] = round((drand48()-0.5)*1024*1024*100);
#endif

	//inData[0] = 0;
	//inData[3] = complexd(0,1000000);

	memset((void*)dstMatrix, 0, sz);

#ifdef HALFWIDTH
	copyArrayToMemHalfWidth(inData, srcMatrix, W/2,H);
#else
	copyArrayToMem(inData, srcMatrix, W,H,w,h);
#endif


	fprintf(stderr, "fft start\n");
	struct timespec startTime, endTime;
	clock_gettime(CLOCK_MONOTONIC, &startTime);

	for(int i=0; i<100; i++)
		fft->performLargeFFT(srcMatrix, dstMatrix, scratchMatrix);

	clock_gettime(CLOCK_MONOTONIC, &endTime);
	fprintf(stderr, "fft end\n");
	fprintf(stderr, "total time %lld us\n", (endTime-startTime)/1000);




	copyArrayFromMem(dstMatrix, outData, W,H,w,h);
	
	
	
	double fftw_scale = 1./1024;
	fftw_execute(plan);
	// compare against hardware fft
	double maxError = 0, errorPower = 0;
	double maxRatioError = 0;
	double maxVal = 0;
	for(int x=0; x<N; x++) {
		complexd correct = fftw_outp[x]*fftw_scale;
		complexd error = outData[x] - correct;
		double errorMag = abs(error);
		double mag = abs(correct);
		double ratioError = (mag<10) ? 0 : errorMag/mag;
		
		errorPower += norm(error);
		
		if(errorMag > maxError)
			maxError = errorMag;

		if(ratioError > maxRatioError)
			maxRatioError = ratioError;
		
		if(mag > maxVal)
			maxVal = mag;
		if(x <= 10)
			printf("item %d: should be %.1f, is %.1f\n", x, correct.real(), outData[x].real());
	}
	printf("max value: %lld\n", int64_t(round(maxVal)));
	printf("max error: %.1f LSB, rms error %.1f LSB\n", maxError, sqrt(errorPower/N));
	printf("max relative error: %.7f\n", maxRatioError);
	
	for(int Y=0;Y<16;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<16; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);
			
			uint64_t data = dstMatrix[addr];
			int32_t re = int32_t(data);
			int32_t im = int32_t(data>>32);
			printf("%9d,", im);
		}
		printf("\n");
	}
}



void test3(int x, int y) {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);
	
	
	// create input array
	vector<vector<complexd> > inData, outData;
	createArray(inData, W,H,w,h);
	createArray(outData, W,H,w,h);
	srand48(6536795);
	for(int y=0; y<rows; y++) {
		for(int x=0; x<cols; x++) {
			inData[y][x] = 0;
		}
	}
	inData[x][y] = 1024*1024;

	copyArraysToMem(inData, srcMatrix, W,H,w,h);
	
	
	// submit buffer to hw
	uint32_t marker = fft->submitFFT(srcMatrix, dstMatrix);
	fprintf(stderr, "fft submitted\n");
	fft->waitFFT(marker);
	fprintf(stderr, "fft completed\n");
	
	copyArraysFromMem(dstMatrix, outData, W,H,w,h);
	
	
	for(int Y=0;Y<16;Y++) {
		uint32_t Y1 = expandBits(Y/h) << 1;
		for(int X=0; X<0+16; X++) {
			uint32_t X1 = expandBits(X/w);
			uint32_t addr = X1 | Y1;
			addr = addr*burstLength + (Y%h)*w + (X%w);
			
			uint64_t data = dstMatrix[addr];
			int32_t re = int32_t(data);
			int32_t im = int32_t(data>>32);
			printf("%9d,", im);
		}
		printf("\n");
	}
}
void loopbackTest() {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)reservedMem;
	volatile uint64_t* dstMatrix = (volatile uint64_t*)(reservedMem + sz);
	for(int i=0; i<N; i++)
		srcMatrix[i] = (i*i);
	for(int i=0; i<N; i++)
		dstMatrix[i] = 123;

	fft->waitFFT(fft->submitFFT(srcMatrix, dstMatrix, false));
	int errs = 0;
	for(int i=0; i<N; i++) {
		if(srcMatrix[i] != dstMatrix[i]) {
			printf("error: %d should be %lld, is %lld\n", i, srcMatrix[i], dstMatrix[i]);
			if((++errs) >= 10) return;
		}
	}
}


int main(int argc, char** argv) {
	if(mapReservedMem() < 0) {
		return 1;
	}
	fft = new OwOComm::AXIFFT(0x43C10000, 512,512,2,2);
	fft->reservedMem = reservedMem;
	fft->reservedMemEnd = reservedMemEnd;
	fft->reservedMemAddr = reservedMemAddr;
	
	

#ifdef SDR5_FLAGS
	uint32_t MYFLAG_HALFWIDTH = (1<<4) | (1<<1);

	// we used a custom address permutation module so we need to
	// use our custom flags.
	/*fft->pass1InFlags = AXIFFT_FLAG_BURST_TRANSPOSE;
	fft->pass1OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIFFT_FLAG_BURST_TRANSPOSE;
	fft->pass2InFlags = AXIPIPE_FLAG_TRANSPOSE | AXIFFT_FLAG_TWIDDLE_MULTIPLY;
	fft->pass2OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIPIPE_FLAG_TRANSPOSE;*/
#ifdef HALFWIDTH
	fft->pass1InSize = fft->pass1InSize/2;
	fft->pass1InFlags = AXIFFT_FLAG_BURST_TRANSPOSE | MYFLAG_HALFWIDTH;
	//fft->pass1OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIFFT_FLAG_BURST_TRANSPOSE;
	fft->pass2InFlags = AXIFFT_FLAG_BURST_TRANSPOSE | AXIFFT_FLAG_TWIDDLE_MULTIPLY;
	//fft->pass2OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIPIPE_FLAG_TRANSPOSE;
#else
	fft->pass1InFlags = AXIFFT_FLAG_INPUT_BURST_TRANSPOSE;
	fft->pass2InFlags = AXIFFT_FLAG_INPUT_BURST_TRANSPOSE | AXIFFT_FLAG_TWIDDLE_MULTIPLY;
	//fft->pass1OutFlags = AXIPIPE_FLAG_TRANSPOSE;
	//fft->pass2OutFlags = AXIPIPE_FLAG_TRANSPOSE;
#endif // HALFWIDTH

#endif // SDR5_FLAGS

	//test1(false);
	//test1_1();
	test2();
	//test3(atoi(argv[1]), atoi(argv[2]));
	
	//loopbackTest();
	
	return 0;
}
