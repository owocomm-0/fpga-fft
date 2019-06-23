library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexRam;
use work.twiddleGenerator;
use work.complexMultiply;
use work.complexMultiply2;
use work.complexMultiplyLarge;
use work.dsp48e1_complexMultiply;
use work.transposer;

-- data input and output are in transposed order: 0,4,8,12,1,5,9,13,... (for N=16)
-- sub-fft should accept data and output data in linear order.
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n).

-- subOut1 should be wired to the output of a fft-2*subOrder1.
-- subIn2 should be wired to the input of a fft-2*subOrder2.
-- phases of the 2 sub-ffts are simply the global phase (modulus sub-N).

-- If customSubOrder is true, sub-fft 1 accepts and outputs data in an arbitrary order
-- determined by a address bit permutation. bitPermOut and bitPermIn should be connected
-- to the permutation function (purely combinational).
-- The order of data input and output are also affected: row order of the input are permuted
-- (e.g. 0,8,4,12,1,9,5,13,...), and column order of the output are permuted
-- (e.g. 0,4,8,12,2,6,10,14,...). sub-fft 2 must still accept data in linear order,
-- but may output data in permuted order, in which case the rows of the output
-- are permuted.
entity fft3step_bram_generic3 is
	generic(dataBits: integer := 18;
			twiddleBits: integer := 12;
			subOrder1,subOrder2: integer := 4;
			twiddleDelay: integer := 7;
			subDelay1,subDelay2: integer := 11;
			multDelay: integer := 6;
			customSubOrder: boolean := false;
			round: boolean := true;
			largeMultiplier: boolean := false
			);

	port(clk: in std_logic;
		subOut1: in complex;
		phase: in unsigned(subOrder1+subOrder2-1 downto 0);
		subIn2: out complex;
		subPhase2: out unsigned(subOrder2-1 downto 0);
		phaseOut: out unsigned(subOrder1+subOrder2-1 downto 0);
		
		-- twiddle generator
		twAddr: out unsigned(subOrder1+subOrder2-1 downto 0);
		twData: in complex;
		
		bitPermIn: out unsigned(subOrder1-1 downto 0) := (others=>'X');
		bitPermOut: in unsigned(subOrder1-1 downto 0) := (others=>'0')
		);
end entity;

architecture ar of fft3step_bram_generic3 is
	constant order: integer := subOrder1+subOrder2;
	constant N: integer := 2**order;
	constant subN1: integer := 2**subOrder1;
	constant subN2: integer := 2**subOrder2;

	signal ph1: unsigned(order-1 downto 0) := (others=>'0');
	signal ph2: unsigned(order downto 0) := (others=>'0');
	
	signal rph0,rph1,rph2,rph3,rph4,rph5,rph6,rph_twiddle: unsigned(order-1 downto 0) := (others=>'0');
	signal twRowAddr: unsigned(subOrder1-1 downto 0) := (others=>'0');
	signal raddr: unsigned(order downto 0) := (others=>'0');
	signal rdata: complex;
	signal twAddr0, twAddr0Next: unsigned(order-1 downto 0) := (others=>'0');
	signal multOut: complex;
begin
	-- perform subN2 ffts of size subN1
	-- delay is subDelay1 cycles
	--subIn1 <= din;
	--subPhase1 <= phase(subOrder1-1 downto 0);
	ph1 <= phase-subDelay1+1 when rising_edge(clk); -- subDelay1 cycles of apparent delay
	-- subOut1 is aligned with ph1
	
	transp: entity transposer generic map(subOrder2, subOrder1, dataBits)
		port map(clk, subOut1, ph1, rdata);
	rph0 <= ph1;
	-- rdata is aligned with rph0
	-- fft4_delay + 16 cycles
	
	-- fetch twiddle factors
	-- twiddle index is actually rowIndex*colIndex
	rph_twiddle <= rph0+twiddleDelay+2 when rising_edge(clk);
	
	bitPermIn <= rph_twiddle(rph_twiddle'left downto subOrder2);
	twRowAddr <= bitPermOut when customSubOrder=true else
		rph_twiddle(rph_twiddle'left downto subOrder2);
	
	twAddr0Next <= (others=>'0') when rph_twiddle(subOrder2-1 downto 0)=0 else
					twAddr0 + twRowAddr;
	twAddr0 <= twAddr0Next when rising_edge(clk); -- aligned with rph0+twiddleDelay
	twAddr <= twAddr0;
	-- twData is aligned with rph0
	
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
			port map(clk, twdata, rdata, multOut);
	end generate;
g_mult2:
	if not largeMultiplier generate
		mult: entity complexMultiply2
			generic map(in1Bits=>dataBits, in2Bits=>twiddleBits+1,
						outBits=>dataBits, round=>round)
			port map(clk, rdata, twdata, multOut);
	end generate;
	
	
	rph3 <= rph0-multDelay+1 when rising_edge(clk);
	-- subDelay1 + 16 + mult_delay cycles
	
	-- perform subN1 ffts of size subN2
	-- delay is subDelay2 cycles
	subIn2 <= multOut;
	subPhase2 <= rph3(subOrder2-1 downto 0);
	--subPhase2 <= rph3(subOrder2-1 downto 0);
	--dout <= subOut2;
	phaseOut <= rph3-subDelay2+1 when rising_edge(clk);
	-- subDelay1 + N + mult_delay + subDelay2 cycles
end ar;
