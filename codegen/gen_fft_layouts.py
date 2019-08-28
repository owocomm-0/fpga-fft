
# This file contains layout definitions. Edit this file to add custom layouts.
# Do not add other logic or call functions in gen_fft_generators.py from this file.

from gen_fft_modules import *

#fft2_scale_none = FFTBase(2, 'fft2_serial2', 'SCALE_NONE', 3)
#fft2_scale_div_n = FFTBase(2, 'fft2_serial2', 'SCALE_DIV_N', 3)

fft2_scale_none = FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6)
fft2_scale_div_n = FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6)


#fft4_scale_none = FFT4Step(4, fft2_scale_none, fft2_scale_none);
#fft4_scale_div_sqrt_n = FFT4Step(4, fft2_scale_none, fft2_scale_div_n);
#fft4_scale_div_n = FFT4Step(4, fft2_scale_div_n, fft2_scale_div_n);


fft4_delay = 10
#fft4_large_scale_none = FFTBase(4, 'fft4_serial3', 'SCALE_NONE', fft4_delay)
fft4_large_scale_div_sqrt_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_SQRT_N', fft4_delay)
#fft4_large_scale_div_n = FFTBase(4, 'fft4_serial3', 'SCALE_DIV_N', fft4_delay)


#fft4_delay = 12
#fft4_scale_none = FFTBase(4, 'fft4_serial4', 'SCALE_NONE', fft4_delay)
#fft4_scale_div_n = FFTBase(4, 'fft4_serial4', 'SCALE_DIV_N', fft4_delay)



#fft4_delay = 11
#fft4_entity = 'fft4_serial7'
fft4_delay = 7
fft4_entity = 'fft4_serial8'
fft4_iBitOrder = [1,0]
fft4_oBitOrder = [1,0]
fft4_scale_none = FFTBase(4, fft4_entity, 'SCALE_NONE', fft4_delay, iBitOrder=fft4_iBitOrder, oBitOrder=fft4_oBitOrder)
fft4_scale_none_bg1 = FFTBase(4, fft4_entity, 'SCALE_NONE', fft4_delay, bitGrowth=1, iBitOrder=fft4_iBitOrder, oBitOrder=fft4_oBitOrder)
fft4_scale_div_sqrt_n = FFTBase(4, fft4_entity, 'SCALE_DIV_SQRT_N', fft4_delay, iBitOrder=fft4_iBitOrder, oBitOrder=fft4_oBitOrder)
fft4_scale_div_n = FFTBase(4, fft4_entity, 'SCALE_DIV_N', fft4_delay, iBitOrder=fft4_iBitOrder, oBitOrder=fft4_oBitOrder)



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


