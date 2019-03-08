#!/usr/bin/python
from numpy.fft import ifft

def reverse_bits(i, bits):
	b = '{:0{width}b}'.format(i, width=bits)
	return int(b[::-1], 2)

def printResult(arr):
	assert len(arr)==16
	for i in xrange(16):
		row = i/4
		col = i%4
		i2 = col*4 + reverse_bits(row,2)
		x = arr[i2]
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*4)), int(round(x.imag*4))

def printResult4(arr):
	for x in arr:
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(x.real*2), int(x.imag*2)


#printResult(ifft([0,64,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]))

arr = []
for i in xrange(16):
	re = i*6;
	im = i*7;
	arr.append(re + 1j*im);

printResult(ifft(arr))

#for i in [0,2,1,3]:
#	printResult4(ifft([arr[x+i] for x in [0,4,8,12]]))
#	print
'''
for y in xrange(16):
	for x in xrange(16):
		X = reverse_bits(x,4)
		Y = reverse_bits(y,4)
		val0 = x*y
		val1 = X*Y
		val2 = reverse_bits(val0, 7)
		val3 = reverse_bits(val0, 8)
		val4 = reverse_bits(val0, 9)
		
		# if (val0 < 2**7) and val1 == val2:
			# print 1,
		# elif (val0 < 2**8) and val1 == val3:
			# print 2,
		# elif (val0 < 2**9) and val1 == val4:
			# print 3,
		# else:
			# print 0,
		print '%5d' % val1,
	print

'''
