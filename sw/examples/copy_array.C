#include "copy_array.H"
#include "owocomm/axi_pipe.H"
#include <assert.h>
using namespace std;
using namespace OwOComm;


void createArray(vector<vector<complexd> >& arr, int W, int H, int w, int h) {
	arr.resize(H*h);
	for(int i=0; i<H*h; i++)
		arr[i].resize(W*w);
}


#define COMPLEX_TO_U64(val) (uint64_t(uint32_t(int32_t((val).real()))) \
						| (uint64_t)(int64_t((val).imag()) << 32))

#define COMPLEX_TO_U32(val) (uint32_t(uint16_t(int16_t((val).real()))) \
						| (uint32_t)(int32_t((val).imag()) << 16))

void copyArraysToMem(const vector<vector<complexd> >& src, volatile void* dst, int W, int H, int w, int h) {
	assert(src.size() == H*h);
	assert(src[0].size() == W*w);
	volatile uint64_t* dstMatrix = (volatile uint64_t*)dst;
	int burstLength = w*h;
	
	for(int X=0; X<W; X++) {
		uint32_t X1 = expandBits(X);
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = expandBits(Y) << 1;
			uint32_t addr = X1 | Y1;
			for(int y=0; y<h; y++)
				for(int x=0; x<w; x++) {
					complexd val = src[Y*h+y][X*w+x];
					dstMatrix[addr * burstLength + y*w + x] = COMPLEX_TO_U64(val);
				}
		}
	}
}

void copyArraysToMemHalfWidth(const vector<vector<complexd> >& src, volatile void* dst, int W, int H) {
	int w=4, h=2;
	assert(src.size() == H*h);
	assert(src[0].size() == W*w);
	volatile uint32_t* dstMatrix = (volatile uint32_t*)dst;
	int burstLength = w*h;
	int Imask = (W>H) ? (H-1) : (W-1);
	int Ibits = ((W>H) ? myLog2(H) : myLog2(W)) - 1;

	for(int X=0; X<W; X++) {
		uint32_t X1 = (expandBits(X&Imask) | ((X & (~Imask)) << Ibits));
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = (expandBits(Y&Imask) | ((Y & (~Imask)) << Ibits)) << 1;
			uint32_t addr = (X1 | Y1) * burstLength;

			dstMatrix[addr + 0] = COMPLEX_TO_U32(src[Y*h+0][X*w+0]);
			dstMatrix[addr + 1] = COMPLEX_TO_U32(src[Y*h+0][X*w+1]);
			dstMatrix[addr + 2] = COMPLEX_TO_U32(src[Y*h+1][X*w+0]);
			dstMatrix[addr + 3] = COMPLEX_TO_U32(src[Y*h+1][X*w+1]);
			dstMatrix[addr + 4] = COMPLEX_TO_U32(src[Y*h+0][X*w+2]);
			dstMatrix[addr + 5] = COMPLEX_TO_U32(src[Y*h+0][X*w+3]);
			dstMatrix[addr + 6] = COMPLEX_TO_U32(src[Y*h+1][X*w+2]);
			dstMatrix[addr + 7] = COMPLEX_TO_U32(src[Y*h+1][X*w+3]);
		}
	}
}

void copyArrayToMemHalfWidth(const complexd* src, volatile void* dst, int W, int H) {
	int w=4, h=2;
	volatile uint32_t* dstMatrix = (volatile uint32_t*)dst;
	int burstLength = w*h;
	int Imask = (W>H) ? (H-1) : (W-1);
	int Ibits = ((W>H) ? myLog2(H) : myLog2(W)) - 1;

	for(int X=0; X<W; X++) {
		uint32_t X1 = (expandBits(X&Imask) | ((X & (~Imask)) << Ibits));
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = (expandBits(Y&Imask) | ((Y & (~Imask)) << Ibits)) << 1;
			uint32_t addr = (X1 | Y1) * burstLength;

			dstMatrix[addr + 0] = COMPLEX_TO_U32(src[Y*h+0 + (X*w+0)*1024]);
			dstMatrix[addr + 1] = COMPLEX_TO_U32(src[Y*h+0 + (X*w+1)*1024]);
			dstMatrix[addr + 2] = COMPLEX_TO_U32(src[Y*h+1 + (X*w+0)*1024]);
			dstMatrix[addr + 3] = COMPLEX_TO_U32(src[Y*h+1 + (X*w+1)*1024]);
			dstMatrix[addr + 4] = COMPLEX_TO_U32(src[Y*h+0 + (X*w+2)*1024]);
			dstMatrix[addr + 5] = COMPLEX_TO_U32(src[Y*h+0 + (X*w+3)*1024]);
			dstMatrix[addr + 6] = COMPLEX_TO_U32(src[Y*h+1 + (X*w+2)*1024]);
			dstMatrix[addr + 7] = COMPLEX_TO_U32(src[Y*h+1 + (X*w+3)*1024]);
		}
	}
}

void copyArraysFromMem(const volatile void* src, vector<vector<complexd> >& dst, int W, int H, int w, int h) {
	assert(dst.size() == H*h);
	assert(dst[0].size() == W*w);
	volatile uint64_t* srcMatrix = (volatile uint64_t*)src;
	int burstLength = w*h;
	
	for(int X=0; X<W; X++) {
		uint32_t X1 = expandBits(X);
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = expandBits(Y) << 1;
			uint32_t addr = (X1 | Y1)*burstLength;
			for(int x=0; x<w; x++)
				for(int y=0; y<h; y++) {
					uint64_t data = srcMatrix[addr + y*w + x];
					int32_t re = int32_t(data);
					int32_t im = int32_t(data>>32);
					dst[X*w+x][Y*h+y] = complexd(re, im);
				}
		}
	}
}


void copyArrayToMem(const complexd* src, volatile void* dst, int W, int H, int w, int h) {
	volatile uint64_t* dstMatrix = (volatile uint64_t*)dst;
	int burstLength = w*h;
	int rows = H*h;
	
	for(int X=0; X<W; X++) {
		uint32_t X1 = expandBits(X);
		uint32_t xx = X*w;
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = expandBits(Y) << 1;
			uint32_t yy = Y*h;
			uint32_t addr = X1 | Y1;
			addr *= burstLength;
			for(int y=0; y<h; y++)
				for(int x=0; x<w; x++) {
					complexd val = src[(xx+x)*rows + (yy+y)];
					dstMatrix[addr + y*w + x] = COMPLEX_TO_U64(val);
				}
		}
	}
}

void copyArrayFromMem(volatile void* src, complexd* dst, int W, int H, int w, int h) {
	volatile uint64_t* srcMatrix = (volatile uint64_t*)src;
	int burstLength = w*h;
	int cols = W*w;
	
	for(int X=0; X<W; X++) {
		uint32_t X1 = expandBits(X);
		uint32_t xx = X*w;
		for(int Y=0;Y<H;Y++) {
			// interleave row and col address
			uint32_t Y1 = expandBits(Y) << 1;
			uint32_t yy = Y*h;
			uint32_t addr = X1 | Y1;
			addr *= burstLength;
			for(int y=0; y<h; y++)
				for(int x=0; x<w; x++) {
					uint64_t data = srcMatrix[addr + y*w + x];
					int32_t re = int32_t(data);
					int32_t im = int32_t(data>>32);
					dst[(xx+x) + (yy+y)*cols] = complexd(re, im);
				}
		}
	}
}
