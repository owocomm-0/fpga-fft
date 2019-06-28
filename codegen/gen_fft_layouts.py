
# This file contains layout definitions. Edit this file to add custom layouts.
# Do not add other logic or call functions in gen_fft_generators.py from this file.

from gen_fft_modules import *

#fft2_scale_none = FFTBase(2, 'fft2_serial2', 'SCALE_NONE', 3)
#fft2_scale_div_n = FFTBase(2, 'fft2_serial2', 'SCALE_DIV_N', 3)

fft2_scale_none = FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6)
fft2_scale_div_n = FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6)


#fft4_scale_none = FFTConfiguration(4, fft2_scale_none, fft2_scale_none);
#fft4_scale_div_sqrt_n = FFTConfiguration(4, fft2_scale_none, fft2_scale_div_n);
#fft4_scale_div_n = FFTConfiguration(4, fft2_scale_div_n, fft2_scale_div_n);


fft4_delay = 10
#fft4_large_scale_none = FFTBase(4, 'fft4_serial3', 'SCALE_NONE', fft4_delay)
fft4_large_scale_div_sqrt_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N', fft4_delay)
#fft4_large_scale_div_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N', fft4_delay)


#fft4_delay = 12
#fft4_scale_none = FFTBase(4, 'fft4_serial4', 'SCALE_NONE', fft4_delay)
#fft4_scale_div_n = FFTBase(4, 'fft4_serial4', 'SCALE_DIV_N', fft4_delay)



fft4_delay = 11
fft4_entity = 'fft4_serial7'
fft4_scale_none = FFTBase(4, fft4_entity, 'SCALE_NONE', fft4_delay)
fft4_scale_div_sqrt_n = FFTBase(4, fft4_entity, 'SCALE_DIV_SQRT_N', fft4_delay)
fft4_scale_div_n = FFTBase(4, fft4_entity, 'SCALE_DIV_N', fft4_delay)
fft4_scale_none.setOutputBitOrder([1,0])
fft4_scale_div_sqrt_n.setOutputBitOrder([1,0])
fft4_scale_div_n.setOutputBitOrder([1,0])


fft16 = \
	FFTConfiguration(16, 
		fft4_scale_none,
		fft4_scale_div_n);

fft16_scale_none = FFTConfiguration(16,  fft4_scale_none, fft4_scale_none);
fft16_scale_div_n = FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n);

# scales by 1/4. 32 is not a perfect square so 1/sqrt(n) is not possible
fft32 = \
	FFTConfiguration(32,
		FFTConfiguration(8, 
			fft4_scale_none,
			fft2_scale_none),
		fft4_scale_div_n);

fft64 = \
	FFTConfiguration(64,
		FFTConfiguration(16, 
			fft4_scale_none,
			fft4_large_scale_div_sqrt_n),
		fft4_scale_div_n);


fft64_scale_none = FFTConfiguration(64, fft16_scale_none, fft4_scale_none);
fft64_scale_div_n = FFTConfiguration(64, fft16_scale_div_n, fft4_scale_div_n);




fft256 = \
	FFTConfiguration(256,
		FFTConfiguration(16, 
			fft4_scale_none,
			fft4_scale_none),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));
fft256.setOptionsRecursive(True, True)


fft1024 = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_large_scale_div_sqrt_n),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));

fft1024_wide = \
	FFTConfiguration(1024,
		FFTConfiguration(64,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_scale_div_sqrt_n),
		FFTConfiguration(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));

fft1024_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)

fft1024_2 = \
	FFTConfiguration(1024,
		FFTConfiguration(256,
			FFTConfiguration(16, 
				fft4_scale_none,
				fft4_scale_none),
			FFTConfiguration(16, 
				fft4_large_scale_div_sqrt_n,
				fft4_scale_div_n)),
		fft4_scale_div_n);




fft4096 = \
	FFTConfiguration(4096,
		FFTConfiguration(64,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			fft4_scale_none),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192 = \
	FFTConfiguration(8192,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_div_n)),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192_wide = \
	FFTConfiguration(8192,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_div_n)),
		FFTConfiguration(64, 
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));
fft8192_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)


fft16k = \
	FFTConfiguration(16*1024,
		FFTConfiguration(4096,
			FFTConfiguration(64,
				FFTConfiguration(16,
					fft4_scale_none,
					fft4_scale_none),
				fft4_scale_none),
			FFTConfiguration(64, 
				FFTConfiguration(16,
					fft4_large_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n)),
		fft4_scale_div_n);

fft16k_2 = \
	FFTConfiguration(16*1024,
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(8,  fft4_scale_none, fft2_scale_none)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k = \
	FFTConfiguration(32*1024,
		FFTConfiguration(256,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_div_sqrt_n)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide = \
	FFTConfiguration(32*1024,
		FFTConfiguration(256,
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_none),
			FFTConfiguration(16,  fft4_scale_none, fft4_scale_div_sqrt_n)),
		FFTConfiguration(128,
			FFTConfiguration(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFTConfiguration(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide.setOptionsRecursive(rnd=True, largeMultiplier=True)


