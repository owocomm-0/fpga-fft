#!/usr/bin/python
import numpy
from numpy.fft import ifft
from math import *
import sys

def reorderResult(arr):
	assert len(arr)==64
	res = []
	for i in xrange(64):
		row = i/4
		col = i%4
		row = (row%4)*4 + row/4
		i2 = col*16 + row
		x = arr[i2]
		res.append(x)
	return res

def printResult(arr):
	assert len(arr)==64
	res = reorderResult(arr)
	for i in xrange(64):
		x = res[i]
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*8)), int(round(x.imag*8))

arr = []
for i in xrange(128):
	re = (i*i) % 1024;
	im = (i*(i+13)) % 1024;
	arr.append(re + 1j*im);

if len(sys.argv)>1 and sys.argv[1] == 'verify':
	# reorderResult returns list, so += concatenates
	res = reorderResult(ifft(arr[:64]))
	res += reorderResult(ifft(arr[64:]))
	lines = sys.stdin.readlines()
	maxDiff = 0.
	rmsDiff = 0.
	for line in lines:
		tmp = line.split(':')
		ind = int(tmp[0])
		vals = tmp[1].strip().split(' ')
		val = int(vals[0]) + 1j*int(vals[1])
		correctVal = res[ind]*8
		diff = abs(val-correctVal)
		if diff > maxDiff: maxDiff = diff
		rmsDiff += diff**2
		if diff >= 8:
			print 'index %d should be %s, is %s' % (ind, str(correctVal), str(val))
	rmsDiff = sqrt(rmsDiff/len(lines))
	print 'maxDiff = %.2f' % maxDiff
	print 'rmsDiff = %.2f' % rmsDiff
else:
	printResult(ifft(arr[:64]))
	
	#tmp = 0
	#for val in arr[:256]:
	#	tmp += val
	#print tmp


