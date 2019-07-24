#include <complex>
#include <vector>
using namespace std;
typedef complex<double> complexd;

void createArray(vector<vector<complexd> >& arr, int W, int H, int w, int h);

// w,h must be 4,2; row-major
void copyArraysToMemHalfWidth(const vector<vector<complexd> >& src, volatile void* dst, int W, int H);
// col-major
void copyArrayToMemHalfWidth(const complexd* src, volatile void* dst, int W, int H);

void copyArraysToMem(const vector<vector<complexd> >& src, volatile void* dst, int W, int H, int w, int h);
void copyArraysFromMem(const volatile void* src, vector<vector<complexd> >& dst, int W, int H, int w, int h);
void copyArrayToMem(const complexd* src, volatile void* dst, int W, int H, int w, int h);
void copyArrayFromMem(volatile void* src, complexd* dst, int W, int H, int w, int h);



inline uint32_t expandBits(uint32_t val) {
	uint32_t tmp = (val & 0b1);
	tmp |= (val & 0b10) << 1;
	tmp |= (val & 0b100) << 2;
	tmp |= (val & 0b1000) << 3;
	tmp |= (val & 0b10000) << 4;
	tmp |= (val & 0b100000) << 5;
	tmp |= (val & 0b1000000) << 6;
	tmp |= (val & 0b10000000) << 7;
	tmp |= (val & 0b100000000) << 8;
	tmp |= (val & 0b1000000000) << 9;
	return tmp;
}

