-- instance name: fft1024_wide

-- layout:
--1024: twiddleBits=twBits, delay=1227
--	64: twiddleBits=twBits, delay=131
--		16: twiddleBits=twBits, delay=47
--			4: base, 'fft4_serial7', scale='SCALE_NONE', bitGrowth=0, delay=11
--			4: base, 'fft4_serial7', scale='SCALE_NONE', bitGrowth=0, delay=11
--		4: base, 'fft4_serial7', scale='SCALE_DIV_SQRT_N', bitGrowth=0, delay=11
--	16: twiddleBits=twBits, delay=47
--		4: base, 'fft4_serial7', scale='SCALE_DIV_N', bitGrowth=0, delay=11
--		4: base, 'fft4_serial7', scale='SCALE_DIV_N', bitGrowth=0, delay=11


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.twiddleAddrGen;
use work.transposer;
use work.twiddleGenerator;
use work.twiddleRom1024;
use work.reorderBuffer;
use work.dsp48e1_complexMultiply;
use work.fft1024_wide_sub64;
use work.fft1024_wide_sub16_2;

-- data input bit order: (9 downto 0) [1,0,3,2,5,4,9,8,7,6]
-- data output bit order: (9 downto 0) [0,1,2,3,4,5,6,7,8,9]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 1227
entity fft1024_wide is
	generic(dataBits: integer := 24;
			twBits: integer := 12;
			inverse: boolean := true);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(10-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide is
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned(6-1 downto 0);
	signal sub2phase: unsigned(4-1 downto 0);
	constant N: integer := 1024;
	constant dataBitsIntern: integer := dataBits + 0;
	constant dataBitsOut: integer := dataBits + 0;
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 7;
	constant order: integer := 10;
	constant delay: integer := 1227;
	constant sub1dataBits: integer := dataBits;
	constant sub2dataBits: integer := dataBitsIntern;


	--=======================================

	signal ph1, ph2, ph3: unsigned(order-1 downto 0);
	signal rbIn, transpOut: complex;
	signal bitPermIn,bitPermOut: unsigned(6-1 downto 0);

	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;

	signal romAddr: unsigned(order-4 downto 0);
	signal romData: std_logic_vector(twiddleBits*2-3 downto 0);
	signal rP0: unsigned(4-1 downto 0);
	signal rP1: unsigned(4-1 downto 0);
	signal rCnt: unsigned(1-1 downto 0);
	signal rbInPhase: unsigned(4-1 downto 0);

begin
	sub1din <= din;
	sub1phase <= phase(6-1 downto 0);

	ph1 <= phase-131+1 when rising_edge(clk);

	transp: entity transposer
		generic map(N1=>4, N2=>6, dataBits=>dataBitsIntern)
		port map(clk=>clk, din=>sub1dout, phase=>ph1, dout=>transpOut);

	ph2 <= ph1;

	twAG: entity twiddleAddrGen
		generic map(
			subOrder1=>6,
			subOrder2=>4,
			twiddleDelay=>twiddleDelay,
			customSubOrder=>true)
		port map(
			clk=>clk,
			phase=>ph2,
			twAddr=>twAddr,
			bitPermIn=>bitPermIn,
			bitPermOut=>bitPermOut);

	twMult: entity dsp48e1_complexMultiply
		generic map(in1Bits=>twiddleBits+1,
					in2Bits=>dataBitsIntern,
					outBits=>dataBitsIntern)
		port map(clk=>clk, in1=>twData, in2=>transpOut, out1=>rbIn);

	ph3 <= ph2-9+1 when rising_edge(clk);
	rbInPhase <= ph3(4-1 downto 0);
	dout <= sub2dout;
	bitPermOut <= bitPermIn(0)&bitPermIn(1)&bitPermIn(2)&bitPermIn(3)&bitPermIn(4)&bitPermIn(5);

	tw: entity twiddleGenerator
		generic map(twiddleBits, order, inverse=>inverse)
		port map(clk, twAddr, twData, romAddr, romData);

	rom: entity twiddleRom1024 generic map(twBits=>twiddleBits)
		port map(clk, romAddr,romData);
	rP1 <= rP0(1)&rP0(0)&rP0(3)&rP0(2) when rCnt(0)='1' else rP0;


	rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBitsIntern, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>rbIn, phase=>rbInPhase, dout=>sub2din,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP1);

	sub2phase <= rbInPhase-0;
	sub1: entity fft1024_wide_sub64 generic map(dataBits=>sub1dataBits, twBits=>twBits, inverse=>inverse)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2: entity fft1024_wide_sub16_2 generic map(dataBits=>sub2dataBits, twBits=>twBits, inverse=>inverse)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;

-- instantiation (python):
--FFT4Step(1024, 
--	FFT4Step(64, 
--		FFT4Step(16, 
--			FFTBase(4, 'fft4_serial7', 'SCALE_NONE', 11, oBitOrder=[1, 0]),
--			FFTBase(4, 'fft4_serial7', 'SCALE_NONE', 11, oBitOrder=[1, 0]),
--			multiplier=Multiplier('dsp48e1_complexMultiply', 9),
--			twiddleBits='twBits'),
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_SQRT_N', 11, oBitOrder=[1, 0]),
--		multiplier=Multiplier('dsp48e1_complexMultiply', 9),
--		twiddleBits='twBits'),
--	FFT4Step(16, 
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_N', 11, oBitOrder=[1, 0]),
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_N', 11, oBitOrder=[1, 0]),
--		multiplier=Multiplier('dsp48e1_complexMultiply', 9),
--		twiddleBits='twBits'),
--	multiplier=Multiplier('dsp48e1_complexMultiply', 9),
--	twiddleBits='twBits')