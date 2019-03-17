#!/usr/bin/python
from math import *
import sys

def myLog2(N):
	tmp = log(N)/log(2.)
	tmp = int(tmp)
	assert 2**tmp == N
	return tmp

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
		self.stateBits = int(ceil(log(self.N)/log(2)))
	
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
	def __init__(self, N, entity, scale, delay1=11):
		self.N = N
		self.isBase = True
		self.entity = entity
		self.scale = scale
		self.delay1 = delay1
		self.dataBits = 'dataBits'
		self.imports = [entity]

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
		O = myLog2(self.N)
		return range(O)

	# see inputBitOrder
	def outputBitOrder(self):
		O = myLog2(self.N)
		return range(O)
	
	def sigIn(self, id):
		return id + 'in'
	def sigOut(self, id):
		return id + 'out'
	def sigPhase(self, id):
		return id + 'phase'

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
signal {0:s}in, {0:s}out: complex;
signal {0:s}phase: unsigned({1:d}-1 downto 0);'''.format(id, myLog2(self.N))

	def genBody(self, id):
		template = '''%sinst: entity %s
	generic map(dataBits=>%s, scale=>%s)
	port map(clk=>clk, din=>%sin, phase=>%sphase, dout=>%sout);'''
		return template % (id, self.entity,
					self.dataBits, self.scale,
					id, id, id);

	def delay(self):
		return self.delay1

class FFTConfiguration:
	def __init__(self, N, sub1, sub2, twiddleBits=12):
		assert N == (sub1.N*sub2.N)
		self.N = N
		self.isBase = False
		self.sub1 = sub1
		self.sub2 = sub2
		self.twiddleBits = twiddleBits
		self.multDelay = 6
		self.reorderAdditiveDelay = 0
		
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
	
	def configurationStr(self):
		clsName = self.__class__.__name__
		
		res = '%s(%d, \n' % (clsName, self.N)
		res += addIndent(self.sub1.configurationStr()) + ',\n'
		res += addIndent(self.sub2.configurationStr()) + ',\n'
		res += 'twiddleBits=%d)' % self.twiddleBits
		return res
	
	def descriptionStr(self):
		res = '%d: twiddleBits=%d, delay=%d\n' % (self.N, self.twiddleBits, self.delay())
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
		return id + 'in'
	def sigOut(self, id):
		return id + 'out'
	def sigPhase(self, id):
		return id + 'phase'
	
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
	
	def genDeclarations(self, id, sub1, sub2):
		signals = '''
signal {0:s}in, {0:s}out, {0:s}rbIn: complex;
signal {0:s}phase: unsigned({0:s}order-1 downto 0);
signal {0:s}bitPermIn,{0:s}bitPermOut: unsigned({1:s}order-1 downto 0);

-- twiddle generator
signal {0:s}twAddr: unsigned({0:s}order-1 downto 0);
signal {0:s}twData: complex;

signal {0:s}romAddr: unsigned({0:s}order-4 downto 0);
signal {0:s}romData: std_logic_vector({0:s}twiddleBits*2-3 downto 0);
'''
		signals = signals.format(id,sub1,sub2)
		
		if self.sub2Transposer:
			signals += self.reorderPerm.genDeclarations(id)
			signals += '''
signal {0:s}rbInPhase: unsigned({2:s}order-1 downto 0);
'''.format(id,sub1,sub2)
		
		return signals
		
	def genBody(self, id, subId1, subId2):
		bOrder1 = bitOrderToVHDL(self.sub1.outputBitOrder(), id + 'bitPermIn')
		
		sub2in = self.sub2.sigIn(subId2)
		sub2phase = self.sub2.sigPhase(subId2)
		sub2delay = self.sub2.delay()
		
		if self.sub2Transposer:
			sub2in = id + 'rbIn'
			sub2phase = id + 'rbInPhase'
			sub2delay += self.reorderDelay
		
		#         0     1       2       3       4             5       6        7
		params = [id, subId1, subId2, sub2in, sub2delay, sub2phase, bOrder1, self.N]
		body = '''
{0:s}core: entity fft3step_bram_generic3
	generic map(
		dataBits=>dataBits,
		twiddleBits=>{0:s}twiddleBits,
		subOrder1=>{1:s}order,
		subOrder2=>{2:s}order,
		twiddleDelay=>{0:s}twiddleDelay,
		subDelay1=>{1:s}delay,
		subDelay2=>{4:d},
		customSubOrder=>true)
	port map(
		clk=>clk, phase=>{0:s}phase, phaseOut=>open,
		subOut1=>{1:s}out,
		subIn2=>{3:s},
		subPhase2=>{5:s},
		twAddr=>{0:s}twAddr, twData=>{0:s}twData,
		bitPermIn=>{0:s}bitPermIn, bitPermOut=>{0:s}bitPermOut);
	
{1:s}in <= {0:s}in;
{0:s}out <= {2:s}out;
{1:s}phase <= {0:s}phase({1:s}order-1 downto 0);
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
						self.reorderAdditiveDelay]
			body += self.reorderPerm.genBody(id)
			body += '''
	
{0:s}rb: entity reorderBuffer
	generic map(N=>{1:d}, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>{6:d})
	port map(clk, din=>{0:s}rbIn, phase=>{0:s}rbInPhase, dout=>{5:s}in,
		bitPermIn=>{2:s}, bitPermCount=>{3:s}, bitPermOut=>{4:s});
	
{5:s}phase <= {0:s}rbInPhase-{6:d};
	
'''.format(*params)
		return body

def indent(s, level):
	sp = '\t' * level
	ret = []
	for line in s.split('\n'):
		if len(line) == 0: continue
		ret.append(sp + line)
	
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

def genVHDL(fft):
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
			fft.N,
			myLog2(fft.N)]
	code += '''
-- data input bit order: {0:s}
-- data output bit order: {1:s}
-- phase should be 0,1,2,3,4,5,6,...
-- delay is {2:d}
entity fft{3:d}_generated is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned({4:d}-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft{3:d}_generated is
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


#fft2_scale_none = FFTBase(2, 'fft2_serial2', 'SCALE_NONE', 3)
#fft2_scale_div_n = FFTBase(2, 'fft2_serial2', 'SCALE_DIV_N', 3)

fft2_scale_none = FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6)
fft2_scale_div_n = FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6)


fft4_scale_none = FFTConfiguration(4, fft2_scale_none, fft2_scale_none);
fft4_scale_div_sqrt_n = FFTConfiguration(4, fft2_scale_none, fft2_scale_div_n);
fft4_scale_div_n = FFTConfiguration(4, fft2_scale_div_n, fft2_scale_div_n);


fft4_large_scale_none = FFTBase(4, 'fft4_serial3', 'SCALE_NONE', 11)
fft4_large_scale_div_sqrt_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N', 11)
fft4_large_scale_div_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N', 11)



fft16 = \
	FFTConfiguration(16, 
		FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
		FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'));

fft16_scale_none = FFTConfiguration(16,  fft4_large_scale_none, fft4_scale_none);
fft16_scale_div_n = FFTConfiguration(16,  fft4_scale_div_n, fft4_large_scale_div_n);

fft64 = \
	FFTConfiguration(64,
		FFTConfiguration(16, 
			FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N')),
		FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'));


fft64_scale_none = FFTConfiguration(64, fft16_scale_none, fft4_scale_none);
fft64_scale_div_n = FFTConfiguration(64, fft16_scale_div_n, fft4_scale_div_n);




fft256 = \
	FFTConfiguration(256,
		FFTConfiguration(16, 
			FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
			FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
		FFTConfiguration(16, 
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')));

fft256_2 = \
	FFTConfiguration(256,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')),
		FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'));

fft256_3 = \
	FFTConfiguration(256,
		FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
		FFTConfiguration(64,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
				FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')));


fft256_4 = \
	FFTConfiguration(256,
		FFTConfiguration(16, 
			fft4_scale_none,
			fft4_scale_none),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));



fft1024 = \
	FFTConfiguration(1024,
		FFTConfiguration(256,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N'),
				FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'))),
		FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'),
		16); # twiddleBits


fft1024_2 = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N')),
		FFTConfiguration(16, 
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')),
		16); # twiddleBits


fft1024_3 = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_large_scale_none),
			fft4_scale_div_sqrt_n),
		FFTConfiguration(16, 
			fft4_large_scale_div_n,
			fft4_scale_div_n),
		16); # twiddleBits

fft4096 = \
	FFTConfiguration(4096,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE'),
				FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
			FFTBase(4, 'fft4_serial3', 'SCALE_NONE')),
		FFTConfiguration(64,
			FFTConfiguration(16, 
				FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N'),
				FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')),
			FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N')),
		16); # twiddleBits


fft4096_2 = \
	FFTConfiguration(4096,
		fft64_scale_none,
		fft64_scale_div_n,
		16); # twiddleBits


fft4096_2 = \
	FFTConfiguration(4096,
		FFTConfiguration(64,
			FFTConfiguration(16,  fft4_scale_none, fft4_large_scale_none),
			fft4_scale_none),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_large_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n),
		16); # twiddleBits

fft8192 = \
	FFTConfiguration(8192,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_large_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_div_n)),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_large_scale_div_sqrt_n, fft4_scale_div_n),
			fft4_scale_div_n),
		16); # twiddleBits

fft16k = \
	FFTConfiguration(16*1024,
		FFTConfiguration(4096,
			FFTConfiguration(64,
				FFTConfiguration(16,
					fft4_scale_none,
					fft4_large_scale_none),
				fft4_scale_none),
			FFTConfiguration(64, 
				FFTConfiguration(16,
					fft4_large_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n),
			16), # twiddleBits
		fft4_scale_div_n,
		16);

#print fft256.inputBitOrder()
#print fft256.outputBitOrder()

#print fft1024.inputBitOrder()
#print BitPermutation(fft1024.inputBitOrder()).genBody('aaa_', 'sigIn', 'sigCount', 'sigOut')

#print fft4096.reorderPerm.genBody('A_', 'sigIn', 'sigCount', 'sigOut')

#print fft256_4.inputBitOrder()

#print genVHDL(fft16k)

if len(sys.argv) < 2:
	print 'usage: %s INSTANCE_TO_GENERATE' % sys.argv[0]
	print 'see source code of this program for a list of instances or add your own instance'
	exit(1)

instanceName = sys.argv[1]
instance = globals()[instanceName]

vhdlCode = '-- instance name: ' + instanceName + '\n\n'
vhdlCode += '-- layout:\n'
vhdlCode += commentOut(instance.descriptionStr())
vhdlCode += '\n\n'

print vhdlCode
print genVHDL(instance)

print '\n-- instantiation (python):\n'
print commentOut(instance.configurationStr())

