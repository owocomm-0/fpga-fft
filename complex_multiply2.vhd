library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.multiplyAdd;

-- delay is 5 cycles
-- rounding is always enabled regardless of "round" parameter
entity complexMultiply2 is
	generic(in1Bits,in2Bits,outBits: integer := 8;
			round: boolean := true);
	port(clk: in std_logic;
			in1,in2: in complex;
			out1: out complex
			);
end entity;
architecture a of complexMultiply2 is
	constant internalBits: integer := in1Bits + in2Bits;
	signal halfLSB: signed(internalBits-outBits-2 downto 0);
	signal halfLSB1: signed(internalBits-1 downto 0);
	signal a,b,a1,b1,a2,b2,a3,b3: signed(in1Bits-1 downto 0);
	signal c,d,c1,d1,c2,d2,c3,d3: signed(in2Bits-1 downto 0);
	
	signal ac,bd,ad,bc, ac1,bd1,ad1,bc1, ac2,bd2,ad2,bc2,
			ac3,bd3,ad3,bc3, ac4,bd4,ad4,bc4: signed(internalBits-1 downto 0);
	signal res_re, res_im: signed(outBits-1 downto 0);
begin
	a <= complex_re(in1, in1Bits);-- when rising_edge(clk);
	b <= complex_im(in1, in1Bits);-- when rising_edge(clk);
	c <= complex_re(in2, in2Bits);-- when rising_edge(clk);
	d <= complex_im(in2, in2Bits);-- when rising_edge(clk);
	a1 <= a when rising_edge(clk);
	b1 <= b when rising_edge(clk);
	c1 <= c when rising_edge(clk);
	d1 <= d when rising_edge(clk);
	a2 <= a1 when rising_edge(clk);
	b2 <= b1 when rising_edge(clk);
	c2 <= c1 when rising_edge(clk);
	d2 <= d1 when rising_edge(clk);
	a3 <= a2 when rising_edge(clk);
	b3 <= b2 when rising_edge(clk);
	c3 <= c2 when rising_edge(clk);
	d3 <= d2 when rising_edge(clk);
	
	
	halfLSB <= "01" & (halfLSB'left-2 downto 0=>'0');
	halfLSB1 <= resize(halfLSB,internalBits);
	
	mAdd1: entity multiplyAdd
		generic map(in1Bits=>in1Bits, in2Bits=>in2Bits, outBits=>internalBits)
		port map(clk, a, c, halfLSB1, ac3);
	mAdd2: entity multiplyAdd
		generic map(in1Bits=>in1Bits, in2Bits=>in2Bits, outBits=>internalBits)
		port map(clk, a, d, halfLSB1, ad3);
	
	mAdd3: entity multiplyAdd
		generic map(in1Bits=>in1Bits, in2Bits=>in2Bits, outBits=>internalBits, subtract=>true)
		port map(clk, b1, d1, ac3, bd4);
	mAdd4: entity multiplyAdd
		generic map(in1Bits=>in1Bits, in2Bits=>in2Bits, outBits=>internalBits, subtract=>false)
		port map(clk, b1, c1, ad3, bc4);
	
	res_re <= bd4(bd4'left-2 downto bd4'left-outBits-1) when rising_edge(clk);
	res_im <= bc4(bc4'left-2 downto bc4'left-outBits-1) when rising_edge(clk);
	
	out1 <= to_complex(res_re, res_im); -- when rising_edge(clk);
end a;
