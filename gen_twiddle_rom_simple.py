#!/usr/bin/python
from math import *

N = 4;
twiddleBits = 12;
reducedBits = False;
# if reducedBits is true, output fits in a twiddleBits bit signed integer.
# if reducedBits is false, output fits in a twiddleBits+1 bit signed integer.

depthOrder = int(ceil(log(N)/log(2.)));
scale = (2**(twiddleBits-1));
if reducedBits:
	scale -= 1
else:
	twiddleBits += 1

fmt = '{0:0' + str(twiddleBits) + 'b}'

name = 'twiddleGenerator'+str(N)

print '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity {2:s} is
	port(clk: in std_logic;
			twAddr: in unsigned({0:d}-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of {2:s} is
	constant romDepthOrder: integer := {0:d};
	constant romDepth: integer := 2**romDepthOrder;
	constant twiddleBits: integer := {1:d};
	constant romWidth: integer := twiddleBits*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others=>'0');
begin
	addr1 <= twAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	twData <= to_complex(signed(data1(twiddleBits-1 downto 0)), signed(data1(data1'left downto twiddleBits)));
	rom <= ('''.format(depthOrder, twiddleBits, name)

for i in xrange(N):
	x = float(i)/N * (2*pi)
	re = cos(x)
	im = sin(x)
	
	re1 = int(round(re*scale));
	im1 = int(round(im*scale));
	
	if re1<0:
		re1 += (2**twiddleBits)
	if im1<0:
		im1 += (2**twiddleBits)
	
	if i != 0:
		print ',',
	print '"' + fmt.format(im1) + fmt.format(re1) + '"', 
	if i%10==9: print;

print;
print ''');
end a;
'''
