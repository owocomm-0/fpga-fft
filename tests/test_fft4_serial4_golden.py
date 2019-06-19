#!/usr/bin/python
from numpy.fft import ifft

def printResult(arr):
	for x in arr:
		print int(x.real), int(x.imag)

printResult(ifft([0,1,2,3])*4)
printResult(ifft([1+2j, 2+5j, -4+8j, 34-2j])*4)
