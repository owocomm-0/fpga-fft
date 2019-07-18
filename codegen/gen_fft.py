#!/usr/bin/python
from math import *
import os,sys,random

# imports from local directory
from gen_fft_utils import *
from gen_fft_generators import *
from gen_fft_layouts import *

def emitFile(filename, contents):
	if outDir == '-':
		print contents
	else:
		f = open(filename, 'wb')
		f.write(contents)
		f.close()

# accepts list of list [filename, contents]
def emitFiles(filesList):
	for filename, contents in filesList:
		emitFile(filename, contents)

def emitVHDL(filename, contents):
	emitFile(filename + '.vhd', contents)

if len(sys.argv) < 3:
	print 'usage: %s (fft|reorderer|wrapper|large) INSTANCE_TO_GENERATE OUTDIR' % sys.argv[0]
	print 'see gen_fft_layouts.py for a list of instances or to add your own instance'
	print 'if OUTDIR is -, output to stdout'
	exit(1)

outpType = sys.argv[1]
instanceName = sys.argv[2]
outDir = sys.argv[3]
instance = globals()[instanceName]

if outDir != '-':
	os.chdir(outDir)

if outpType == 'fft':
	header = '-- instance name: ' + instanceName + '\n\n'
	header += '-- layout:\n'
	header += commentOut(instance.descriptionStr())
	header += '\n\n'
	
	footer = '\n-- instantiation (python):\n'
	footer += commentOut(instance.configurationStr())

	files = genFFTSeparated(instance, instanceName)

	# top level entity is always the last file
	topFile = len(files) - 1
	files[topFile][1] = header + files[topFile][1] + footer

	emitFiles(files)

if outpType == 'reorderer':
	# generate reorderers for 1, 2, and 4 rows of data
	for rows in [1,2,4]:
		if bitOrderIsNatural(instance.inputBitOrder()) and rows == 1:
			print '-- no input reorder generated because input is already natural order'
		else:
			name = instanceName + '_ireorderer' + str(rows)
			emitVHDL(name, genReorderer(instance, False, rows, name))

		if bitOrderIsNatural(instance.outputBitOrder()) and rows == 1:
			print '-- no output reorder generated because output is already natural order'
		else:
			name = instanceName + '_oreorderer' + str(rows)
			emitVHDL(name, genReorderer(instance, True, rows, name))

if outpType == 'wrapper':
	for rows in [1,2,4]:
		name = instanceName + '_wrapper' + str(rows)
		emitVHDL(name, genReordererWrapper(instance, rows, name, instanceName))

if outpType == 'large':
	for rows in [2,4]:
		name = instanceName + '_large' + str(rows)
		emitVHDL(name, genLargeFFT(instance, rows, name, instanceName))
		emitVHDL(name + 'axi', genAXIWrapper(instance, rows, name + 'axi', name))

