library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- values are unnormalized
entity fft2_noPipeline is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := false);
	port(din: in complexArray(1 downto 0);
		dout: out complexArray(1 downto 0)
		);
end entity;

architecture a of fft2_noPipeline is
	signal a,b: complexArray(1 downto 0);
	constant shift: integer := scalingShift(scale, 1);
begin
	assert (scale=SCALE_NONE or scale=SCALE_DIV_N)
		report "fft-2 does not support scaling type SCALE_DIV_SQRT_N"
			 severity error;
	a <= din;
	b(0) <= a(0) + a(1);
	b(1) <= a(0) - a(1);
	
g:	for I in 0 to 1 generate
	g1: if round and (scale /= SCALE_NONE) generate
			-- add 1 to do rounding instead of truncation
			dout(I) <= keepNBits(shift_right(b(I) + to_complex(1,1),shift), dataBits);
		end generate;
	g2: if (not round) or scale=SCALE_NONE generate
			dout(I) <= keepNBits(shift_right(b(I),shift), dataBits);
		end generate;
	end generate;
end a;
