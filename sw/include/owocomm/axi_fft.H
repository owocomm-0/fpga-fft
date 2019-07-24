#include <owocomm/axi_pipe.H>

// enable twiddle multiplier before fft
#define AXIFFT_FLAG_TWIDDLE_MULTIPLY	(1<<2)

// reorder words within each burst
#define AXIFFT_FLAG_BURST_TRANSPOSE		(1<<3)

namespace OwOComm {
	class AXIFFT: public AXIPipe {
	public:
		int W,H,w,h;
		int pass1InSize, pass1OutSize, pass2InSize, pass2OutSize;
		uint32_t pass1InFlags = AXIPIPE_FLAG_INTERLEAVE | AXIFFT_FLAG_BURST_TRANSPOSE;
		uint32_t pass1OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIPIPE_FLAG_TRANSPOSE;
		uint32_t pass2InFlags = AXIPIPE_FLAG_INTERLEAVE | AXIFFT_FLAG_BURST_TRANSPOSE | AXIFFT_FLAG_TWIDDLE_MULTIPLY;
		uint32_t pass2OutFlags = AXIPIPE_FLAG_INTERLEAVE | AXIPIPE_FLAG_TRANSPOSE;

		AXIFFT(volatile void* regsAddr, int W, int H, int w, int h);

		AXIFFT(uint32_t regsAddr, int W, int H, int w, int h);

		void setSizes();

		uint32_t submitFFT🅱uffers(volatile void* srcBuf, volatile void* dstBuf,
								int srcBytes, int dstBytes, uint32_t srcFlags, uint32_t dstFlags);

		uint32_t submitFFT(volatile void* srcBuf, volatile void* dstBuf, bool secondPass=false);

		void waitFFT(uint32_t marker);

		void performLargeFFT(volatile void* src, volatile void* dst, volatile void* scratch);
	};
}
