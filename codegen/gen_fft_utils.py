
# This file contains utility functions for the code generator.

from math import *
import sys

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

	print >> sys.stderr, 'bad bit order: ' + str(bitOrder)
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

def indent(s, level):
	s = s.strip()
	sp = '\t' * level
	ret = []
	for line in s.split('\n'):
		if len(line.strip()) == 0:
			ret.append('')
			continue
		ret.append(sp + line)
	ret.append('')
	return '\n'.join(ret)


