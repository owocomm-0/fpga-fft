#include <owocomm/axi_fft.H>
#include <stdexcept>
namespace OwOComm {

	AXIFFT::AXIFFT(volatile void* regsAddr, int irqfd, int W, int H, int w, int h):
		AXIPipe(regsAddr, irqfd), W(W), H(H), w(w), h(h) {
		setSizes();
	}

	AXIFFT::AXIFFT(uint32_t regsAddr, const char* irqDevice, int W, int H, int w, int h):
		AXIPipe(regsAddr, irqDevice), W(W), H(H), w(w), h(h) {
		setSizes();
	}

	void AXIFFT::setSizes() {
		int sz = W*w*H*h*sizeof(uint64_t);
		pass1InSize = pass1OutSize = pass2InSize = pass2OutSize = sz;
	}

	uint32_t AXIFFT::submitFFT🅱uffers(volatile void* srcBuf, volatile void* dstBuf,
							int srcBytes, int dstBytes, uint32_t srcFlags, uint32_t dstFlags) {
		if(write🅱ufferAcceptance() < 1) throw runtime_error("hw not accepting write 🅱uffers");
		if(read🅱ufferAcceptance() < 1) throw runtime_error("hw not accepting read 🅱uffers");

		uint32_t ret = submit🅱uffer(true, dstBuf, dstBytes, dstFlags | AXIPIPE_FLAG_INTERRUPT);
		submit🅱uffer(false, srcBuf, srcBytes, srcFlags);
		return ret;
	}
	uint32_t AXIFFT::submitFFT(volatile void* srcBuf, volatile void* dstBuf, bool secondPass) {
		uint32_t srcFlags = secondPass?pass2InFlags:pass1InFlags;
		uint32_t dstFlags = secondPass?pass2OutFlags:pass1OutFlags;
		int srcBytes = secondPass?pass2InSize:pass1InSize;
		int dstBytes = secondPass?pass2OutSize:pass1OutSize;

		return submitFFT🅱uffers(srcBuf, dstBuf, srcBytes, dstBytes, srcFlags, dstFlags);
	}
	void AXIFFT::waitFFT(uint32_t marker) {
		waitWrite(marker);
	}

	void AXIFFT::performLargeFFT(volatile void* src, volatile void* dst, volatile void* scratch) {
		uint32_t marker = 0;
		marker = submitFFT(src, scratch);
		waitFFT(marker);
		marker = submitFFT(scratch, dst, true);
		waitFFT(marker);
	}

	void AXIFFT::performLargeFFTAsync(volatile void* src, volatile void* dst, volatile void* scratch, const function<void()>& cb) {
		_dst = dst;
		_scratch = scratch;
		_cb = cb;
		uint32_t marker = submitFFT(src, scratch);
		waitWriteAsync(marker, [this]() {
			uint32_t marker = submitFFT(_scratch, _dst, true);
			waitWriteAsync(marker, _cb);
		});
	}
}
