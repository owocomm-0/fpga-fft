#!/bin/bash

for twBits in 10 12 14 17 24; do
	D="generated/twiddle${twBits}b"
	mkdir -p "$D"
	for twSize in 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768; do
		if (( twSize > 32 )); then
			./gen_twiddle_rom.py $twSize $twBits > "$D/twiddle_rom_$twSize.vhd"
		else
			./gen_twiddle_rom_simple.py $twSize $twBits > "$D/twiddle_generator_$twSize.vhd"
		fi;
	done;
done;
