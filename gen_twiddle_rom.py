#!/usr/bin/python
from math import *
import sys

if len(sys.argv) < 3:
	print 'usage: %s SIZE BITS' % sys.argv[0]
	exit(1)

N = int(sys.argv[1]);
width = int(sys.argv[2]);

size = N/8;
romDepthOrder = int(ceil(log(size)/log(2.)));
romWidth = width - 1;
scale = (2**romWidth);

fmt = '{0:0' + str(romWidth) + 'b}'
name = 'twiddleRom'+str(N)

print '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity {2:s} is
	port(clk: in std_logic;
			romAddr: in unsigned({0:d}-1 downto 0);
			romData: out std_logic_vector({1:d}-1 downto 0)
			);
end entity;
architecture a of {2:s} is
	constant romDepthOrder: integer := {0:d};
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := {1:d};
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0);
	signal data0,data1: std_logic_vector(romWidth-1 downto 0);
begin
	addr1 <= romAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	romData <= data1;
	rom <= ('''.format(romDepthOrder, romWidth*2, name)

for i in xrange(size):
	x = float(i+1)/N * (2*pi)
	re = cos(x)
	im = sin(x)
	
	re1 = int(round(re*scale));
	im1 = int(round(im*scale));
	
	if re1 >= scale: re1 = scale - 1
	if im1 >= scale: im1 = scale - 1
	
	#assert re1 < scale;
	#assert im1 < scale;
	
	if i != 0:
		print ',',
	print '"' + fmt.format(im1) + fmt.format(re1) + '"', 
	if i%10==9: print;

print;
print ''');
end a;
'''
