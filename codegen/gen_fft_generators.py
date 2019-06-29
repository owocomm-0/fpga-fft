
# This file contains the functions for generating code for an FFT layout.

from math import *
import sys,random

# imports from local directory
from gen_fft_utils import *
from gen_fft_modules import *


def genDeclarations(fft, id, level, fnName='genDeclarations'):
	params = [id + '_']
	subId1 = id + 'A'
	subId2 = id + 'B'
	if id == 'top':
		subId1 = 'A'
		subId2 = 'B'
	
	if (fnName == 'genDeclarations' or fnName == 'genBody') \
			and not isinstance(fft, FFTBase):
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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
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

def _collectInstances(instanceMap, instanceList, fft):
	if isinstance(fft, FFTBase):
		return

	for ch in fft.children():
		_collectInstances(instanceMap, instanceList, ch)

	key = fft.descriptionStr()
	if not key in instanceMap:
		instanceMap[key] = fft
		instanceList.append(fft)

# generate the complete code for a fft instance and its dependencies
def genFFTSeparated(fft, entityName):
	# collect all instances
	instanceMap = {}
	instanceList = [] # in topological order; dependencies come first
	_collectInstances(instanceMap, instanceList, fft)
	
	# name all instances
	fftSizes = {}
	for inst in instanceList:
		if inst.N in fftSizes:
			fftSizes[inst.N] += 1
			inst._name = entityName + '_sub' + str(inst.N) + '_' + str(fftSizes[inst.N])
		else:
			fftSizes[inst.N] = 1
			inst._name = entityName + '_sub' + str(inst.N)
	
	fft._name = entityName
	
	# generate all instances
	code = []
	for inst in instanceList:
		names = []
		for ch in inst.children():
			if isinstance(ch, FFTBase):
				names.append(ch.entity)
			else:
				names.append(ch._name)

		code.append(inst.genEntity(inst._name, *names))
	
	return '\n\n'.join(code)

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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
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
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
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
'''
	code += '''
	core: entity {0:s} generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, phase=>core_phase({2:d}-1 downto 0), din=>core_din, dout=>core_dout);
	
	oreorderer_phase <= core_phase - {4:d} + 1 when rising_edge(clk);
	
	oreorderer: entity {0:s}_oreorderer{1:d} generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>oreorderer_phase, din=>core_dout, dout=>dout);
end ar;
'''.format(*params)
	return code

