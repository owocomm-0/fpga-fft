library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial8_bf;

-- delay is 8 cycles if convergentRound is true, or 7 cycles if false.
-- if convergentRound is false, rounding bias is random.
-- input and output are in bit reversed order.
entity fft4_serial8 is
	generic(dataBits: integer := 18;
			bitGrowth: integer := 0;
			scale: scalingModes := SCALE_NONE;
			round: boolean := true;
			-- if true, use an extra adder for rounding for increased Fmax;
			-- only applicable for random rounding; does not increase pipeline delay.
			fastRounding: boolean := true;
			convergentRound: boolean := false;
			inverse: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft4_serial8 is
	constant shift: integer := scalingShift(scale, 2);

	-- 0: no rounding; 1: in-butterfly rounding; 2: fast rounding; 3: convergent rounding
	constant roundingMode: integer := iif(shift=0 or round=false, 0,
											iif(convergentRound, 3,
												iif(fastRounding, 2, 1)));
	-- how many bits to drop
	constant bfRoundPos: integer := iif(roundingMode=1, shift, 0);

	-- if dropping one bit, do it in bf2;
	-- if dropping two bits, add 0/1 in bf1 and add 0/1 in bf2.
	constant bf2RoundPos: integer := iif(bfRoundPos >= 1, 1, 0);
	constant bf1RoundPos: integer := iif(bfRoundPos = 2, 1, 0);

	signal ph1, ph2, ph3, ph4: unsigned(1 downto 0);
	signal din1, bfInA, bfInB, bfOut, tmp1, tmp2: complex;
	signal bf2InA, bf2InB, bf2InANext, bf2InBNext, bf2Out: complex;
	signal bfSubtractRe, bfSubtractIm, bf2SubtractRe, bf2SubtractIm: std_logic;
	signal bf2SubtractTmp: std_logic;

	signal dinBias: std_logic := '0';
	signal bf1Bias: std_logic := '0';
	signal roundRandRe, roundRandIm: std_logic := '0';
	signal roundAddRe, roundAddIm: signed(shift downto 0) := (others=>'0');
	signal dout0Next: complex;

	signal lfsr, lfsrNext: unsigned(6 downto 0) := "1101010";


	-- register duplicates
	signal ph1_dup0, ph1_dup1: unsigned(1 downto 0);

	-- dedicate registers to important control signals
	attribute keep: string;
	attribute keep of ph1:signal is "true";
	attribute keep of bfSubtractRe:signal is "true";
	attribute keep of bfSubtractIm:signal is "true";
	attribute keep of bf1Bias:signal is "true";
	attribute keep of bf2SubtractRe:signal is "true";
	attribute keep of bf2SubtractIm:signal is "true";
	attribute keep of roundRandRe:signal is "true";
	attribute keep of roundRandIm:signal is "true";
	attribute keep of ph1_dup0:signal is "true";
	attribute keep of ph1_dup1:signal is "true";

	attribute max_fanout: integer;
	attribute max_fanout of bfSubtractRe : signal is 16;
	attribute max_fanout of bfSubtractIm : signal is 16;
	attribute max_fanout of bf1Bias : signal is 16;
	attribute max_fanout of bf2SubtractRe : signal is 16;
	attribute max_fanout of bf2SubtractIm : signal is 16;
	attribute max_fanout of roundRandRe : signal is 16;
	attribute max_fanout of roundRandIm : signal is 16;

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



	--ph <= phase+1 when rising_edge(clk);
	ph1 <= phase when rising_edge(clk);
	ph2 <= ph1 when rising_edge(clk);
	ph3 <= ph2 when rising_edge(clk);
	ph4 <= ph3 when rising_edge(clk);

	ph1_dup0 <= phase when rising_edge(clk);
	ph1_dup1 <= phase when rising_edge(clk);

	din1 <= keepNBits(din, dataBits) when rising_edge(clk);
	
	bfInB <= din when ph1(0)='0' and rising_edge(clk);

	-- fast rounding
g8: if roundingMode = 2 generate
		dinBias <= ph2(1) when rising_edge(clk);
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
		bfInA.re <= din1.re + roundAddRe when ph1(0)='0' and rising_edge(clk);
		bfInA.im <= din1.im + roundAddIm when ph1(0)='0' and rising_edge(clk);
	end generate;
g9: if roundingMode /= 2 generate
		bfInA <= din1 when ph1(0)='0' and rising_edge(clk);
	end generate;


	bfSubtractRe <= ph1(0) when rising_edge(clk);
	bfSubtractIm <= ph1(0) when rising_edge(clk);

	bf1: entity fft4_serial8_bf
		generic map(dataBits=>dataBits+1,
					roundPos=>bf1RoundPos)
		port map(clk=>clk,
				dinA=>bfInA,
				dinB=>bfInB,
				subtractRe=>bfSubtractRe,
				subtractIm=>bfSubtractIm,
				roundRandRe=>bf1Bias,
				roundRandIm=>bf1Bias,
				dout=>bfOut);

	tmp1 <= bfOut when ph2(1)='0' and rising_edge(clk);
	tmp2 <= bfOut when ph1(1)='1' and rising_edge(clk);

	bf2InANext <= tmp1 when ph1_dup0(1)='0' else tmp2;
	bf2InBNext <= bfOut when ph1_dup1(1)='0' else to_complex(tmp1.im, tmp1.re);
	bf2InA <= bf2InANext when ph1_dup0(0)='0' and rising_edge(clk);
	bf2InB <= bf2InBNext when ph1_dup1(0)='0' and rising_edge(clk);


	bf2SubtractTmp <= phase(1) xor phase(0) when rising_edge(clk);
g0: if inverse generate
		bf2SubtractRe <= bf2SubtractTmp when rising_edge(clk);
		bf2SubtractIm <= ph1(0) when rising_edge(clk);
	end generate;
g1: if not inverse generate
		bf2SubtractRe <= ph1(0) when rising_edge(clk);
		bf2SubtractIm <= bf2SubtractTmp when rising_edge(clk);
	end generate;

	bf2: entity fft4_serial8_bf
		generic map(dataBits=>dataBits+2, roundPos=>bf2RoundPos)
		port map(clk=>clk,
				dinA=>bf2InA,
				dinB=>bf2InB,
				subtractRe=>bf2SubtractRe,
				subtractIm=>bf2SubtractIm,
				roundRandRe=>roundRandRe,
				roundRandIm=>roundRandIm,
				dout=>bf2Out);

	-- in-butterfly rounding
g2: if roundingMode = 1 generate
		lfsrNext <= lfsr(0) & (lfsr(6) xor lfsr(0) xor tmp1.re(0) xor tmp1.im(1)) & lfsr(5 downto 1);
		lfsr <= ignoreUninitialized(lfsrNext) when rising_edge(clk);

		roundRandRe <= lfsr(0) when rising_edge(clk);
		roundRandIm <= lfsr(1) when rising_edge(clk);
		bf1Bias <= ph3(1) when rising_edge(clk);
		--roundRandRe <= bf2InA.re(1) xor bf2InA.re(2) xor bf2InB.re(1) xor bf2InB.re(2) when rising_edge(clk);
		--roundRandIm <= bf2InA.im(1) xor bf2InA.im(2) xor bf2InB.im(1) xor bf2InB.im(2) when rising_edge(clk);
		
	end generate;

	-- unless convergent rounding, take the output from bf2
gOut:
	if roundingMode /= 3 generate
		dout <= keepNBits(shift_right(bf2Out, shift), dataBits + bitGrowth);
	end generate;

	-- convergent rounding
g3: if roundingMode = 3 generate
		assert fastRounding = false;
		-- roundRandRe/roundRandIm selects whether to round with a bias towards +inf or -inf.
		-- in convergent rounding mode we alternate between +inf and -inf bias.
		roundRandRe <= bf2Out.re(shift);
		roundRandIm <= bf2Out.im(shift);
	g4: if shift=0 generate
			dout <= keepNBits(bf2Out, dataBits + bitGrowth) when rising_edge(clk);
		end generate;
	g5: if shift=1 generate
			roundAddRe <= "0" & roundRandRe;
			roundAddIm <= "0" & roundRandIm;
		end generate;
	g6: if shift=2 generate
			roundAddRe <= "0" & roundRandRe & (not roundRandRe);
			roundAddIm <= "0" & roundRandIm & (not roundRandIm);
		end generate;

	g7: if shift /= 0 generate
			dout0Next.re <= bf2Out.re + roundAddRe;
			dout0Next.im <= bf2Out.im + roundAddIm;
			dout <= keepNBits(shift_right(dout0Next, shift), dataBits + bitGrowth) when rising_edge(clk);
		end generate;
	end generate;

end ar;
