#!/usr/bin/python
from numpy.fft import ifft

def printResult(arr):
	assert len(arr)==16
	for i in xrange(16):
		i2 = (i%4)*4 + (i/4)
		x = arr[i2]
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*4)), int(round(x.imag*4))

#printResult(ifft([0,64,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]))

arr = []
for i in xrange(16):
	re = i*6;
	im = i*7;
	arr.append(re + 1j*im);

printResult(ifft(arr))
