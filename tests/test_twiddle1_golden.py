#!/usr/bin/python
from math import *

N = 16;
width = 12;

size = N/8;
romDepthOrder = int(ceil(log(size)/log(2.)));
romWidth = width - 1;
scale = (2**romWidth)-1;

fmt = '{0:0' + str(romWidth) + 'b}'

for i in xrange(N):
	x = float(i)/N * (2*pi)
	re = cos(x)
	im = sin(x)
	
	re1 = int(round(re*scale));
	im1 = int(round(im*scale));
	
	print re1, im1
