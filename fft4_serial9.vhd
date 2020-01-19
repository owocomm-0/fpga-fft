library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial9_bf1;
use work.fft4_serial9_bf2;

-- delay is 8 cycles
entity fft4_serial9 is
	generic(dataBits: integer := 18;
			bitGrowth: integer := 0;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true;
			inverse: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft4_serial9 is
	constant shift: integer := scalingShift(scale, 2);

	-- lower bits of din2 are duplicated
	constant din2LowerBits: integer := 8;

	signal ph1, ph2, ph3, ph4: unsigned(1 downto 0);
	signal din1, din2, din2Dup, din2_2, din2Next: complex;

	signal dinBias, dinBiasP1, dinBiasP2: std_logic := '0';
	signal roundRandRe, roundRandIm: std_logic := '0';
	signal roundAddRe, roundAddIm: signed(shift downto 0) := (others=>'0');
	signal lfsr, lfsrNext: unsigned(6 downto 0) := "1101010";

	signal bf1Sel: std_logic;
	signal bfOut, bfOut1: complex;
	signal bfHistA, bfHistB: complexArray(7 downto 0);
	signal histSelARe, histSelAIm, histSelBRe, histSelBIm: unsigned(2 downto 0);
	signal histSelAP1, histSelAP2, histSelBP1, histSelBP2: unsigned(2 downto 0);
	signal histOutA, histOutB, histOutBSwapped: complex;

	signal bf2SelBNext: std_logic;
	signal bf2SubtractReNext, bf2SubtractImNext, bf2SubtractTmp: std_logic;

	signal bf2Out: complex;

	-- register duplicates
	signal ph1_dup0, ph1_dup1: unsigned(1 downto 0);

	-- dedicate registers to important control signals
	attribute keep: string;
	attribute EQUIVALENT_REGISTER_REMOVAL: string;

	attribute keep of ph1:signal is "true";
	attribute keep of dinBias:signal is "true";
	attribute EQUIVALENT_REGISTER_REMOVAL of din2:signal is "false";
	attribute EQUIVALENT_REGISTER_REMOVAL of din2Dup:signal is "false";
	attribute keep of bf1Sel:signal is "true";
	attribute keep of histSelARe:signal is "true";
	attribute keep of histSelAIm:signal is "true";
	attribute keep of histSelBRe:signal is "true";
	attribute keep of histSelBIm:signal is "true";
	attribute keep of roundRandRe:signal is "true";
	attribute keep of roundRandIm:signal is "true";
	attribute EQUIVALENT_REGISTER_REMOVAL of bfHistA: signal is "NO";
	attribute EQUIVALENT_REGISTER_REMOVAL of bfHistB: signal is "NO";

	attribute max_fanout: integer;
	attribute max_fanout of histSelARe : signal is 16;
	attribute max_fanout of histSelAIm : signal is 16;
	attribute max_fanout of histSelBRe : signal is 16;
	attribute max_fanout of histSelBIm : signal is 16;

	-- hack to deal with 'U' tainting the lfsr and tainting all outputs
	function ignoreUninitialized(din: unsigned) return unsigned is
		variable ret: unsigned(din'range) := (others=>'0');
	begin
		for I in ret'range loop
			if din(I) = '1' then
				ret(I) := '1';
			end if;
		end loop;
		return ret;
	end function;
begin
	ph1 <= phase when rising_edge(clk);
	ph2 <= ph1 when rising_edge(clk);
	ph3 <= ph2 when rising_edge(clk);
	ph4 <= ph3 when rising_edge(clk);

	din1 <= din when rising_edge(clk);


	-- fast rounding
g8: if shift /= 0 generate
		dinBiasP2 <= '1' when ph1=2 else '0';
		dinBiasP1 <= dinBiasP2 when rising_edge(clk);
		dinBias <= dinBiasP1 when rising_edge(clk);
		lfsrNext <= lfsr(0) & (lfsr(6) xor lfsr(0) xor din1.re(0) xor din1.im(1)) & lfsr(5 downto 1);
		lfsr <= ignoreUninitialized(lfsrNext) when rising_edge(clk);

		roundRandRe <= lfsr(0) when rising_edge(clk);
		roundRandIm <= lfsr(1) when rising_edge(clk);

	gA: if shift=1 generate
			roundAddRe <= "0" & (roundRandRe and dinBias);
			roundAddIm <= "0" & (roundRandIm and dinBias);
		end generate;
	gB: if shift=2 generate
			roundAddRe <= "000" when dinBias='0' else
							"0" & roundRandRe & (not roundRandRe);
			roundAddIm <= "000" when dinBias='0' else
							"0" & roundRandIm & (not roundRandIm);
		end generate;
		din2Next.re <= din1.re + roundAddRe;
		din2Next.im <= din1.im + roundAddIm;
	end generate;
g9: if shift = 0 generate
		din2Next <= din1;
	end generate;

	din2 <= din2Next when rising_edge(clk);

	-- in the cycles where din2Dup is used (butterfly is in subtraction mode),
	-- the bias added to din2 is zero, so we can directly take din2Dup from din1.
	din2Dup <= din1 when rising_edge(clk);

	din2_2.re <= din2.re(din2.re'left downto din2LowerBits) & din2Dup.re(din2LowerBits-1 downto 0);
	din2_2.im <= din2.im(din2.im'left downto din2LowerBits) & din2Dup.im(din2LowerBits-1 downto 0);

	bf1Sel <= ph1(0) when rising_edge(clk);

	bf1: entity fft4_serial9_bf1
		generic map(dataBits=>dataBits+1)
		port map(clk=>clk,
				A=>din2,
				B0=>din1,
				B1=>din2_2,
				selRe=>bf1Sel,
				selIm=>bf1Sel,
				dout=>bfOut);


	-- addressable shift register
	--bfOut1 <= bfOut when rising_edge(clk);
	bfHistA <= bfHistA(bfHistA'left-1 downto 0) & bfOut when rising_edge(clk);
	bfHistB <= bfHistB(bfHistB'left-1 downto 0) & bfOut when rising_edge(clk);
	
	histSelAP2 <= "010" when ph1=3 else
					"011" when ph1=0 else
					"011" when ph1=1 else
					"100";
	--histSelANext <= "001" when ph2=3 else
					--"010" when ph2=0 else
					--"010" when ph2=1 else
					--"011";
	histSelBP2 <= "000" when ph1=3 else
					"001" when ph1=0 else
					"001" when ph1=1 else
					"010";

	histSelAP1 <= histSelAP2 when rising_edge(clk);
	histSelBP1 <= histSelBP2 when rising_edge(clk);

	histSelARe <= histSelAP1 when rising_edge(clk);
	histSelAIm <= histSelAP1 when rising_edge(clk);
	histSelBRe <= histSelBP1 when rising_edge(clk);
	histSelBIm <= histSelBP1 when rising_edge(clk);

	histOutA.re <= bfHistA(to_integer(histSelARe)).re when rising_edge(clk);
	histOutA.im <= bfHistA(to_integer(histSelAIm)).im when rising_edge(clk);
	histOutB.re <= bfHistB(to_integer(histSelBRe)).re when rising_edge(clk);
	histOutB.im <= bfHistB(to_integer(histSelBIm)).im when rising_edge(clk);
	histOutBSwapped <= to_complex(histOutB.im, histOutB.re);


	bf2SubtractTmp <= ph1(1) xor ph1(0) when rising_edge(clk);
g0: if inverse generate
		bf2SubtractReNext <= bf2SubtractTmp;
		bf2SubtractImNext <= ph2(0);
	end generate;
g1: if not inverse generate
		bf2SubtractReNext <= ph2(0);
		bf2SubtractImNext <= bf2SubtractTmp;
	end generate;

	bf2SelBNext <= ph2(1);

	bf2: entity fft4_serial9_bf2
		generic map(dataBits=>dataBits+2)
		port map(clk=>clk,
				A=>histOutA,
				B0=>histOutB,
				B1=>histOutBSwapped,
				selBNext=>bf2SelBNext,
				subtractReNext=>bf2SubtractReNext,
				subtractImNext=>bf2SubtractImNext,
				dout=>bf2Out);

	dout <= keepNBits(shift_right(bf2Out, shift), dataBits + bitGrowth);

end ar;
