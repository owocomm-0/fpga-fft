
# This file contains layout definitions. Edit this file to add custom layouts.
# Do not add other logic or call functions in gen_fft_generators.py from this file.

from gen_fft_modules import *


SCALE_NONE = 'SCALE_NONE'
SCALE_DIV_SQRT_N = 'SCALE_DIV_SQRT_N'
SCALE_DIV_N = 'SCALE_DIV_N'


def fft2_serial(scale, bitGrowth=0):
	delay = 6
	return FFTBase(2, 'fft2_serial',
					scale=scale,
					delay=delay,
					bitGrowth=bitGrowth)


def fft4_serial3(scale, bitGrowth=0):
	delay = 10
	iBitOrder = [0,1]
	oBitOrder = [1,0]
	return FFTBase(4, 'fft4_serial3',
					scale=scale,
					delay=delay,
					bitGrowth=bitGrowth,
					iBitOrder=iBitOrder,
					oBitOrder=oBitOrder)

def fft4_serial7(scale, bitGrowth=0):
	delay = 11
	iBitOrder = [0,1]
	oBitOrder = [1,0]
	return FFTBase(4, 'fft4_serial7',
					scale=scale,
					delay=delay,
					bitGrowth=bitGrowth,
					iBitOrder=iBitOrder,
					oBitOrder=oBitOrder)

def fft4_serial8(scale, bitGrowth=0):
	delay = 7
	iBitOrder = [1,0]
	oBitOrder = [1,0]
	return FFTBase(4, 'fft4_serial8',
					scale=scale,
					delay=delay,
					bitGrowth=bitGrowth,
					iBitOrder=iBitOrder,
					oBitOrder=oBitOrder)

def fft4_serial9(scale, bitGrowth=0):
	delay = 8
	iBitOrder = [1,0]
	oBitOrder = [1,0]
	return FFTBase(4, 'fft4_serial9',
					scale=scale,
					delay=delay,
					bitGrowth=bitGrowth,
					iBitOrder=iBitOrder,
					oBitOrder=oBitOrder)


fft4_default = fft4_serial8
fft4_scale_none = fft4_default(scale=SCALE_NONE)
fft4_scale_none_bg1 = fft4_default(scale=SCALE_NONE, bitGrowth=1)
fft4_scale_none_bg2 = fft4_default(scale=SCALE_NONE, bitGrowth=2)
fft4_scale_div_sqrt_n = fft4_default(scale=SCALE_DIV_SQRT_N)
fft4_scale_div_sqrt_n_bg1 = fft4_default(scale=SCALE_DIV_SQRT_N, bitGrowth=1)
fft4_scale_div_n = fft4_default(scale=SCALE_DIV_N)

fft4_default_small = fft4_serial9
fft4_small_scale_none = fft4_default_small(scale=SCALE_NONE)
fft4_small_scale_none_bg1 = fft4_default_small(scale=SCALE_NONE, bitGrowth=1)
fft4_small_scale_none_bg2 = fft4_default_small(scale=SCALE_NONE, bitGrowth=2)
fft4_small_scale_div_sqrt_n = fft4_default_small(scale=SCALE_DIV_SQRT_N)
fft4_small_scale_div_sqrt_n_bg1 = fft4_default_small(scale=SCALE_DIV_SQRT_N, bitGrowth=1)
fft4_small_scale_div_n = fft4_default_small(scale=SCALE_DIV_N)

fft4_default_fast = fft4_serial3
fft4_fast_scale_none = fft4_default_fast(scale=SCALE_NONE)
fft4_fast_scale_none_bg1 = fft4_default_fast(scale=SCALE_NONE, bitGrowth=1)
fft4_fast_scale_none_bg2 = fft4_default_fast(scale=SCALE_NONE, bitGrowth=2)
fft4_fast_scale_div_sqrt_n = fft4_default_fast(scale=SCALE_DIV_SQRT_N)
fft4_fast_scale_div_sqrt_n_bg1 = fft4_default_fast(scale=SCALE_DIV_SQRT_N, bitGrowth=1)
fft4_fast_scale_div_n = fft4_default_fast(scale=SCALE_DIV_N)

fft2_default = fft2_serial
fft2_scale_none = fft2_default(scale=SCALE_NONE)
fft2_scale_none_bg1 = fft2_default(scale=SCALE_NONE, bitGrowth=1)
fft2_scale_div_n = fft2_default(scale=SCALE_DIV_N)


fft16 = \
	FFT4Step(16, 
		fft4_scale_none,
		fft4_scale_div_n);

fft16_scale_none = FFT4Step(16,  fft4_scale_none, fft4_scale_none);
fft16_scale_div_n = FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n);

fft16_2 = \
	FFTSPDF(16, fft4_scale_div_n);

# scales by 1/4. 32 is not a perfect square so 1/sqrt(n) is not possible
fft32 = \
	FFT4Step(32,
		FFT4Step(8, 
			fft4_scale_none,
			fft2_scale_none),
		fft4_scale_div_n);

fft64 = \
	FFT4Step(64,
		FFT4Step(16, 
			fft4_scale_none,
			fft4_large_scale_div_sqrt_n),
		fft4_scale_div_n);


fft64_scale_none = FFT4Step(64, fft16_scale_none, fft4_scale_none);
fft64_scale_div_n = FFT4Step(64, fft16_scale_div_n, fft4_scale_div_n);




fft256 = \
	FFT4Step(256,
		FFT4Step(16, 
			fft4_scale_none,
			fft4_scale_none),
		FFT4Step(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));
fft256.setMultiplier(largeMult)


fft1024 = \
	FFT4Step(1024,
		FFT4Step(64,
			FFT4Step(16, 
				fft4_scale_div_sqrt_n,
				fft4_scale_div_sqrt_n),
			fft4_scale_div_sqrt_n),
		FFT4Step(16, 
			fft4_scale_div_sqrt_n,
			fft4_scale_div_sqrt_n));


fft1024_scaled = \
	FFT4Step(1024,
		FFT4Step(64,
			FFT4Step(16, 
				fft4_scale_div_n,
				fft4_scale_div_n),
			fft4_scale_div_n),
		FFT4Step(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));


fft1024_wide = \
	FFT4Step(1024,
		FFT4Step(64,
			FFT4Step(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_scale_div_sqrt_n),
		FFT4Step(16, 
			fft4_scale_div_n,
			fft4_scale_div_n));
fft1024_wide.setMultiplier(largeMult)


fft1024_wide_unscaled = \
	FFT4Step(1024,
		FFT4Step(64,
			FFT4Step(16, 
				fft4_scale_none,
				fft4_scale_none),
			fft4_scale_none),
		FFT4Step(16, 
			fft4_scale_none,
			fft4_scale_none));
fft1024_wide_unscaled.setMultiplier(largeMult)




fft1024_2 = \
	FFT4Step(1024,
		FFT4Step(256,
			FFT4Step(16, 
				fft4_scale_none,
				fft4_scale_none),
			FFT4Step(16, 
				fft4_large_scale_div_sqrt_n,
				fft4_scale_div_n)),
		fft4_scale_div_n);
fft1024_spdf = \
	FFTSPDF(1024,
		bfBitGrowth=1,
		sub1=FFTSPDF(256,
			bfBitGrowth=1,
			sub1=FFT4Step(64,
				FFT4Step(16, 
					fft4_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n)));


fft1024_spdf_wide = \
	FFTSPDF(1024,
		bfBitGrowth=1,
		sub1=FFTSPDF(256,
			bfBitGrowth=1,
			sub1=FFT4Step(64,
				FFT4Step(16, 
					fft4_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n)));

fft1024_spdf_wide.setMultiplier(largeMult)


fft4096 = \
	FFT4Step(4096,
		FFT4Step(64,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			fft4_scale_none),
		FFT4Step(64, 
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192 = \
	FFT4Step(8192,
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			FFT4Step(8,  fft4_scale_none, fft2_scale_div_n)),
		FFT4Step(64, 
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));

fft8192_wide = \
	FFT4Step(8192,
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			FFT4Step(8,  fft4_scale_none, fft2_scale_div_n)),
		FFT4Step(64, 
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			fft4_scale_div_n));
fft8192_wide.setMultiplier(largeMult)


fft16k = \
	FFT4Step(16*1024,
		FFT4Step(4096,
			FFT4Step(64,
				FFT4Step(16,
					fft4_scale_none,
					fft4_scale_none),
				fft4_scale_none),
			FFT4Step(64, 
				FFT4Step(16,
					fft4_large_scale_div_sqrt_n,
					fft4_scale_div_n),
				fft4_scale_div_n)),
		fft4_scale_div_n);

fft16k_2 = \
	FFT4Step(16*1024,
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			FFT4Step(8,  fft4_scale_none, fft2_scale_none)),
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFT4Step(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k = \
	FFT4Step(32*1024,
		FFT4Step(256,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			FFT4Step(16,  fft4_scale_none, fft4_scale_div_sqrt_n)),
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFT4Step(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide = \
	FFT4Step(32*1024,
		FFT4Step(256,
			FFT4Step(16,  fft4_scale_none, fft4_scale_none),
			FFT4Step(16,  fft4_scale_none, fft4_scale_div_sqrt_n)),
		FFT4Step(128,
			FFT4Step(16,  fft4_scale_div_n, fft4_scale_div_n),
			FFT4Step(8,  fft4_scale_div_n, fft2_scale_div_n)));

fft32k_wide.setMultiplier(largeMult)


