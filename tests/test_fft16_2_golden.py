#!/usr/bin/python
import numpy
from numpy.fft import ifft
from math import *
import sys

N = 16
scale = 4

def printResult(arr):
	for x in arr:
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*scale)), int(round(x.imag*scale))

arr = []
for i in xrange(N*2):
	re = (i*i*123) % 1969;
	im = (i*(i+199)*123) % 1969;
	arr.append(re + 1j*im);

res = [x for x in ifft(arr[:N])]
res += [x for x in ifft(arr[N:])]
	
if len(sys.argv)>1 and sys.argv[1] == 'verify':
	# convert to list, so += concatenates
	lines = sys.stdin.readlines()
	maxDiff = 0.
	rmsDiff = 0.
	i = 0
	for line in lines:
		tmp = line.split(':')
		ind = int(tmp[0])
		vals = tmp[1].strip().split(' ')
		val = int(vals[0]) + 1j*int(vals[1])
		correctVal = res[ind]*scale
		diff = abs(val-correctVal)
		if diff > maxDiff: maxDiff = diff
		rmsDiff += diff**2
		if diff >= 8:
			print 'line %d index %d should be %s, is %s' % (i, ind, str(correctVal), str(val))
		i += 1
	rmsDiff = sqrt(rmsDiff/len(lines))
	print 'maxDiff = %.2f' % maxDiff
	print 'rmsDiff = %.2f' % rmsDiff
	
else:
	printResult(res)


