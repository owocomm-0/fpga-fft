
CXX := clang++-7
CFLAGS ?= -O2


REQUIRED_CXXFLAGS := --std=c++0x -finput-charset=UTF-8 -fextended-identifiers -I./include -I../axi-util/sw/include

CXXFLAGS2 := $(REQUIRED_CXXFLAGS) $(INCLUDES) $(CFLAGS)

all: libaxi_fft.a

%.o: %.C
	$(CXX) -c $(CXXFLAGS2) $< -o $@

../axi-util/sw/libaxi_pipe.a:
	make -C ../axi-util/sw libaxi_pipe.a

libaxi_fft.a: axi_fft.o ../axi-util/sw/libaxi_pipe.a
	ar rcsT $@ $^

clean:
	rm -f *.a *.o
