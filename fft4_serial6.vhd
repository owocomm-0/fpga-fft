library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 1 cycle; output is unregistered
-- if carryPosition is 0, add 0 or 1 to results
-- if carryPosition is 1, add 1 or 2 to results
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
	signal roundIn1: std_logic;
	signal carry1, carry2, cA, cB, cA1, cB1: signed(carryPosition+1 downto 0);
	signal a,b,aPlusB,aMinusB: complex;
	signal carrySelA, carrySelB: std_logic;
	signal carryAddA, carryAddB: complex := to_complex(0,0);
begin
	a <= din(0) when rising_edge(clk);
	b <= din(1) when rising_edge(clk);
	roundIn1 <= roundIn when rising_edge(clk);

	-- set up carry signals for rounding
	-- carry1 rounds with + bias, and carry2 rounds with - bias
g1: if carryPosition = 0 generate
		carry1 <= "01";
		carry2 <= "00";
	end generate;
g2: if carryPosition > 0 generate
		carry1 <= "01" & (carryPosition-1 downto 0=>'0');
		carry2 <= "00" & (carryPosition-1 downto 0=>'1');
	end generate;

	-- select carry signal based on input
g4: if carryPosition >= 0 generate
		carrySelA <= a.re(carryPosition+1); -- when rising_edge(clk);
		carrySelB <= b.re(carryPosition+1); -- when rising_edge(clk);
		cA <= carry1 when carrySelA='1' else carry2;
		cB <= carry1 when carrySelB='0' else carry2;
		--cB <= cA;

		cA1 <= cA and (cA'range=>roundIn);
		cB1 <= cB and (cB'range=>roundIn);

		carryAddA <= to_complex(cA1, cA1) when rising_edge(clk);
		carryAddB <= to_complex(cB1, cB1) when rising_edge(clk);
	end generate;
--g2: if carryPosition = 0 generate
--		c <= to_complex(1, 1) when roundIn1='1' else
--			to_complex(0, 0);
--	end generate;
--g3: if carryPosition = 1 generate
--	end generate;
	
	--aPlusB <= round_convergent(a + b, roundIn1, carryPosition);
	--aMinusB <= round_convergent(a - b, roundIn1, carryPosition);

	aPlusB <= a + b + carryAddA;
	aMinusB <= a - b + carryAddB;

	dout(0) <= keepNBits(aPlusB, dataBits);
	dout(1) <= keepNBits(aMinusB, dataBits);
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
