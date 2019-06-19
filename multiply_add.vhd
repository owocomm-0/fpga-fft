library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- a,b to p delay is 3
-- c to p delay is 1
entity multiplyAdd is
	generic(in1Bits,in2Bits,outBits: integer;
			subtract: boolean := false);
	port(clk: in std_logic;
			a: in signed(in1Bits-1 downto 0);
			b: in signed(in2Bits-1 downto 0);
			c: in signed(outBits-1 downto 0);
			p: out signed(outBits-1 downto 0)
			);
end entity;
architecture a of multiplyAdd is
	constant intermediateBits: integer := in1Bits + in2Bits;
	signal a1: signed(in1Bits-1 downto 0);
	signal b1: signed(in2Bits-1 downto 0);
	signal m0: signed(intermediateBits-1 downto 0);
	signal m: signed(outBits-1 downto 0);
begin
	a1 <= a when rising_edge(clk);
	b1 <= b when rising_edge(clk);
	m0 <= a1*b1 when rising_edge(clk);
	m <= resize(m0, outBits);
g1: if subtract generate
		p <= c-m when rising_edge(clk);
	end generate;
g2: if not subtract generate
		p <= m+c when rising_edge(clk);
	end generate;
end a;
