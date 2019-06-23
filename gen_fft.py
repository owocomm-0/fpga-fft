#!/usr/bin/python
from math import *
import sys,random

def myLog2(N):
	tmp = log(N)/log(2.)
	tmp = int(tmp)
	assert 2**tmp == N
	return tmp

def boolStr(b):
	if b:
		return 'true'
	else:
		return 'false'

def serializeSymbol(val):
	if type(val) is int:
		return str(val)
	if type(val) is str:
		return '\'' + val.replace('\\', '\\\\').replace('\'', '\\\'') + '\''
	raise TypeError(str(type(val)))


def bitOrderDescription(bitOrder):
	listStr = ','.join([str(x) for x in reversed(bitOrder)])
	return '(%d downto 0) [%s]' % (len(bitOrder)-1, listStr)

def bitOrderIsNatural(bitOrder):
	for i in xrange(len(bitOrder)):
		if bitOrder[i] != i:
			return False
	return True

def bitOrderToVHDL(bitOrder, srcSignal):
	if bitOrderIsNatural(bitOrder):
		return srcSignal
	fmt = srcSignal + '(%d)'
	return '&'.join([fmt % i for i in bitOrder[::-1]])

def bitOrderNTimes(bitOrder, n):
	res = range(len(bitOrder))
	for i in xrange(n):
		res = [res[x] for x in bitOrder]
	return res

def bitOrderConstraintLength(bitOrder):
	tmp = range(len(bitOrder))
	for i in xrange(1000):
		tmp = [tmp[x] for x in bitOrder]
		if bitOrderIsNatural(tmp): return i+1
	assert False

def addIndent(s):
	ret = []
	for line in s.split('\n'):
		ret.append('\t' + line)
	return '\n'.join(ret)

def commentOut(s):
	ret = []
	for line in s.split('\n'):
		ret.append('--' + line)
	return '\n'.join(ret)

class BitPermutation:
	def __init__(self, bitOrder):
		self.bitOrder = bitOrder
		self.N = len(bitOrder)
		self.repLen = bitOrderConstraintLength(bitOrder)
		self.stateBits = int(ceil(log(self.repLen)/log(2)))
	
	def genConstants(self, id):
		return ''
	
	def genDeclarations(self, id):
		fmt = id + 'rP%d'
		signals = [(fmt % i) for i in range(self.stateBits+1)]
		
		fmt = 'signal %s: unsigned(%d-1 downto 0);'
		decls = [(fmt % (x, self.N)) for x in signals]
		
		decls.append('signal %srCnt: unsigned(%d-1 downto 0);' % (id, self.stateBits))
		
		return '\n'.join(decls)

	def sigIn(self, id):
		return id + 'rP0'
	
	def sigOut(self, id):
		return '%srP%d' % (id, self.stateBits)
	
	def sigCount(self, id):
		return id + 'rCnt'
	

	def genBody(self, id):
		buf = ''
		bOrder = self.bitOrder
		for i in xrange(self.stateBits):
			option0 = id + 'rP%d' % i
			option1 = bitOrderToVHDL(bOrder, option0)
			#          0  1   2      3       4
			params = [id, i, i+1, option0, option1]
			buf += \
'''{0:s}rP{2:d} <= {4:s} when {0:s}rCnt({1:d})='1' else {3:s};
'''.format(*params)
			
			bOrder = bitOrderNTimes(bOrder, 2)
		return buf
	
	def delay(self):
		return 0

class FFTBase:
	def __init__(self, N, entity, scale, delay1):
		self.N = N
		self.isBase = True
		self.entity = entity
		self.scale = scale
		self.delay1 = delay1
		self.dataBits = 'dataBits'
		self.imports = [entity]
		self.iBitOrder = range(myLog2(self.N))
		self.oBitOrder = range(myLog2(self.N))
	
	def setInputBitOrder(self, bitOrder):
		assert len(bitOrder) == myLog2(self.N)
		self.iBitOrder = bitOrder
	
	def setOutputBitOrder(self, bitOrder):
		assert len(bitOrder) == myLog2(self.N)
		self.oBitOrder = bitOrder
	
	def setOptions(self, rnd, largeMultiplier):
		pass
	
	def setOptionsRecursive(self, rnd, largeMultiplier):
		pass

	def configurationStr(self):
		clsName = self.__class__.__name__
		res = "%s(%d, '%s', '%s', %d)" % (clsName, self.N, self.entity, self.scale, self.delay1)
		return res
	
	def descriptionStr(self):
		return "%d: base, '%s', scale='%s', delay=%d" % (self.N, self.entity, self.scale, self.delay1)
	
	# returns the mapping from temporal order to natural order; 
	# inputBitOrder()[0] is the source address of bit 0 in the output of the mapping.
	# e.g. bitOrder of [1,2,3,0] will transform 0b0001 to 0b1000
	def inputBitOrder(self):
		return self.iBitOrder

	# see inputBitOrder
	def outputBitOrder(self):
		return self.oBitOrder
	
	def sigIn(self, id):
		return id + 'din'
	def sigOut(self, id):
		return id + 'dout'
	def sigPhase(self, id):
		return id + 'phase'

	def getImports(self):
		return self.imports

	def genConstants(self, id):
		constantsArr = ['N', self.N,
					'order', myLog2(self.N),
					'delay', self.delay()]
		constants = ''
		for i in xrange(0, len(constantsArr), 2):
			name = constantsArr[i]
			val = str(constantsArr[i+1])
			constants += 'constant %s%s: integer := %s;\n' % (id, name,val)
		return constants

	def genDeclarations(self, id):
		return '''
signal {0:s}din, {0:s}dout: complex;
signal {0:s}phase: unsigned({1:d}-1 downto 0);'''.format(id, myLog2(self.N))

	def genBody(self, id):
		template = '''%sinst: entity %s
	generic map(dataBits=>%s, scale=>%s)
	port map(clk=>clk, din=>%sdin, phase=>%sphase, dout=>%sdout);'''
		return template % (id, self.entity,
					self.dataBits, self.scale,
					id, id, id);

	def delay(self):
		return self.delay1

class FFTConfiguration:
	def __init__(self, N, sub1, sub2, twiddleBits='twBits', rnd=True, largeMultiplier=False):
		assert N == (sub1.N*sub2.N)
		self.N = N
		self.isBase = False
		self.sub1 = sub1
		self.sub2 = sub2
		self.twiddleBits = twiddleBits
		self.reorderAdditiveDelay = 0
		self.setOptions(rnd, largeMultiplier)
		
		if N > 32:
			self.simpleTwiddleRom = False
			self.twiddleDelay = 7
			self.imports = ['twiddleRom%d' % N]
		else:
			self.simpleTwiddleRom = True
			self.twiddleDelay = 2
			self.imports = ['twiddleGenerator%d' % N]
		
		if not bitOrderIsNatural(sub2.inputBitOrder()):
			self.sub2Transposer = True
			self.reorderPerm = BitPermutation(sub2.inputBitOrder())
			self.reorderDelay = sub2.N + self.reorderAdditiveDelay
		else:
			self.sub2Transposer = False
	
	def setOptions(self, rnd, largeMultiplier):
		self.rnd = rnd
		self.largeMultiplier = largeMultiplier
		self.multDelay = 6
		
		if largeMultiplier:
			self.multDelay = 9
			#if rnd:
			#	self.multDelay = 9
			#else:
			#	self.multDelay = 8
	
	def setOptionsRecursive(self, rnd, largeMultiplier):
		self.setOptions(rnd, largeMultiplier)
		self.sub1.setOptionsRecursive(rnd, largeMultiplier)
		self.sub2.setOptionsRecursive(rnd, largeMultiplier)
	
	def configurationStr(self):
		clsName = self.__class__.__name__
		
		res = '%s(%d, \n' % (clsName, self.N)
		res += addIndent(self.sub1.configurationStr()) + ',\n'
		res += addIndent(self.sub2.configurationStr()) + ',\n'
		res += 'twiddleBits=%s)' % serializeSymbol(self.twiddleBits)
		return res
	
	def descriptionStr(self):
		res = '%d: twiddleBits=%s, delay=%d\n' % (self.N, str(self.twiddleBits), self.delay())
		res += addIndent(self.sub1.descriptionStr()) + '\n'
		res += addIndent(self.sub2.descriptionStr())
		return res
	
	def delay(self):
		d = self.sub1.delay() + self.N + self.multDelay + self.sub2.delay()
		if self.sub2Transposer:
			d += self.reorderDelay
		return d
	
	def inputBitOrder(self):
		O1 = myLog2(self.sub1.N)
		O2 = myLog2(self.sub2.N)
		
		# sub2 must accept data in natural order
		tmp = range(O1,O1+O2)
		tmp += self.sub1.inputBitOrder()
		return tmp

	def outputBitOrder(self):
		O1 = myLog2(self.sub1.N)
		O2 = myLog2(self.sub2.N)
		
		tmp = [x+O2 for x in self.sub1.outputBitOrder()]
		tmp += self.sub2.outputBitOrder()
		return tmp
	
	def sigIn(self, id):
		return id + 'din'
	def sigOut(self, id):
		return id + 'dout'
	def sigPhase(self, id):
		return id + 'phase'
	
	def getImports(self):
		ret = self.imports
		ret.extend(self.sub1.getImports())
		ret.extend(self.sub2.getImports())
		return ret
	
	def genConstants(self, id):
		constantsArr = ['N', self.N,
					'twiddleBits', self.twiddleBits,
					'twiddleDelay', self.twiddleDelay,
					'order', myLog2(self.N),
					'delay', self.delay()]
		constants = ''
		for i in xrange(0, len(constantsArr), 2):
			name = constantsArr[i]
			val = str(constantsArr[i+1])
			constants += 'constant %s%s: integer := %s;\n' % (id, name,val)
		
		if self.sub2Transposer:
			constants += self.reorderPerm.genConstants(id)
		
		return constants
	
	def genDeclarations(self, id, sub1, sub2, includePorts=True):
		sub1Order = myLog2(self.sub1.N)
		sub2Order = myLog2(self.sub2.N)
		signals = ''
		if includePorts:
			signals = '''
signal {0:s}din, {0:s}dout: complex;
signal {0:s}phase: unsigned({0:s}order-1 downto 0);
'''

		signals += '''
signal {0:s}rbIn: complex;
signal {0:s}bitPermIn,{0:s}bitPermOut: unsigned({1:d}-1 downto 0);

-- twiddle generator
signal {0:s}twAddr: unsigned({0:s}order-1 downto 0);
signal {0:s}twData: complex;

signal {0:s}romAddr: unsigned({0:s}order-4 downto 0);
signal {0:s}romData: std_logic_vector({0:s}twiddleBits*2-3 downto 0);
'''
		signals = signals.format(id, sub1Order, sub2Order)
		
		if self.sub2Transposer:
			signals += self.reorderPerm.genDeclarations(id)
			signals += '''
signal {0:s}rbInPhase: unsigned({2:d}-1 downto 0);
'''.format(id, sub1Order, sub2Order)
		
		return signals
		
	def genBody(self, id, subId1, subId2):
		bOrder1 = bitOrderToVHDL(self.sub1.outputBitOrder(), id + 'bitPermIn')
		
		sub1order = myLog2(self.sub1.N)
		sub2order = myLog2(self.sub2.N)
		sub1delay = self.sub1.delay()
		sub2delay = self.sub1.delay()
		
		sub2in = self.sub2.sigIn(subId2)
		sub2phase = self.sub2.sigPhase(subId2)
		
		if self.sub2Transposer:
			sub2in = id + 'rbIn'
			sub2phase = id + 'rbInPhase'
			sub2delay += self.reorderDelay
		
		#         0     1       2       3       4             5       6     
		params = [id, subId1, subId2, sub2in, sub2delay, sub2phase, bOrder1,
		#              7          8              9                    10
					self.N, self.multDelay, boolStr(self.rnd), boolStr(self.largeMultiplier),
		#              11         12         13         14
					sub1order, sub2order, sub1delay, sub2delay
					]
		body = '''
{0:s}core: entity fft3step_bram_generic3
	generic map(
		dataBits=>dataBits,
		twiddleBits=>{0:s}twiddleBits,
		subOrder1=>{11:d},
		subOrder2=>{12:d},
		twiddleDelay=>{0:s}twiddleDelay,
		multDelay=>{8:d},
		subDelay1=>{13:d},
		subDelay2=>{4:d},
		round=>{9:s},
		customSubOrder=>true,
		largeMultiplier=>{10:s})
	port map(
		clk=>clk, phase=>{0:s}phase, phaseOut=>open,
		subOut1=>{1:s}dout,
		subIn2=>{3:s},
		subPhase2=>{5:s},
		twAddr=>{0:s}twAddr, twData=>{0:s}twData,
		bitPermIn=>{0:s}bitPermIn, bitPermOut=>{0:s}bitPermOut);
	
{1:s}din <= {0:s}din;
{0:s}dout <= {2:s}dout;
{1:s}phase <= {0:s}phase({11:d}-1 downto 0);
{0:s}bitPermOut <= {6:s};
'''
		
		if self.simpleTwiddleRom:
			body += '''
{0:s}tw: entity twiddleGenerator{7:d} port map(clk, {0:s}twAddr, {0:s}twData);
'''
		else:
			body += '''
{0:s}tw: entity twiddleGenerator generic map({0:s}twiddleBits, {0:s}order)
	port map(clk, {0:s}twAddr, {0:s}twData, {0:s}romAddr, {0:s}romData);
{0:s}rom: entity twiddleRom{7:d} port map(clk, {0:s}romAddr,{0:s}romData);
'''
		
		body = body.format(*params)
		if self.sub2Transposer:
			params = [id, myLog2(self.sub2.N),
						self.reorderPerm.sigIn(id),
						self.reorderPerm.sigCount(id),
						self.reorderPerm.sigOut(id),
						subId2,
						self.reorderAdditiveDelay,
						self.reorderPerm.repLen]
			body += self.reorderPerm.genBody(id)
			body += '''
	
{0:s}rb: entity reorderBuffer
	generic map(N=>{1:d}, dataBits=>dataBits, repPeriod=>{7:d}, bitPermDelay=>0, dataPathDelay=>{6:d})
	port map(clk, din=>{0:s}rbIn, phase=>{0:s}rbInPhase, dout=>{5:s}din,
		bitPermIn=>{2:s}, bitPermCount=>{3:s}, bitPermOut=>{4:s});
	
{5:s}phase <= {0:s}rbInPhase-{6:d};
	
'''.format(*params)
		return body
	
	def _genSubInst(self, instanceName, entityName, obj):
		if isinstance(obj, FFTBase):
			return obj.genBody(instanceName)
		
		line1 = '{0:s}: entity {1:s} generic map(dataBits=>dataBits, twBits=>twBits)'.format(instanceName, entityName)
		line2 = '	port map(clk=>clk, din=>{0:s}din, phase=>{0:s}phase, dout=>{0:s}dout);'.format(instanceName)
		return line1 + '\n' + line2
	
	def genEntity(self, entityName, sub1Name, sub2Name):
		code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
'''
		imports = self.imports
		imports.extend([sub1Name, sub2Name])
		importsSet = set()
		for imp in imports:
			if not imp in importsSet:
				importsSet.add(imp)
				code += 'use work.%s;\n' % imp
		
		params = [bitOrderDescription(self.inputBitOrder()),
				bitOrderDescription(self.outputBitOrder()),
				self.delay(),
				entityName,
				myLog2(self.N),
				myLog2(self.sub1.N),
				myLog2(self.sub2.N)]
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
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned({5:d}-1 downto 0);
	signal sub2phase: unsigned({6:d}-1 downto 0);
'''.format(*params)
		
		code += indent(self.genConstants(''), 1)
		code += '\n\n\t--=======================================\n\n'
		code += indent(self.genDeclarations('', 'sub1', 'sub2', False), 1)
		code += '''
begin
'''
		code += indent(self.genBody('', 'sub1', 'sub2'), 1)
		code += indent(self._genSubInst('sub1', sub1Name, self.sub1), 1)
		code += indent(self._genSubInst('sub2', sub2Name, self.sub2), 1)
		code += '''
end ar;
'''
		return code

def indent(s, level):
	sp = '\t' * level
	ret = []
	for line in s.split('\n'):
		if len(line) == 0: continue
		ret.append(sp + line)
	ret.append('')
	return '\n'.join(ret)

def genDeclarations(fft, id, level, fnName='genDeclarations'):
	params = [id + '_']
	subId1 = id + 'A'
	subId2 = id + 'B'
	if id == 'top':
		subId1 = 'A'
		subId2 = 'B'
	
	if (fnName == 'genDeclarations' or fnName == 'genBody') \
			and isinstance(fft, FFTConfiguration):
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
use work.fft3step_bram_generic3;
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
	if not isinstance(fft, FFTConfiguration):
		return
	_collectInstances(instanceMap, instanceList, fft.sub1)
	_collectInstances(instanceMap, instanceList, fft.sub2)
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
		sub1Name = ''
		sub2Name = ''
		if isinstance(inst.sub1, FFTConfiguration):
			sub1Name = inst.sub1._name
		else:
			sub1Name = inst.sub1.entity
		
		if isinstance(inst.sub2, FFTConfiguration):
			sub2Name = inst.sub2._name
		else:
			sub2Name = inst.sub2.entity
		
		code.append(inst.genEntity(inst._name, sub1Name, sub2Name))
	
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
	reorderDelay = fft.N * rows
	delay = reorderDelay*2 + fft.delay()
	
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
'''.format(*params)

	#          0         1      2         3            4
	params = [fftName, rows, colBits, reorderDelay, fft.delay()]
	code += '''
begin
	ireorder: entity {0:s}_ireorderer{1:d} generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>phase, din=>din, dout=>core_din);
	
	core_phase <= phase - {3:d} + 1 when rising_edge(clk);
	
	core: entity {0:s} generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, phase=>core_phase({2:d}-1 downto 0), din=>core_din, dout=>core_dout);
	
	oreorderer_phase <= core_phase - {4:d} + 1 when rising_edge(clk);
	
	oreorderer: entity {0:s}_oreorderer{1:d} generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>oreorderer_phase, din=>core_dout, dout=>dout);
end ar;
'''.format(*params)
	return code



#fft2_scale_none = FFTBase(2, 'fft2_serial2', 'SCALE_NONE', 3)
#fft2_scale_div_n = FFTBase(2, 'fft2_serial2', 'SCALE_DIV_N', 3)

fft2_scale_none = FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6)
fft2_scale_div_n = FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6)


#fft4_scale_none = FFTConfiguration(4, fft2_scale_none, fft2_scale_none);
#fft4_scale_div_sqrt_n = FFTConfiguration(4, fft2_scale_none, fft2_scale_div_n);
#fft4_scale_div_n = FFTConfiguration(4, fft2_scale_div_n, fft2_scale_div_n);


fft4_delay = 10
#fft4_large_scale_none = FFTBase(4, 'fft4_serial3', 'SCALE_NONE', fft4_delay)
fft4_large_scale_div_sqrt_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N', fft4_delay)
#fft4_large_scale_div_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N', fft4_delay)


#fft4_delay = 12
#fft4_scale_none = FFTBase(4, 'fft4_serial4', 'SCALE_NONE', fft4_delay)
#fft4_scale_div_n = FFTBase(4, 'fft4_serial4', 'SCALE_DIV_N', fft4_delay)



fft4_delay = 11
fft4_scale_none = FFTBase(4, 'fft4_serial5_natural', 'SCALE_NONE', fft4_delay)
fft4_scale_div_sqrt_n = FFTBase(4, 'fft4_serial5_natural', 'SCALE_DIV_SQRT_N', fft4_delay)
fft4_scale_div_n = FFTBase(4, 'fft4_serial5_natural', 'SCALE_DIV_N', fft4_delay)
fft4_scale_none.setOutputBitOrder([1,0])
fft4_scale_div_sqrt_n.setOutputBitOrder([1,0])
fft4_scale_div_n.setOutputBitOrder([1,0])


fft16 = \
	FFTConfiguration(16, 
		fft4_scale_none,
		fft4_scale_div_n);

fft16_scale_none = FFTConfiguration(16,  fft4_scale_none, fft4_scale_none);
fft16_scale_div_n = FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n);

# scales by 1/4. 32 is not a perfect square so 1/sqrt(n) is not possible
fft32 = \
	FFTConfiguration(32,
		FFTConfiguration(8, 
			fft4_scale_none,
			fft2_scale_none),
		fft4_scale_div_n);

fft64 = \
	FFTConfiguration(64,
		FFTConfiguration(16, 
			fft4_scale_none,
			fft4_large_scale_div_sqrt_n),
		fft4_scale_div_n);


fft64_scale_none = FFTConfiguration(64, fft16_scale_none, fft4_scale_none);
fft64_scale_div_n = FFTConfiguration(64, fft16_scale_div_n, fft4_scale_div_n);




fft256 = \
	FFTConfiguration(256,
		FFTConfiguration(16, 
			fft4_scale_none,
			fft4_scale_none),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));
fft256.setOptionsRecursive(True, True)


fft1024 = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_large_scale_div_sqrt_n),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));

fft1024_wide = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_scale_div_sqrt_n),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));

fft1024_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)

fft1024_2 = \
	FFTConfiguration(1024,
		FFTConfiguration(256,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			FFTConfiguration(16, 
				fft4_large_scale_div_sqrt_n,
				fft4_scale_div_n)),
		fft4_scale_div_n);




fft4096 = \
	FFTConfiguration(4096,
		FFTConfiguration(64,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			fft4_scale_none),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192 = \
	FFTConfiguration(8192,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_div_n)),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192_wide = \
	FFTConfiguration(8192,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_div_n)),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));
fft8192_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)


fft16k = \
	FFTConfiguration(16*1024,
		FFTConfiguration(4096,
			FFTConfiguration(64,
				FFTConfiguration(16,
					fft4_scale_none,
					fft4_scale_none),
				fft4_scale_none),
			FFTConfiguration(64, 
				FFTConfiguration(16,
					fft4_large_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n)),
		fft4_scale_div_n);

fft16k_2 = \
	FFTConfiguration(16*1024,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_none)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k = \
	FFTConfiguration(32*1024,
		FFTConfiguration(256,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(16,  fft4_scale_none, fft4_large_scale_div_sqrt_n)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide = \
	FFTConfiguration(32*1024,
		FFTConfiguration(256,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(16,  fft4_scale_none, fft4_large_scale_div_sqrt_n)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)

# N = 14
# perm = range(N)
# for x in range(500):
	# random.shuffle(perm)
	# repLen = bitOrderConstraintLength(perm)
	# if repLen > 84:
		# print str(perm) + ': ' + str(repLen)

# for N in range(3, 50):
	# perm = range(N)
	# maxRep = 0
	# for x in range(50000):
		# random.shuffle(perm)
		# repLen = bitOrderConstraintLength(perm)
		# if repLen > maxRep:
			# maxRep = repLen
	# print 'N = %d: %d' % (N, maxRep)

# exit(0)

#print fft256.inputBitOrder()
#print fft256.outputBitOrder()

#print fft1024.inputBitOrder()
#print BitPermutation(fft1024.inputBitOrder()).genBody('aaa_', 'sigIn', 'sigCount', 'sigOut')

#print fft4096.reorderPerm.genBody('A_', 'sigIn', 'sigCount', 'sigOut')

#print fft256_4.inputBitOrder()

#print genVHDL(fft16k)

if len(sys.argv) < 3:
	print 'usage: %s [fft|reorderer] INSTANCE_TO_GENERATE' % sys.argv[0]
	print 'see source code of this program for a list of instances or add your own instance'
	exit(1)

outpType = sys.argv[1]
instanceName = sys.argv[2]
instance = globals()[instanceName]

if outpType == 'fft':
	vhdlCode = '-- instance name: ' + instanceName + '\n\n'
	vhdlCode += '-- layout:\n'
	vhdlCode += commentOut(instance.descriptionStr())
	vhdlCode += '\n\n'

	print vhdlCode
	#print genFFT(instance, entityName=instanceName)
	#print instance.genEntity(instanceName, 'aaa', 'bbb')
	print genFFTSeparated(instance, instanceName)

	print '\n-- instantiation (python):\n'
	print commentOut(instance.configurationStr())

if outpType == 'reorderer':
	# generate reorderers for 1, 2, and 4 rows of data
	for rows in [1,2,4]:
		print genReorderer(instance, False, rows, instanceName + '_ireorderer' + str(rows))
		print genReorderer(instance, True, rows, instanceName + '_oreorderer' + str(rows))

if outpType == 'wrapper':
	for rows in [1,2,4]:
		print genReordererWrapper(instance, rows, instanceName + '_wrapper' + str(rows), instanceName)

