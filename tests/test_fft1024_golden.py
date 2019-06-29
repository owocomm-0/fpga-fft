#!/usr/bin/python
import numpy
from numpy.fft import ifft,fft
from math import *
import sys, argparse

N = 1024

parser = argparse.ArgumentParser()
parser.add_argument('verb', type=str, metavar='print|verify')
parser.add_argument('--inverse', dest='inverse', action='store_const',
                    const=True, default=False,
                    help='whether to use inverse FFT')

args = parser.parse_args()

if args.inverse:
	scale = 32
	fftfunc = ifft
else:
	scale = 1./32
	fftfunc = fft

def printResult(arr):
	assert len(arr)==N
	res = arr
	for i in xrange(N):
		x = res[i]
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*scale)), int(round(x.imag*scale))

arr = []
for i in xrange(N*2):
	re = (i*i) % 1969;
	im = (i*(i+13)) % 1969;
	arr.append(re + 1j*im);

if args.verb == 'verify':
	# convert to list, so += concatenates
	res = [x for x in fftfunc(arr[:N])]
	res += [x for x in fftfunc(arr[N:])]
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
	printResult(fftfunc(arr[:N]))
	
	#tmp = 0
	#for val in arr[:256]:
	#	tmp += val
	#print tmp


