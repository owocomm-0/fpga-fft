library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 3 clock cycles;
-- values are normalized to sqrt(n)
entity fft4 is
	generic(dataBits: integer := 18);

	port(clk: in std_logic;
		din: in complexArray(3 downto 0);
		dout: out complexArray(3 downto 0)
		);
end entity;

architecture a of fft4 is
	signal a,b: complexArray(3 downto 0);
	signal resA1, resA2, resB1, resB2: complex;
	constant mask: integer := to_integer(signed'(dataBits-1 downto 0=>'1'));
begin
	a <= din when rising_edge(clk);
	resA1 <= a(0) + a(2) when rising_edge(clk);
	resA2 <= a(0) - a(2) when rising_edge(clk);
	resB1 <= a(1) + a(3) when rising_edge(clk);
	resB2.re <= a(1).im - a(3).im when rising_edge(clk);
	resB2.im <= a(3).re - a(1).re when rising_edge(clk);
	
	b(0) <= resA1 + resB1 when rising_edge(clk);
	b(3) <= resA2 + resB2 when rising_edge(clk);
	b(2) <= resA1 - resB1 when rising_edge(clk);
	b(1) <= resA2 - resB2 when rising_edge(clk);
	
g:	for I in 0 to 3 generate
		dout(I) <= keepNBits(shift_right(b(I),1), dataBits);
	end generate;
end a;
