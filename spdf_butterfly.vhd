library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 2 cycles
-- if carryPosition is 0, add 1 to results
-- if carryPosition is 1, add 2 to results
entity spdf_butterflyA is
	generic(dataBits: integer := 18);
	port(clk: in std_logic;
		din: in complexArray(1 downto 0);
		dout: out complexArray(1 downto 0)
		);
end entity;

architecture a of spdf_butterflyA is
	signal a,b: complexArray(1 downto 0);
	signal c: complex;
begin
	a <= din when rising_edge(clk);
	
	b(0) <= a(0) + a(1);
	b(1) <= a(0) - a(1);
	
	dout(0) <= keepNBits(b(0), dataBits) when rising_edge(clk);
	dout(1) <= keepNBits(b(1), dataBits) when rising_edge(clk);
end a;
