library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 2 cycles
entity fft4_serial4_bf is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true;
			offsetValue: integer := 0);
	port(clk: in std_logic;
		din: in complexArray(1 downto 0);
		dout: out complexArray(1 downto 0)
		);
end entity;

architecture a of fft4_serial4_bf is
	signal a,b: complexArray(1 downto 0);
	constant shift: integer := scalingShift(scale, 1);
begin
	assert (scale=SCALE_NONE or scale=SCALE_DIV_N)
		report "fft-2 does not support scaling type SCALE_DIV_SQRT_N"
			 severity error;
	a <= din when rising_edge(clk);
	b(0) <= a(0) + a(1) + to_complex(offsetValue, offsetValue);
	b(1) <= a(0) - a(1) + to_complex(offsetValue, offsetValue);
	
g:	for I in 0 to 1 generate
	g1: if round and (scale /= SCALE_NONE) generate
			-- add 1 to do rounding instead of truncation
			dout(I) <= keepNBits(shift_right(b(I) + to_complex(1,1),shift), dataBits) when rising_edge(clk);
		end generate;
	g2: if (not round) or scale=SCALE_NONE generate
			dout(I) <= keepNBits(shift_right(b(I),shift), dataBits) when rising_edge(clk);
		end generate;
	end generate;
end a;
