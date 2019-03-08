#!/usr/bin/python
from numpy.fft import ifft

def printResult(arr):
	for x in arr:
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(x.real*2), int(x.imag*2)

printResult(ifft([2,2,4,4]))
printResult(ifft([1+2j, 2+5j, -4+8j, 34-2j]))
