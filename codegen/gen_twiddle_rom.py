#!/usr/bin/python
from math import *
import sys

# generates a twiddle rom of SIZE depth supporting the specified widths

if len(sys.argv) < 3:
	print 'usage: %s SIZE WIDTH0 [WIDTH1...]' % sys.argv[0]
	exit(1)

N = int(sys.argv[1]);
widths = [int(x) for x in sys.argv[2:]];

size = N/8;
romDepthOrder = int(ceil(log(size)/log(2.)));
useLUTRAM = (romDepthOrder <= 5)
useBlockRAM = (romDepthOrder >= 8)

name = 'twiddleRom'+str(N)

extraCode = ''
if useLUTRAM:
	extraCode = '''
	attribute rom_style: string;
	attribute rom_style of data0: signal is "distributed";
	attribute rom_style of addr1: signal is "distributed";'''

if useBlockRAM:
	extraCode = '''
	attribute rom_style: string;
	attribute rom_style of data0: signal is "block";
	attribute rom_style of addr1: signal is "block";'''

def printROM(twBits):
	romWidth = (twBits - 1)
	scale = (2**romWidth)
	fmt = '{0:0' + str(romWidth) + 'b}'
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
		if i%6 == 0: print;
		print '"' + fmt.format(im1) + fmt.format(re1) + '"', 

print '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity {1:s} is
	generic(twBits: integer := 17);
	port(clk: in std_logic;
			romAddr: in unsigned({0:d}-1 downto 0);
			romData: out std_logic_vector((twBits-1)*2-1 downto 0)
			);
end entity;
architecture a of {1:s} is
	constant romDepthOrder: integer := {0:d};
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := (twBits-1)*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0);
	signal data0,data1: std_logic_vector(romWidth-1 downto 0);
{2:s}
begin
	addr1 <= romAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	romData <= data1;'''.format(romDepthOrder, name, extraCode)

for twBits in widths:
	print '''
g{twBits:d}:
	if twBits = {twBits:d} generate
		rom <= ('''.format(**locals()), 
	printROM(twBits);
	print ''');
	end generate;'''

print;
print '''
end a;
'''
