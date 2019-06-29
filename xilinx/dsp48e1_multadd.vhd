library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- a,b to p delay is 3
-- c to p delay is 1
entity dsp48e1_multAdd is
	generic(subtract, cShift17: boolean := false);
	port(clk: in std_logic;
			a: in signed(24 downto 0);
			b: in signed(17 downto 0);
			c: in signed(47 downto 0);
			p: out signed(47 downto 0)
			);
end entity;
architecture a of dsp48e1_multAdd is
	signal a1: signed(24 downto 0);
	signal b1: signed(17 downto 0);
	signal c0: signed(47 downto 0);
	--signal m0: signed(47 downto 0);
	signal m: signed(47 downto 0);
begin
	a1 <= a when rising_edge(clk);
	b1 <= b when rising_edge(clk);
	m <= resize(a1*b1, 48) when rising_edge(clk);

g3: if cShift17 generate
		c0 <= shift_right(c, 17); --(16 downto 0=>'0') & c(c'left downto 17);
	end generate;
g4: if not cShift17 generate
		c0 <= c;
	end generate;

g5: if subtract generate
		p <= m-c0 when rising_edge(clk);
	end generate;
g6: if not subtract generate
		p <= m+c0 when rising_edge(clk);
	end generate;
end a;



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.dsp48e1_multAdd;

-- a,b to p delay is 5
-- c to p delay is 3
entity dsp48e1_largeMultAdd is
	generic(subtract: boolean := false);
	port(clk: in std_logic;
			a: in signed(24 downto 0);
			b: in signed(34 downto 0);
			c: in signed(64 downto 0);
			p: out signed(64 downto 0)
			);
end entity;
architecture a of dsp48e1_largeMultAdd is
	signal a1: signed(24 downto 0);
	signal b1: signed(34 downto 0);
	signal c1,c2,c3,c4: signed(64 downto 0);
	signal bin: signed(17 downto 0);
	signal cin: signed(47 downto 0);
	signal pLower, pLower1, pUpper: signed(47 downto 0);
	signal pFull: signed(64 downto 0);
begin
	a1 <= a when rising_edge(clk);
	b1 <= b when rising_edge(clk);
	c1 <= c when rising_edge(clk);
	
	c2 <= c1 when rising_edge(clk);
	c3 <= c2 when rising_edge(clk);
	c4 <= c3 when rising_edge(clk);
	
	multLower: entity dsp48e1_multAdd
		generic map(subtract=>subtract)
		port map(clk=>clk, a=>a, b=>bin,
				c=>cin, p=>pLower);
	cin <= "00" & c(45 downto 0);
	bin <= "0" & b(16 downto 0);
	
	pLower1 <= pLower when rising_edge(clk);
	
	multUpper: entity dsp48e1_multAdd
		generic map(cShift17=>true)
		port map(clk=>clk, a=>a1, b=>b1(34 downto 17),
				c=>pLower, p=>pUpper);
	
	pFull <= (pUpper & pLower1(16 downto 0));
	
g1: if not subtract generate
		p <= pFull + (c2(c2'left downto 46) & (45 downto 0=>'0')) when rising_edge(clk);
	end generate;
g2: if subtract generate
		p <= pFull - (c2(c2'left downto 46) & (45 downto 0=>'0')) when rising_edge(clk);
	end generate;
end a;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.dsp48e1_largeMultAdd;

-- in1 is 25 bits and in2 is 35 bits
-- delay is 9 cycles
entity dsp48e1_complexMultiply35x25 is
	generic(outBits: integer := 48;
			shiftRight: integer := 24;
			round: boolean := true);
	port(clk: in std_logic;
			in1,in2: in complex;
			out1: out complex
			);
end entity;
architecture a of dsp48e1_complexMultiply35x25 is
	constant in1Bits: integer := 25;
	constant in2Bits: integer := 35;
	constant internalBits: integer := 65;
	signal a,b,a1,b1,a2,b2,a3,b3,a4,b4: signed(in1Bits-1 downto 0);
	signal c,d,c1,d1,c2,d2,c3,d3,c4,d4: signed(in2Bits-1 downto 0);
	signal ac,bd,ad,bc, bdIn, bcIn: signed(internalBits-1 downto 0);
	signal res_re, res_im: signed(outBits-1 downto 0);
	
	signal roundIn1, roundIn2: signed(internalBits-1 downto 0);
begin
	a <= complex_re(in1, in1Bits); -- when rising_edge(clk);
	b <= complex_im(in1, in1Bits); -- when rising_edge(clk);
	c <= complex_re(in2, in2Bits); -- when rising_edge(clk);
	d <= complex_im(in2, in2Bits); -- when rising_edge(clk);
	
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
	a4 <= a3 when rising_edge(clk);
	b4 <= b3 when rising_edge(clk);
	c4 <= c3 when rising_edge(clk);
	d4 <= d3 when rising_edge(clk);
	
g1: if round generate
		roundIn1 <= resize("01" & (shiftRight-2 downto 0=>'0'), internalBits);
		roundIn2 <= -resize("01" & (shiftRight-2 downto 0=>'0'), internalBits);
	end generate;
g2: if not round generate
		roundIn1 <= (others=>'0');
		roundIn2 <= (others=>'0');
	end generate;
	
	-- multiply
	m1: entity dsp48e1_largeMultAdd
		port map(clk=>clk, a=>b, b=>d, c=>roundIn2, p=>bd);
	m2: entity dsp48e1_largeMultAdd
		port map(clk=>clk, a=>b, b=>c, c=>roundIn1, p=>bc);
	
	bdIn <= (bd'left downto 59=>bd(58)) & bd(58 downto 0) when rising_edge(clk);
	bcIn <= (bc'left downto 59=>bc(58)) & bc(58 downto 0) when rising_edge(clk);
	
	m3: entity dsp48e1_largeMultAdd
		generic map(subtract=>true)
		port map(clk=>clk, a=>a4, b=>c4, c=>bdIn, p=>ac);
	m4: entity dsp48e1_largeMultAdd
		port map(clk=>clk, a=>a4, b=>d4, c=>bcIn, p=>ad);
	
	res_re <= resize(shift_right(ac, shiftRight), outBits);
	res_im <= resize(shift_right(ad, shiftRight), outBits);
	out1 <= to_complex(res_re, res_im);
end a;



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.dsp48e1_complexMultiply35x25;

-- max width is 25 (in1) and 35 (in2)
-- delay is 9 cycles
entity dsp48e1_complexMultiply is
	generic(in1Bits, in2Bits, outBits: integer := 8;
			round: boolean := true);
	port(clk: in std_logic;
			in1,in2: in complex;
			out1: out complex
			);
end entity;
architecture a of dsp48e1_complexMultiply is

begin
	mult: entity dsp48e1_complexMultiply35x25
		generic map(outBits=>outBits, shiftRight=>(in1Bits+in2Bits-outBits-2), round=>round)
		port map(clk=>clk, in1=>in1, in2=>in2, out1=>out1);
end a;

