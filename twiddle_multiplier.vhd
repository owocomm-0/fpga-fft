library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexMultiply;
use work.complexMultiply2;
use work.complexMultiplyLarge;
use work.dsp48e1_complexMultiply;

-- If customSubOrder is true, the columns (slow changing part of the phase)
-- are reordered by a user defined permutation. bitPermOut and bitPermIn
-- should be connected to this permutation function (purely combinational).
-- total delay is equal to multDelay.
entity twiddleMultiplier is
	generic(dataBits: integer := 18;
			twiddleBits: integer := 12;
			subOrder1,subOrder2: integer := 4;
			twiddleDelay: integer := 7;
			multDelay: integer := 6;
			customSubOrder: boolean := false;
			round: boolean := true;
			largeMultiplier: boolean := false
			);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(subOrder1+subOrder2-1 downto 0);
		dout: out complex;
		
		-- twiddle generator
		twAddr: out unsigned(subOrder1+subOrder2-1 downto 0);
		twData: in complex;
		
		bitPermIn: out unsigned(subOrder1-1 downto 0) := (others=>'X');
		bitPermOut: in unsigned(subOrder1-1 downto 0) := (others=>'0')
		);
end entity;

architecture ar of twiddleMultiplier is
	constant order: integer := subOrder1+subOrder2;
	constant N: integer := 2**order;
	constant subN1: integer := 2**subOrder1;
	constant subN2: integer := 2**subOrder2;
	
	constant extraPhaseReg: boolean := false; --(order >= 12);
	constant extraTwiddleReg: boolean := false; --(order >= 13);
	constant twDelay: integer := twiddleDelay + iif(extraTwiddleReg, 1, 0);

	signal ph_1, ph0: unsigned(order-1 downto 0) := (others=>'0');
	
	signal ph_twiddle: unsigned(order-1 downto 0) := (others=>'0');
	signal twMajorAddr: unsigned(subOrder1-1 downto 0) := (others=>'0');
	signal twData1: complex;
	signal twAddr0, twAddr0Next: unsigned(order-1 downto 0) := (others=>'0');
begin
g1: if extraPhaseReg generate
		ph_1 <= phase+2 when rising_edge(clk);
		ph0 <= ph_1 when rising_edge(clk);
	end generate;
g2: if not extraPhaseReg generate
		ph0 <= phase;
	end generate;
	
	ph_twiddle <= ph0+twDelay+2 when rising_edge(clk);
	
	bitPermIn <= ph_twiddle(ph_twiddle'left downto subOrder2);
	twMajorAddr <= bitPermOut when customSubOrder=true else
		ph_twiddle(ph_twiddle'left downto subOrder2);
	
	twAddr0Next <= (others=>'0') when ph_twiddle(subOrder2-1 downto 0)=0 else
					twAddr0 + twMajorAddr;
	twAddr0 <= twAddr0Next when rising_edge(clk); -- aligned with ph0+twiddleDelay
	twAddr <= twAddr0;
	
	
g3: if extraTwiddleReg generate
		twData1 <= twData when rising_edge(clk);
	end generate;
g4: if not extraTwiddleReg generate
		twData1 <= twData;
	end generate;
	-- twData1 is aligned with ph0
	
	
	-- mutliply by twiddles; delay is multDelay cycles
g_mult:
	if largeMultiplier generate
		--mult: entity complexMultiplyLarge
			--generic map(in1Bits=>dataBits, in2Bits=>twiddleBits+1,
						--outBits=>dataBits, round=>round)
			--port map(clk, rdata, twdata, multOut);
		mult: entity dsp48e1_complexMultiply
			generic map(in1Bits=>twiddleBits+1, in2Bits=>dataBits,
						outBits=>dataBits, round=>round)
			port map(clk, twData1, din, dout);
	end generate;
g_mult2:
	if not largeMultiplier generate
		mult: entity complexMultiply2
			generic map(in1Bits=>dataBits, in2Bits=>twiddleBits+1,
						outBits=>dataBits, round=>round)
			port map(clk, din, twData1, dout);
	end generate;
end ar;
