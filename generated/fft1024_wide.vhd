-- instance name: fft1024_wide

-- layout:
--1024: twiddleBits=twBits, delay=1227
--	64: twiddleBits=twBits, delay=131
--		16: twiddleBits=twBits, delay=47
--			4: base, 'fft4_serial7', scale='SCALE_NONE', delay=11
--			4: base, 'fft4_serial7', scale='SCALE_NONE', delay=11
--		4: base, 'fft4_serial7', scale='SCALE_DIV_SQRT_N', delay=11
--	16: twiddleBits=twBits, delay=47
--		4: base, 'fft4_serial7', scale='SCALE_DIV_N', delay=11
--		4: base, 'fft4_serial7', scale='SCALE_DIV_N', delay=11



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
use work.twiddleGenerator16;
use work.fft4_serial7;

-- data input bit order: (3 downto 0) [1,0,3,2]
-- data output bit order: (3 downto 0) [0,1,2,3]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 47
entity fft1024_wide_sub16 is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(4-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_sub16 is
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned(2-1 downto 0);
	signal sub2phase: unsigned(2-1 downto 0);
	constant N: integer := 16;
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 2;
	constant order: integer := 4;
	constant delay: integer := 47;


	--=======================================

	signal rbIn: complex;
	signal bitPermIn,bitPermOut: unsigned(2-1 downto 0);
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	signal romAddr: unsigned(order-4 downto 0);
	signal romData: std_logic_vector(twiddleBits*2-3 downto 0);

begin
	core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder1=>2,
			subOrder2=>2,
			twiddleDelay=>twiddleDelay,
			multDelay=>9,
			subDelay1=>11,
			subDelay2=>11,
			round=>true,
			customSubOrder=>true,
			largeMultiplier=>true)
		port map(
			clk=>clk, phase=>phase, phaseOut=>open,
			subOut1=>sub1dout,
			subIn2=>sub2din,
			subPhase2=>sub2phase,
			twAddr=>twAddr, twData=>twData,
			bitPermIn=>bitPermIn, bitPermOut=>bitPermOut);
		
	sub1din <= din;
	dout <= sub2dout;
	sub1phase <= phase(2-1 downto 0);
	bitPermOut <= bitPermIn(0)&bitPermIn(1);
	tw: entity twiddleGenerator16 port map(clk, twAddr, twData);
	sub1inst: entity fft4_serial7
		generic map(dataBits=>dataBits, scale=>SCALE_NONE)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2inst: entity fft4_serial7
		generic map(dataBits=>dataBits, scale=>SCALE_NONE)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
use work.twiddleRom64;
use work.fft1024_wide_sub16;
use work.fft4_serial7;

-- data input bit order: (5 downto 0) [1,0,3,2,5,4]
-- data output bit order: (5 downto 0) [0,1,2,3,4,5]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 131
entity fft1024_wide_sub64 is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(6-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_sub64 is
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned(4-1 downto 0);
	signal sub2phase: unsigned(2-1 downto 0);
	constant N: integer := 64;
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 7;
	constant order: integer := 6;
	constant delay: integer := 131;


	--=======================================

	signal rbIn: complex;
	signal bitPermIn,bitPermOut: unsigned(4-1 downto 0);
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	signal romAddr: unsigned(order-4 downto 0);
	signal romData: std_logic_vector(twiddleBits*2-3 downto 0);

begin
	core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder1=>4,
			subOrder2=>2,
			twiddleDelay=>twiddleDelay,
			multDelay=>9,
			subDelay1=>47,
			subDelay2=>47,
			round=>true,
			customSubOrder=>true,
			largeMultiplier=>true)
		port map(
			clk=>clk, phase=>phase, phaseOut=>open,
			subOut1=>sub1dout,
			subIn2=>sub2din,
			subPhase2=>sub2phase,
			twAddr=>twAddr, twData=>twData,
			bitPermIn=>bitPermIn, bitPermOut=>bitPermOut);
		
	sub1din <= din;
	dout <= sub2dout;
	sub1phase <= phase(4-1 downto 0);
	bitPermOut <= bitPermIn(0)&bitPermIn(1)&bitPermIn(2)&bitPermIn(3);
	tw: entity twiddleGenerator generic map(twiddleBits, order)
		port map(clk, twAddr, twData, romAddr, romData);
	rom: entity twiddleRom64 port map(clk, romAddr,romData);
	sub1: entity fft1024_wide_sub16 generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2inst: entity fft4_serial7
		generic map(dataBits=>dataBits, scale=>SCALE_DIV_SQRT_N)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
use work.twiddleGenerator16;
use work.fft4_serial7;

-- data input bit order: (3 downto 0) [1,0,3,2]
-- data output bit order: (3 downto 0) [0,1,2,3]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 47
entity fft1024_wide_sub16_2 is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(4-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_sub16_2 is
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned(2-1 downto 0);
	signal sub2phase: unsigned(2-1 downto 0);
	constant N: integer := 16;
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 2;
	constant order: integer := 4;
	constant delay: integer := 47;


	--=======================================

	signal rbIn: complex;
	signal bitPermIn,bitPermOut: unsigned(2-1 downto 0);
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	signal romAddr: unsigned(order-4 downto 0);
	signal romData: std_logic_vector(twiddleBits*2-3 downto 0);

begin
	core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder1=>2,
			subOrder2=>2,
			twiddleDelay=>twiddleDelay,
			multDelay=>9,
			subDelay1=>11,
			subDelay2=>11,
			round=>true,
			customSubOrder=>true,
			largeMultiplier=>true)
		port map(
			clk=>clk, phase=>phase, phaseOut=>open,
			subOut1=>sub1dout,
			subIn2=>sub2din,
			subPhase2=>sub2phase,
			twAddr=>twAddr, twData=>twData,
			bitPermIn=>bitPermIn, bitPermOut=>bitPermOut);
		
	sub1din <= din;
	dout <= sub2dout;
	sub1phase <= phase(2-1 downto 0);
	bitPermOut <= bitPermIn(0)&bitPermIn(1);
	tw: entity twiddleGenerator16 port map(clk, twAddr, twData);
	sub1inst: entity fft4_serial7
		generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2inst: entity fft4_serial7
		generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;



library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic3;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
use work.twiddleRom1024;
use work.fft1024_wide_sub64;
use work.fft1024_wide_sub16_2;

-- data input bit order: (9 downto 0) [1,0,3,2,5,4,9,8,7,6]
-- data output bit order: (9 downto 0) [0,1,2,3,4,5,6,7,8,9]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 1227
entity fft1024_wide is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
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
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 7;
	constant order: integer := 10;
	constant delay: integer := 1227;


	--=======================================

	signal rbIn: complex;
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
	core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder1=>6,
			subOrder2=>4,
			twiddleDelay=>twiddleDelay,
			multDelay=>9,
			subDelay1=>131,
			subDelay2=>147,
			round=>true,
			customSubOrder=>true,
			largeMultiplier=>true)
		port map(
			clk=>clk, phase=>phase, phaseOut=>open,
			subOut1=>sub1dout,
			subIn2=>rbIn,
			subPhase2=>rbInPhase,
			twAddr=>twAddr, twData=>twData,
			bitPermIn=>bitPermIn, bitPermOut=>bitPermOut);
		
	sub1din <= din;
	dout <= sub2dout;
	sub1phase <= phase(6-1 downto 0);
	bitPermOut <= bitPermIn(0)&bitPermIn(1)&bitPermIn(2)&bitPermIn(3)&bitPermIn(4)&bitPermIn(5);
	tw: entity twiddleGenerator generic map(twiddleBits, order)
		port map(clk, twAddr, twData, romAddr, romData);
	rom: entity twiddleRom1024 port map(clk, romAddr,romData);
	rP1 <= rP0(1)&rP0(0)&rP0(3)&rP0(2) when rCnt(0)='1' else rP0;
		
	rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBits, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>rbIn, phase=>rbInPhase, dout=>sub2din,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP1);
		
	sub2phase <= rbInPhase-0;
		
	sub1: entity fft1024_wide_sub64 generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2: entity fft1024_wide_sub16_2 generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;


-- instantiation (python):

--FFTConfiguration(1024, 
--	FFTConfiguration(64, 
--		FFTConfiguration(16, 
--			FFTBase(4, 'fft4_serial7', 'SCALE_NONE', 11),
--			FFTBase(4, 'fft4_serial7', 'SCALE_NONE', 11),
--		twiddleBits='twBits'),
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_SQRT_N', 11),
--	twiddleBits='twBits'),
--	FFTConfiguration(16, 
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_N', 11),
--		FFTBase(4, 'fft4_serial7', 'SCALE_DIV_N', 11),
--	twiddleBits='twBits'),
--twiddleBits='twBits')
