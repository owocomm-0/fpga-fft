library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial6_bf;

-- total delay is 11 cycles
-- data input is in natural order and output is in bit reversed order
entity fft4_serial7 is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true;
			inverse: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft4_serial7 is
	constant shift: integer := scalingShift(scale, 2);
	signal ph, ph1: unsigned(1 downto 0);
	
	signal iReg, iReg2, iReg3, dout0: complex;
	signal bfIn, bfOut0: complexArray(1 downto 0);
	signal oReg0, oReg1, oReg2, oReg3, oReg4, oReg5, oReg6: complex;
	signal bfRound: std_logic;
	
	signal inA, inB, trOutA, trOutB: complexArray(1 downto 0);
begin
	
	ph <= phase+1 when rising_edge(clk);
	ph1 <= phase when rising_edge(clk);

--   clk ||   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |
--    ph ||   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |   0   |   1   |
--  srIn || 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  | 3210  | 0321  | 1032  | 2103  |
--  iReg ||       |   0   |   1   |   2   |   3   |   0   |   1   |
-- iReg2 ||               |   0   |   1   |   2   |   3   |   0   |
-- iReg3 ||               |   -   |   0   |       1       |
--  bfIn ||                       | i2,i0 |       | i3,i1 |       | i2,i0 | t2,t0 | i3,i1 | t3,t1 |
--bfOut0 ||                               | t1,t0 | o2,o0 | t3,t2 | o3,o1 | t1,t0 | o2,o0 | t3,t2 | o3,o1 |
-- oReg0 ||                                       |  t0   |  o0   |  t2   |  o1   |  t0   |  o0   |  t2   |  o1   |
-- oReg1 ||                                       |  o1   |  t0   |  o0   |  t2   |  o1   |  t0   |  o0   |  t2   |
-- oReg2 ||                                       |       -       |       t0      |
--bfOut0 ||                               | t1,t0 | o2,o0 | t3,t2 | o3,o1 | t1,t0 | o2,o0 | t3,t2 | o3,o1 |
-- oReg3 ||                                       |  t1   |  o2   |  t3   |  o3   |  t1   |  o2   |  t3   |  o3   |
-- oReg4 ||                                       |  o3   |  t1   |  o2   |  t3   |  o3   |  t1   |  o2   |  t3   |
-- oReg5 ||                                                       |   -   |           t3          |
-- oReg6 ||                                                       |               t1              |
-- dout0 ||                                               |   o0  |  o2   |  o1   |  o3   |
-- trOut ||                                                               | t2,t0 |       | t3,t1 |

	oReg0 <= bfOut0(0) when rising_edge(clk);
	oReg1 <= oReg0 when rising_edge(clk);
	oReg2 <= oReg1 when ph=2 and rising_edge(clk);
	
	oReg3 <= bfOut0(1) when rising_edge(clk);
	oReg4 <= oReg3 when rising_edge(clk);
	oReg5 <= oReg3 when ph=3 and rising_edge(clk);
	oReg6 <= oReg4 when ph=2 and rising_edge(clk);
	
	trOutA <= (oReg1, oReg2);
	trOutB <= (complex_swap(oReg5), oReg6);
	
	dout0 <= oReg0 when ph=2 else
			oReg4 when ph=3 else
			oReg0 when ph=0 else
			oReg4;

	iReg <= din when rising_edge(clk);
	iReg2 <= iReg when rising_edge(clk);
	iReg3 <= iReg2 when (ph=2 or ph=3) and rising_edge(clk);

g1: if inverse generate
		inA <= (iReg, iReg3);
		inB <= (to_complex(iReg2.re, iReg3.im), to_complex(iReg3.re, iReg2.im));
	end generate;
g2: if not inverse generate
		inA <= (iReg, iReg3);
		inB <= (to_complex(iReg3.re, iReg2.im), to_complex(iReg2.re, iReg3.im));
	end generate;

	bfIn <= inA when ph=3 else
			inB when ph=1 else
			trOutA when ph=0 else
			trOutB;
	bfRound <= '1' when ph=0 or ph=2 else
				'0';
	
	bf: entity fft4_serial6_bf
		generic map(dataBits=>dataBits+2, carryPosition=>shift-1)
		port map(clk=>clk, din=>bfIn, roundIn=>bfRound, dout=>bfOut0);
	
	dout <= keepNBits(shift_right(dout0, shift), dataBits) when rising_edge(clk);
end ar;
