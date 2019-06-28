#!/usr/bin/python
from math import *
import sys,random

# imports from local directory
from gen_fft_utils import *
from gen_fft_generators import *
from gen_fft_layouts import *


# N = 14
# perm = range(N)
# for x in range(500):
	# random.shuffle(perm)
	# repLen = bitOrderConstraintLength(perm)
	# if repLen > 84:
		# print str(perm) + ': ' + str(repLen)

# for N in range(3, 50):
	# perm = range(N)
	# maxRep = 0
	# for x in range(50000):
		# random.shuffle(perm)
		# repLen = bitOrderConstraintLength(perm)
		# if repLen > maxRep:
			# maxRep = repLen
	# print 'N = %d: %d' % (N, maxRep)

# exit(0)

#print fft256.inputBitOrder()
#print fft256.outputBitOrder()

#print fft1024.inputBitOrder()
#print BitPermutation(fft1024.inputBitOrder()).genBody('aaa_', 'sigIn', 'sigCount', 'sigOut')

#print fft4096.reorderPerm.genBody('A_', 'sigIn', 'sigCount', 'sigOut')

#print fft256_4.inputBitOrder()

#print genVHDL(fft16k)

if len(sys.argv) < 3:
	print 'usage: %s [fft|reorderer|wrapper] INSTANCE_TO_GENERATE' % sys.argv[0]
	print 'see gen_fft_layouts.py for a list of instances or to add your own instance'
	exit(1)

outpType = sys.argv[1]
instanceName = sys.argv[2]
instance = globals()[instanceName]

if outpType == 'fft':
	vhdlCode = '-- instance name: ' + instanceName + '\n\n'
	vhdlCode += '-- layout:\n'
	vhdlCode += commentOut(instance.descriptionStr())
	vhdlCode += '\n\n'

	print vhdlCode
	#print genFFT(instance, entityName=instanceName)
	#print instance.genEntity(instanceName, 'aaa', 'bbb')
	print genFFTSeparated(instance, instanceName)

	print '\n-- instantiation (python):\n'
	print commentOut(instance.configurationStr())

if outpType == 'reorderer':
	# generate reorderers for 1, 2, and 4 rows of data
	for rows in [1,2,4]:
		print genReorderer(instance, False, rows, instanceName + '_ireorderer' + str(rows))
		print genReorderer(instance, True, rows, instanceName + '_oreorderer' + str(rows))

if outpType == 'wrapper':
	for rows in [1,2,4]:
		print genReordererWrapper(instance, rows, instanceName + '_wrapper' + str(rows), instanceName)

