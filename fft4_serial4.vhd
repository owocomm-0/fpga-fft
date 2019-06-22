library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- timing diagram:
--   clk ||   -   |   -   |   -   |   -   |   -   |   -   |
--    ph ||   2   |   3   |   0   |   1   |   2   |   3   |
--   din || a1&a0 | a3&a2 |  'X'  |  'X'  | b1&b0 | b3*b2 |
--  dout ||                       | a2&a0 | a3&a1 |
-- doutA ||                       | a2&a0 |
-- doutB ||                               | a3&a1 |
entity fft4_serial4_transposer is
	generic(dataBits: integer := 18);
	port(clk: in std_logic;
		din: in complexArray(1 downto 0);
		phase: in unsigned(1 downto 0);
		dout, doutA, doutB: out complexArray(1 downto 0));
end entity;

architecture ar of fft4_serial4_transposer is
	signal ph1: unsigned(1 downto 0);
	signal registers: complexArray(3 downto 0);
	signal doutA0, doutB0: complexArray(1 downto 0);
begin
	registers(0) <= din(0) when phase=2 and rising_edge(clk);
	registers(1) <= din(1) when phase=2 and rising_edge(clk);
	registers(2) <= din(0) when phase=3 and rising_edge(clk);
	registers(3) <= din(1) when phase=3 and rising_edge(clk);
	
	doutA0 <= (registers(2), registers(0));
	doutB0 <= (complex_swap(registers(3)), registers(1));
	dout <= doutA0 when phase(0)='1' else
			doutB0;
	doutA <= doutA0;
	doutB <= doutB0;
end ar;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial4_bf;
use work.fft4_serial4_transposer;

-- total delay is 12 cycles
entity fft4_serial4 is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;

architecture ar of fft4_serial4 is
	constant shift: integer := scalingShift(scale, 2);
	signal ph, ph1: unsigned(1 downto 0);
	signal srIn: complexArray(3 downto 0);
	signal bfIn, bfOut, trIn, trOut: complexArray(1 downto 0);
	signal bfRound: std_logic;
	
	signal bfOutP,bfOut1: complexArray(1 downto 0);
	signal trOutA, trOutB: complexArray(1 downto 0);
	signal dout0: complex;
begin

--   clk ||   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |
--    ph ||   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |
--  srIn || 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  |
--  bfIn ||                       | i2,i0 | i3,i1 | t2,t0 | t3,t1 | i1,i0 | i3,i2 | t2,t0 | t3,t1 |
--bfOutP ||                                       | t1,t0 | t3,t2 | o2,o0 | o1,o3 |
-- bfOut ||                                               | t1,t0 | t3,t2 | o2,o0 | o1,o3 |

	ph <= phase+1 when rising_edge(clk);
	ph1 <= phase when rising_edge(clk);
	srIn <= din & srIn(3 downto 1) when rising_edge(clk);
	bfIn <= (srIn(3), srIn(1)) when ph=3 else
			(to_complex(srIn(1).re, srIn(3).im), to_complex(srIn(3).re, srIn(1).im)) when ph=0 else
			trOutA when ph=1 else
			trOutB;
	bfRound <= '1' when ph=1 or ph=2 else
				'0';
	trIn <= bfOut;
	
	bf: entity fft4_serial4_bf
		generic map(dataBits=>dataBits+2, carryPosition=>shift-1)
		port map(clk=>clk, din=>bfIn, roundIn=>bfRound, dout=>bfOutP);
	
	tr: entity fft4_serial4_transposer
		generic map(dataBits=>dataBits+1)
		port map(clk=>clk, din=>trIn, phase=>ph, dout=>trOut,
				doutA=>trOutA, doutB=>trOutB);
	
	bfOut <= bfOutP when rising_edge(clk);
	bfOut1 <= bfOut when rising_edge(clk);
	dout0 <= bfOutP(0) when ph=3 else
			bfOutP(1) when ph=0 else
			bfOut1(1) when ph=1 else
			bfOut1(0);
	
	dout <= keepNBits(shift_right(dout0, shift), dataBits) when rising_edge(clk);
end ar;
