#include <owocomm/axi_pipe.H>
#include <owocomm/buffer_pool.H>
#include <owocomm/fm_decoder.H>
#include <owocomm/convolve.H>
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
using namespace OwOComm;


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

static const long channelsArrayAddr = 0x43C40000;
volatile uint32_t* channelsArray = NULL;

// the number of elements in each burst
static const int burstLength = 4;

// buffer size in bytes
static const int sz = 1024*1024;

AXIPipe* axiPipe;
MultiBufferPool bufPool;

int mapReservedMem() {
	int memfd;
	if((memfd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		perror("open");
		printf( "ERROR: could not open /dev/mem\n" );
		return -1;
	}
	channelsArray = (volatile uint32_t*) mmap(NULL, 4096, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, channelsArrayAddr);
	if(channelsArray == NULL) {
		close(memfd);
		throw runtime_error(string("ERROR: could not map channelizer array: ") + strerror(errno));
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

volatile uint64_t* buf(int i) {
	return (volatile uint64_t*)(reservedMem + sz*i);
}



class AXIPipeRecv {
public:
	// user parameters
	AXIPipe* axiPipe = nullptr;
	MultiBufferPool* bufPool = nullptr;
	uint32_t hwFlags = AXIPIPE_FLAG_INTERRUPT;
	int bufSize = 0;
	int nTargetPending = 4;

	// this callback is called for every completed buffer;
	// if the function returns false we don't free the buffer.
	function<bool(volatile uint8_t*)> cb;

	// internal state
	int nPending = 0;
	void start() {
		while(nPending < nTargetPending) {
			nPending++;
			volatile uint8_t* buf = bufPool->get(bufSize);
			uint32_t marker = axiPipe->submitWrite(buf, bufSize, hwFlags);
			//printf("submit write; acceptance %d\n", axiPipe->write🅱ufferAcceptance());
			axiPipe->waitWriteAsync(marker, [this, buf]() {
				//printf("write complete\n");
				if(cb(buf))
					bufPool->put(buf);
				nPending--;
				start();
			});
		}
	}
};

uint32_t bytesWritten = 0;
void test1(int ch) {
	channelsArray[0] = ch;
	channelsArray[1] = 0;
	channelsArray[2] = 0;

	bytesWritten = axiPipe->regs[AXIPIPE_REG_BYTESWRITTEN];

	AXIPipeRecv pipeRecv;
	pipeRecv.axiPipe = axiPipe;
	pipeRecv.bufPool = &bufPool;
	pipeRecv.bufSize = sz;
	pipeRecv.cb = [](volatile uint8_t* buf) {
		uint32_t bw = axiPipe->regs[AXIPIPE_REG_BYTESWRITTEN];
		uint32_t tmp = bw - bytesWritten;
		bytesWritten = bw;
		fprintf(stderr, "got %d bytes\n", tmp);
		write(1, (void*) buf, sz);
		return true;
	};
	pipeRecv.start();
	while(true) {
		if(waitForIrq(axiPipe->irqfd) < 0) {
			perror("wait for irq");
			return;
		}
		axiPipe->dispatchInterrupt();
	}
}
void test2(int ch);


int main(int argc, char** argv) {
	if(argc < 2) {
		fprintf(stderr, "usage: %s channel\n", argv[0]);
		return 1;
	}
	if(mapReservedMem() < 0) {
		return 1;
	}
	axiPipe = new OwOComm::AXIPipe(0x43C30000, "/dev/uio3");
	axiPipe->reservedMem = reservedMem;
	axiPipe->reservedMemEnd = reservedMemEnd;
	axiPipe->reservedMemAddr = reservedMemAddr;

	bufPool.init(reservedMem, reservedMemSize);
	bufPool.addPool(sz, 20);

	test2(atoi(argv[1]));
	
	return 0;
}


// fm demodulator

typedef uint64_t SAMPTYPE;
static constexpr int firLength = 245;
static constexpr int bufLength = 8192 - firLength;
extern const double filter_taps[firLength];

struct FMReceiver {
	static const int decimation = 8;
	FMDecoder<SAMPTYPE> fmDec;
	convolve<float> conv;
	int bufLength = 0;
	uint32_t totalSamples = 0;

	void init(int bufLength, int firLength, double* filterTaps) {
		this->bufLength = bufLength;
		conv.init(firLength, bufLength);
		conv.setWaveform(filterTaps);
	}

	// buf must be at most bufLength samples, and outBuf array must be at least
	// bufLength/decimation samples. returns number of samples output.
	int process(SAMPTYPE* buf, int16_t* outBuf, int length) {
		// demodulate fm
		fmDec.putSamples(buf, length);

		// apply fir filter
		int l = fmDec.outBuf.length();
		float* res = conv.process(&fmDec.outBuf[0], l);

		// decimate and output
		int offs = (decimation - (totalSamples % decimation)) % decimation;
		int j = 0;
		for(int i=offs; i<l; i+=decimation) {
			float tmp = res[i]*20000;
			if(tmp > 32767) tmp = 32767;
			if(tmp < -32767) tmp = -32767;
			outBuf[j] = (int16_t) tmp;
			j++;
		}
		totalSamples += l;
		return j;
	}
}

void test2(int ch) {
	channelsArray[0] = ch;
	channelsArray[1] = 0;

	bytesWritten = axiPipe->regs[AXIPIPE_REG_BYTESWRITTEN];

	AXIPipeRecv pipeRecv;
	pipeRecv.axiPipe = axiPipe;
	pipeRecv.bufPool = &bufPool;
	pipeRecv.bufSize = sz;

	FMReceiver fmr;
	int16_t outBuf[bufLength/fmr.decimation];
	fmr.init(bufLength, firLength, filter_taps);

	pipeRecv.cb = [&](volatile uint8_t* buf) {
		uint32_t bw = axiPipe->regs[AXIPIPE_REG_BYTESWRITTEN];
		uint32_t tmp = bw - bytesWritten;
		bytesWritten = bw;
		fprintf(stderr, "got %d bytes\n", tmp);
		int r = fmr.process((uint64_t*) buf, outBuf, sz);
		write(1, outBuf, r * sizeof(*outBuf));
		return true;
	};
	pipeRecv.start();
	while(true) {
		if(waitForIrq(axiPipe->irqfd) < 0) {
			perror("wait for irq");
			return;
		}
		axiPipe->dispatchInterrupt();
	}
}

/*

FIR filter designed with
http://t-filter.appspot.com

sampling frequency: 320000 Hz

* 0 Hz - 15000 Hz
  gain = 1
  desired ripple = 0.3 dB
  actual ripple = 0.005810687083363608 dB

* 22000 Hz - 160000 Hz
  gain = 0
  desired attenuation = -80 dB
  actual attenuation = -111.64782626901567 dB

*/

const double filter_taps[firLength] = {
  0.00000231735090447612,
  0.000005764087621619054,
  0.000009021121315639547,
  0.000015365994870766233,
  0.000021874890251568598,
  0.00003006861380410441,
  0.00003782679039975108,
  0.000045074728952695395,
  0.00004986013188519099,
  0.000051301918956781014,
  0.00004779001721319568,
  0.0000386106881676277,
  0.00002319673256747957,
  0.0000020280627829816633,
  -0.0000237044182737923,
  -0.00005172260866980114,
  -0.00007898986802435213,
  -0.00010179016689352468,
  -0.00011624182297825087,
  -0.00011872178559809241,
  -0.00010650767501840447,
  -0.00007830609862409991,
  -0.00003475764990927791,
  0.00002128808301260715,
  0.00008473081522889326,
  0.00014851906941609189,
  0.0002042643309490727,
  0.00024317312825164735,
  0.00025719791026878306,
  0.00024027749481696326,
  0.0001895197067219968,
  0.00010612942020531961,
  -0.000004090043370989767,
  -0.00013078801133783777,
  -0.0002597717119328281,
  -0.00037435496420903816,
  -0.0004572580102238492,
  -0.0004928772714953691,
  -0.00046966465964081816,
  -0.0003822872903064423,
  -0.0002332395142347588,
  -0.0000336137423526632,
  0.00019721344468355271,
  0.0004330693226247626,
  0.0006436071300924297,
  0.0007978447632656938,
  0.0008682595682576488,
  0.0008349430458087959,
  0.0006892420897023797,
  0.00043634044321455096,
  0.00009627863322713158,
  -0.0002969079855670797,
  -0.0006980560733180842,
  -0.0010555779097719304,
  -0.001317591854744487,
  -0.0014388084357248698,
  -0.0013873232322522667,
  -0.0011503918341741334,
  -0.0007382782526838749,
  -0.00018546062844531863,
  0.00045127406399760847,
  0.0010979195698247242,
  0.0016711911291957494,
  0.0020885480963683855,
  0.0022791789503434114,
  0.002194582462564842,
  0.0018172823348870015,
  0.0011663356232380821,
  0.0002985590789944577,
  -0.0006951051919435754,
  -0.0016980991485083907,
  -0.0025809769931363904,
  -0.0032170930487458132,
  -0.0034994594040787014,
  -0.0033566664551895704,
  -0.0027656834569753375,
  -0.001759555608348801,
  -0.0004285128588121423,
  0.0010862819313358846,
  0.002606206679422579,
  0.003934804341138645,
  0.004881562477049566,
  0.005287154961448839,
  0.005047004755046488,
  0.004129980693204908,
  0.0025893702341893785,
  0.0005640269543763225,
  -0.0017313453361726553,
  -0.004026510248151733,
  -0.006024984122182826,
  -0.007439383613425309,
  -0.008028911514723545,
  -0.007634463492011655,
  -0.006206744136276247,
  -0.003823272996671508,
  -0.0006911822498183461,
  0.002865798660308257,
  0.006435977653701429,
  0.00956186329930123,
  0.011791953600760224,
  0.012736824490846935,
  0.012123241164555928,
  0.00983982386762235,
  0.005968260888812369,
  0.0007953667760919353,
  -0.005196902091861424,
  -0.01136398934615208,
  -0.016951896417393263,
  -0.021166535305041236,
  -0.02325284519641783,
  -0.022575768679233443,
  -0.01869458979770696,
  -0.011422410415043611,
  -0.0008637681668779003,
  0.012574577830147232,
  0.028202020548290713,
  0.04509097033377419,
  0.062148552214153475,
  0.07820676322226768,
  0.09212266052835064,
  0.10287890525292195,
  0.10967479676769133,
  0.11199872571399999,
  0.10967479676769133,
  0.10287890525292195,
  0.09212266052835064,
  0.07820676322226768,
  0.062148552214153475,
  0.04509097033377419,
  0.028202020548290713,
  0.012574577830147232,
  -0.0008637681668779003,
  -0.011422410415043611,
  -0.01869458979770696,
  -0.022575768679233443,
  -0.02325284519641783,
  -0.021166535305041236,
  -0.016951896417393263,
  -0.01136398934615208,
  -0.005196902091861424,
  0.0007953667760919353,
  0.005968260888812369,
  0.00983982386762235,
  0.012123241164555928,
  0.012736824490846935,
  0.011791953600760224,
  0.00956186329930123,
  0.006435977653701429,
  0.002865798660308257,
  -0.0006911822498183461,
  -0.003823272996671508,
  -0.006206744136276247,
  -0.007634463492011655,
  -0.008028911514723545,
  -0.007439383613425309,
  -0.006024984122182826,
  -0.004026510248151733,
  -0.0017313453361726553,
  0.0005640269543763225,
  0.0025893702341893785,
  0.004129980693204908,
  0.005047004755046488,
  0.005287154961448839,
  0.004881562477049566,
  0.003934804341138645,
  0.002606206679422579,
  0.0010862819313358846,
  -0.0004285128588121423,
  -0.001759555608348801,
  -0.0027656834569753375,
  -0.0033566664551895704,
  -0.0034994594040787014,
  -0.0032170930487458132,
  -0.0025809769931363904,
  -0.0016980991485083907,
  -0.0006951051919435754,
  0.0002985590789944577,
  0.0011663356232380821,
  0.0018172823348870015,
  0.002194582462564842,
  0.0022791789503434114,
  0.0020885480963683855,
  0.0016711911291957494,
  0.0010979195698247242,
  0.00045127406399760847,
  -0.00018546062844531863,
  -0.0007382782526838749,
  -0.0011503918341741334,
  -0.0013873232322522667,
  -0.0014388084357248698,
  -0.001317591854744487,
  -0.0010555779097719304,
  -0.0006980560733180842,
  -0.0002969079855670797,
  0.00009627863322713158,
  0.00043634044321455096,
  0.0006892420897023797,
  0.0008349430458087959,
  0.0008682595682576488,
  0.0007978447632656938,
  0.0006436071300924297,
  0.0004330693226247626,
  0.00019721344468355271,
  -0.0000336137423526632,
  -0.0002332395142347588,
  -0.0003822872903064423,
  -0.00046966465964081816,
  -0.0004928772714953691,
  -0.0004572580102238492,
  -0.00037435496420903816,
  -0.0002597717119328281,
  -0.00013078801133783777,
  -0.000004090043370989767,
  0.00010612942020531961,
  0.0001895197067219968,
  0.00024027749481696326,
  0.00025719791026878306,
  0.00024317312825164735,
  0.0002042643309490727,
  0.00014851906941609189,
  0.00008473081522889326,
  0.00002128808301260715,
  -0.00003475764990927791,
  -0.00007830609862409991,
  -0.00010650767501840447,
  -0.00011872178559809241,
  -0.00011624182297825087,
  -0.00010179016689352468,
  -0.00007898986802435213,
  -0.00005172260866980114,
  -0.0000237044182737923,
  0.0000020280627829816633,
  0.00002319673256747957,
  0.0000386106881676277,
  0.00004779001721319568,
  0.000051301918956781014,
  0.00004986013188519099,
  0.000045074728952695395,
  0.00003782679039975108,
  0.00003006861380410441,
  0.000021874890251568598,
  0.000015365994870766233,
  0.000009021121315639547,
  0.000005764087621619054,
  0.00000231735090447612
};




