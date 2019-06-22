library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 2 cycles
-- if carryPosition is 0, add 1 to results
-- if carryPosition is 1, add 2 to results
entity fft4_serial4_bf is
	generic(dataBits: integer := 18;
			carryPosition: integer := 0);
	port(clk: in std_logic;
		din: in complexArray(1 downto 0);
		roundIn: in std_logic;
		dout: out complexArray(1 downto 0)
		);
end entity;

architecture a of fft4_serial4_bf is
	signal carry: signed(carryPosition+1 downto 0);
	signal a,b: complexArray(1 downto 0);
	signal c: complex;
begin
	a <= din when rising_edge(clk);

g1: if carryPosition = -1 generate
		c <= to_complex(0,0);
	end generate;
g2: if carryPosition >= 0 generate
		carry <= "0" & roundIn & (carryPosition-1 downto 0=>'0');
		c <= to_complex(carry, carry) when rising_edge(clk);
	end generate;
	
	b(0) <= a(0) + a(1) + c;
	b(1) <= a(0) - a(1) + c;
	
	dout(0) <= keepNBits(b(0), dataBits) when rising_edge(clk);
	dout(1) <= keepNBits(b(1), dataBits) when rising_edge(clk);
end a;
