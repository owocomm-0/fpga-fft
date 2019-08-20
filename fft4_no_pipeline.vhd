library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- values are normalized to sqrt(n)
entity fft4_noPipeline is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_DIV_SQRT_N;
			inverse: boolean := true;
			round: boolean := true);
	port(din: in complexArray(3 downto 0);
		dout: out complexArray(3 downto 0)
		);
end entity;

architecture a of fft4_noPipeline is
	signal a,b: complexArray(3 downto 0);
	signal resA1, resA2, resB1, resB2: complex;
	constant mask: integer := to_integer(signed'(dataBits-1 downto 0=>'1'));
	constant shift: integer := scalingShift(scale, 2);
begin
	a <= din;
	resA1 <= a(0) + a(2);
	resA2 <= a(0) - a(2);
	resB1 <= a(1) + a(3);

	-- resB2 is multiplied by either j or -j
g3: if inverse generate
		resB2.re <= a(1).im - a(3).im;
		resB2.im <= a(3).re - a(1).re;
	end generate;
g4: if not inverse generate
		resB2.re <= a(3).im - a(1).im;
		resB2.im <= a(1).re - a(3).re;
	end generate;

	b(0) <= resA1 + resB1;
	b(3) <= resA2 + resB2;
	b(2) <= resA1 - resB1;
	b(1) <= resA2 - resB2;
	
g:	for I in 0 to 3 generate
	g1: if round and (scale /= SCALE_NONE) generate
			-- add 1 to do rounding instead of truncation
			dout(I) <= keepNBits(shift_right(b(I) + to_complex(2**(shift-1),2**(shift-1)),shift), dataBits);
		end generate;
	g2: if (not round) or scale=SCALE_NONE generate
			dout(I) <= keepNBits(shift_right(b(I),shift), dataBits);
		end generate;
	end generate;
end a;
