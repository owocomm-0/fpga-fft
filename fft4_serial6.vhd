library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 1 cycle; output is unregistered
-- if carryPosition is 0, add 1 to results
-- if carryPosition is 1, add 2 to results
entity fft4_serial6_bf is
	generic(dataBits: integer := 18;
			carryPosition: integer := 0);
	port(clk: in std_logic;
		din: in complexArray(1 downto 0);
		roundIn: in std_logic;
		dout: out complexArray(1 downto 0)
		);
end entity;

architecture a of fft4_serial6_bf is
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
	
	dout(0) <= keepNBits(b(0), dataBits);
	dout(1) <= keepNBits(b(1), dataBits);
end a;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial6_bf;

-- total delay is 11 cycles
-- data input is in natural order and output is in bit reversed order
entity fft4_serial6 is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft4_serial6 is
	constant shift: integer := scalingShift(scale, 2);
	signal ph, ph1: unsigned(1 downto 0);
	
	signal iReg, iReg2, iReg3, dout0: complex;
	signal bfIn, bfOut0: complexArray(1 downto 0);
	signal oReg0, oReg1, oReg2, oReg3, oReg4, oReg5, oReg6: complex;
	signal bfRound: std_logic;
	
	signal trOutA, trOutB: complexArray(1 downto 0);
begin
	
	ph <= phase+1 when rising_edge(clk);
	ph1 <= phase when rising_edge(clk);

--   clk ||   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |
--    ph ||   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |   0   |   1   |
--  srIn || 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  |
--  iReg ||       |       0       |   2   |   3   |       0       |
-- iReg2 ||                       |   0   |       |   3   |
-- iReg3 ||               |               1               |
--  bfIn ||                       | i2,i0 |       | i3,i1 |       | i2,i0 | t2,t0 | i3,i1 | t3,t1 |
--bfOut0 ||                               | t1,t0 | o2,o0 | t3,t2 | o3,o1 | t1,t0 | o2,o0 | t3,t2 | o3,o1 |
-- oReg0 ||                                       |   t0  |  o0   |       t2      |
-- oReg1 ||                                       |   -   |          t0           |
-- oReg2 ||                                       |   -   |       -       |  o1   |
--bfOut0 ||                               | t1,t0 | o2,o0 | t3,t2 | o3,o1 | t1,t0 | o2,o0 | t3,t2 | o3,o1 |
-- oReg3 ||                                       |       t1      |  t3   |   -   |
-- oReg4 ||                                               |       o2      |       o3      |
-- oReg5 ||                                                       |   -   |           t3          |
-- oReg6 ||                                                       |               t1              |
-- dout0 ||                                               |   o0  |  o2   |  o1   |  o3   |
-- trOut ||                                                               | t2,t0 |       | t3,t1 |

	oReg0 <= bfOut0(0) when ph/=3 and rising_edge(clk);
	oReg1 <= oReg0 when ph=1 and rising_edge(clk);
	oReg2 <= bfOut0(0) when ph=3 and rising_edge(clk);
	
	oReg3 <= bfOut0(1) when ph/=1 and rising_edge(clk);
	oReg4 <= bfOut0(1) when (ph=1 or ph=3) and rising_edge(clk);
	oReg5 <= oReg3 when ph=3 and rising_edge(clk);
	oReg6 <= oReg3 when ph=2 and rising_edge(clk);
	
	trOutA <= (oReg0, oReg1);
	trOutB <= (complex_swap(oReg5), oReg6);
	
	dout0 <= oReg0 when ph=2 else
			oReg4 when ph=3 else
			oReg2 when ph=0 else
			oReg4;

	iReg <= din when (ph /= 1) and rising_edge(clk);
	iReg2 <= iReg when rising_edge(clk);
	iReg3 <= din when (ph = 1) and rising_edge(clk);
	
	bfIn <= (iReg, iReg2) when ph=3 else
			(to_complex(iReg2.re, iReg3.im), to_complex(iReg3.re, iReg2.im)) when ph=1 else
			trOutA when ph=0 else
			trOutB;
	bfRound <= '1' when ph=0 or ph=2 else
				'0';
	
	bf: entity fft4_serial6_bf
		generic map(dataBits=>dataBits+2, carryPosition=>shift-1)
		port map(clk=>clk, din=>bfIn, roundIn=>bfRound, dout=>bfOut0);
	
	dout <= keepNBits(shift_right(dout0, shift), dataBits) when rising_edge(clk);
end ar;
