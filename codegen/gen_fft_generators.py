
# This file contains the functions for generating code for an FFT layout.

from math import *
import sys,random

# imports from local directory
from gen_fft_utils import *
from gen_fft_modules import *
from gen_fft_large import *


def genDeclarations(fft, id, level, fnName='genDeclarations'):
	params = [id + '_']
	subId1 = id + 'A'
	subId2 = id + 'B'
	if id == 'top':
		subId1 = 'A'
		subId2 = 'B'
	
	if not fft.isBase:
		params += [subId1 + '_', subId2 + '_']
	
	# call gen*
	tmp = getattr(fft, fnName)(*params).strip()
	if len(tmp) == 0: return ''
	
	code = indent(('-- ====== FFT instance \'%s\' (N=%d) ======\n' % (id, fft.N)) + tmp, level)

	if isinstance(fft, FFTBase):
		return code

	tmp = genDeclarations(fft.sub1, subId1, level+1, fnName)
	if tmp != '':
		code += '\n\n' + tmp
	
	tmp = genDeclarations(fft.sub2, subId2, level+1, fnName)
	if tmp != '':
		code += '\n\n' + tmp
	return code

def genImports(fft):
	ret = fft.imports
	if isinstance(fft, FFTBase):
		return ret
	ret.extend(genImports(fft.sub1))
	ret.extend(genImports(fft.sub2))
	return ret

def genFFT(fft, entityName):
	code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
'''
	imports = genImports(fft)
	importsSet = set()
	for imp in imports:
		if not imp in importsSet:
			importsSet.add(imp)
			code += 'use work.%s;\n' % imp
	
	params = [bitOrderDescription(fft.inputBitOrder()),
			bitOrderDescription(fft.outputBitOrder()),
			fft.delay(),
			entityName,
			myLog2(fft.N)]
	code += '''
-- data input bit order: {0:s}
-- data output bit order: {1:s}
-- phase should be 0,1,2,3,4,5,6,...
-- delay is {2:d}
entity {3:s} is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned({4:d}-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of {3:s} is
'''.format(*params)
	
	code += genDeclarations(fft, 'top', 1, 'genConstants')
	code += '\n\n\t--=======================================\n\n'
	code += genDeclarations(fft, 'top', 1, 'genDeclarations')
	code += '''
begin
	top_in <= din;
	top_phase <= phase;
	dout <= top_out;
'''
	code += genDeclarations(fft, 'top', 1, 'genBody')
	code += '''
end ar;
'''
	return code

def _collectTypes(typeMap, typeList, fft):
	if isinstance(fft, FFTBase):
		return

	for ch in fft.children():
		_collectTypes(typeMap, typeList, ch)

	key = fft.descriptionStr()
	if key in typeMap:
		typeMap[key].append(fft)
	else:
		typeMap[key] = [fft]
		typeList.append(key)

# generate the complete code for a fft instance and its dependencies
# returns list of tuple (filename, codeStr)
def genFFTSeparated(fft, entityName):
	# collect all instances
	typeMap = {}
	typeList = [] # in topological order; dependencies come first
	_collectTypes(typeMap, typeList, fft)
	
	# name all instances
	fftSizes = {}
	for typeStr in typeList:
		inst = typeMap[typeStr][0]
		
		# pick an entity name for this type
		name = entityName + '_sub' + str(inst.N)
		if inst.N in fftSizes:
			fftSizes[inst.N] += 1
			name = entityName + '_sub' + str(inst.N) + '_' + str(fftSizes[inst.N])
		else:
			fftSizes[inst.N] = 1

		# annotate all instances with the entity name
		for inst in typeMap[typeStr]:
			inst._name = name

	fft._name = entityName
	
	# generate all instances
	code = []
	for typeStr in typeList:
		inst = typeMap[typeStr][0]
		names = []
		for ch in inst.children():
			if isinstance(ch, FFTBase):
				names.append(ch.entity)
			else:
				names.append(ch._name)
		code.append([inst._name + '.vhd', inst.genEntity(inst._name, *names)])

	return code

# generate a input/output reorderer for converting between natural order
# and fft order, with `rows` interleaved channels
def genReorderer(fft, isOutput, rows, entityName):
	colBits = myLog2(fft.N)
	rowBits = myLog2(rows)
	totalBits = colBits + rowBits
	
	fftDataOrder = None
	dataOrder = None
	if isOutput:
		fftDataOrder = fft.outputBitOrder()
		dataOrder = [x+rowBits for x in fftDataOrder] + range(0, rowBits)
	else:
		fftDataOrder = fft.inputBitOrder()
		dataOrder = range(colBits, colBits+rowBits) + fftDataOrder
	
	perm = BitPermutation(dataOrder)
	
	#print bitOrderConstraintLength(dataOrder)
	#return ''
	
	code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.reorderBuffer;
'''
	params = [
			2**totalBits,
			entityName,
			totalBits,
			bitOrderDescription(dataOrder)]
	code += '''
-- phase should be 0,1,2,3,4,5,6,...
-- delay is {0:d}
-- fft bit order: {3:s}
entity {1:s} is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned({2:d}-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of {1:s} is
'''.format(*params)
	
	code += indent(perm.genDeclarations(''), 1)
	code += indent(perm.genConstants(''), 1)
	
	params = [totalBits,
				perm.sigIn(''),
				perm.sigCount(''),
				perm.sigOut(''),
				perm.repLen]
	code += '''
begin
	rb: entity reorderBuffer
		generic map(N=>{0:d}, dataBits=>dataBits, repPeriod=>{4:d}, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>{1:s}, bitPermCount=>{2:s}, bitPermOut=>{3:s});
'''.format(*params)
	code += indent(perm.genBody(''), 1)
	code += '''
end ar;
'''
	return code


# generate a wrapper for fft that accepts and outputs data in natural order
def genReordererWrapper(fft, rows, entityName, fftName):
	colBits = myLog2(fft.N)
	rowBits = myLog2(rows)
	totalBits = colBits + rowBits
	skipInputReorder = (rows == 1) and bitOrderIsNatural(fft.inputBitOrder())

	reorderDelay = fft.N * rows

	delay = reorderDelay + fft.delay()
	if not skipInputReorder:
		delay += reorderDelay

	code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.{0:s};
use work.{0:s}_ireorderer{1:d};
use work.{0:s}_oreorderer{1:d};
'''.format(fftName, rows)
	
	#          0         1           2       3
	params = [delay, entityName, totalBits, rows]
	code += '''
-- {3:d} interleaved channels, natural order
-- phase should be 0,1,2,3,4,5,6,...
-- din should be ch0d0, ch1d0, ch2d0, ch3d0, ch0d1, ch1d1, ... (if 4 channels)
-- delay is {0:d}
entity {1:s} is
	generic(dataBits: integer := 24; twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned({2:d}-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of {1:s} is
	signal core_din, core_dout: complex;
	signal core_phase: unsigned({2:d}-1 downto 0);
	signal oreorderer_phase: unsigned({2:d}-1 downto 0);
begin
'''.format(*params)

	#          0         1      2         3            4
	params = [fftName, rows, colBits, reorderDelay, fft.delay()]
	
	if skipInputReorder:
		code += '''
	core_din <= din;
	core_phase <= phase;
'''
	else:
		code += '''
	ireorder: entity {0:s}_ireorderer{1:d} generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>phase, din=>din, dout=>core_din);

	core_phase <= phase - {3:d} + 1 when rising_edge(clk);
'''.format(*params)
	code += '''
	core: entity {0:s} generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, phase=>core_phase({2:d}-1 downto 0), din=>core_din, dout=>core_dout);
	
	oreorderer_phase <= core_phase - {4:d} + 1 when rising_edge(clk);
	
	oreorderer: entity {0:s}_oreorderer{1:d} generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>oreorderer_phase, din=>core_dout, dout=>dout);
end ar;
'''.format(*params)
	return code



# generate a large fft core (twiddle multiply followed by fft)
def genLargeFFT(fft, burstWidth, entityName, fftName):
	inst = FFTLarge(fft, burstWidth)
	return inst.genEntity(entityName, fftName)


# generate a AXI stream wrapper for a large FFT
def genAXIWrapper(fft, burstWidth, entityName, largeFFTName):
	inst = FFTLarge(fft, burstWidth)
	N = fft.N**2
	totalBits = myLog2(N)
	delay = inst.delay()
	code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.clockGating;
use work.axiBlockProcessorAdapter2;
use work.{largeFFTName:s};

entity {entityName:s} is
	generic(dataBits: integer := 32; twBits: integer := 24);
	port(aclk, aclk_unbuffered, reset: in std_logic;
		din_tvalid: in std_logic;
		din_tready: out std_logic;
		din_tdata: in std_logic_vector(dataBits*2-1 downto 0);

		dout_tvalid: out std_logic;
		dout_tready: in std_logic;
		dout_tdata: out std_logic_vector(dataBits*2-1 downto 0);

		inFlags, outFlags: in std_logic_vector(6 downto 0));
end entity;
architecture ar of {entityName:s} is
	attribute X_INTERFACE_INFO : string;
	attribute X_INTERFACE_PARAMETER : string;
	attribute X_INTERFACE_INFO of aclk : signal is "xilinx.com:signal:clock:1.0 signal_clock CLK";
	attribute X_INTERFACE_INFO of aclk_unbuffered : signal is "xilinx.com:signal:clock:1.0 signal_clock CLK";
	attribute X_INTERFACE_PARAMETER of aclk: signal is "ASSOCIATED_BUSIF din:dout:inFlags:outFlags";

	constant largeOrder: integer := {totalBits:d};
	signal fftClk_gated: std_logic;
	signal bp_ce, bp_ostrobe: std_logic;
	signal inFlags1, outFlags1: std_logic_vector(6 downto 0);
	signal bp_ce1, bp_ce2: std_logic;
	signal bp_indata, bp_outdata, bp_indata1, bp_indata2: std_logic_vector(dataBits*2-1 downto 0);
	signal bp_inphase, bp_inphase1, bp_inphase2, gated_inphase: unsigned(largeOrder-1 downto 0);
	signal gated_din, gated_dout: complex;
begin
	adapter: entity axiBlockProcessorAdapter2
		generic map(frameSizeOrder=>largeOrder, wordWidth=>dataBits*2, processorDelay=>{delay:d})
		port map (
			aclk => aclk,
			bp_ce => bp_ce,
			bp_indata => bp_indata,
			bp_inphase => bp_inphase,
			bp_ostrobe => bp_ostrobe,
			bp_outdata => bp_outdata,
			doFlush => '1',
			inp_tdata => din_tdata,
			inp_tready => din_tready,
			inp_tvalid => din_tvalid,
			outp_tdata => dout_tdata,
			outp_tready => dout_tready,
			outp_tvalid => dout_tvalid,
			reset => reset);

	bp_ce1 <= bp_ce when rising_edge(aclk);
	bp_ce2 <= bp_ce1 when rising_edge(aclk);
	bp_indata1 <= bp_indata when rising_edge(aclk);
	bp_indata2 <= bp_indata1 when rising_edge(aclk);
	bp_inphase1 <= unsigned(bp_inphase) when rising_edge(aclk);
	bp_inphase2 <= unsigned(bp_inphase1) when rising_edge(aclk);
	bp_ostrobe <= bp_ce2;

	cg: entity clockGating
		port map(clkInUnbuffered=>aclk_unbuffered,
				ce=>bp_ce2,
				clkOutGated=>fftClk_gated);

	-- start of gated clock domain
	gated_din <= to_complex(signed(bp_indata2(dataBits-1 downto 0)), signed(bp_indata2(dataBits*2-1 downto dataBits)));
	gated_inphase <= bp_inphase2;

	inFlags1 <= inFlags when gated_inphase=(2**(gated_inphase'length) - 20) and rising_edge(fftClk_gated);
	outFlags1 <= outFlags when gated_inphase=(2**(gated_inphase'length) - 20) and rising_edge(fftClk_gated);

	fft: entity {largeFFTName:s}
		generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>fftClk_gated, din=>gated_din,
				twMultEnable=>inFlags1(2),
				inTranspose=>inFlags1(3), outTranspose=>outFlags1(3),
				phase=>gated_inphase,
				dout=>gated_dout);

	bp_outdata <= std_logic_vector(resize(gated_dout.im, dataBits)) &
					std_logic_vector(resize(gated_dout.re, dataBits));
end ar;
'''.format(**locals())
	return code

