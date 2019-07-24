
CXX := clang++-7
AXI_UTIL_PATH ?= ../../axi-util/sw
CFLAGS ?= -O2

INCLUDES ?= -I$(AXI_UTIL_PATH)/include -I../include
LIBS ?= -lfftw3

REQUIRED_CXXFLAGS := --std=c++0x -finput-charset=UTF-8 -fextended-identifiers

CXXFLAGS2 := $(REQUIRED_CXXFLAGS) $(INCLUDES) $(CFLAGS)

all: axi_fft_test

%.o: %.C
	$(CXX) -c $(CXXFLAGS2) $< -o $@

../libaxi_fft.a:
	$(MAKE) -C .. libaxi_fft.a

axi_fft_test: axi_fft_test.o copy_array.o ../libaxi_fft.a
	$(CXX) $(LIBS) $^ -o $@

clean:
	rm -f axi_fft_test *.o
