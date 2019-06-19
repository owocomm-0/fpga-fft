-- instance name: fft256

-- layout:
--256: twiddleBits=twBits, delay=376
--	16: twiddleBits=twBits, delay=48
--		4: base, 'fft4_serial4', scale='SCALE_NONE', delay=12
--		4: base, 'fft4_serial4', scale='SCALE_NONE', delay=12
--	16: twiddleBits=twBits, delay=48
--		4: base, 'fft4_serial4', scale='SCALE_DIV_N', delay=12
--		4: base, 'fft4_serial4', scale='SCALE_DIV_N', delay=12



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
use work.twiddleRom256;
use work.twiddleGenerator16;
use work.fft4_serial4;

-- data input bit order: (7 downto 0) [1,0,3,2,7,6,5,4]
-- data output bit order: (7 downto 0) [1,0,3,2,5,4,7,6]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 376
entity fft256 is
	generic(dataBits: integer := 24;
			twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(8-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft256 is
	-- ====== FFT instance 'top' (N=256) ======
	constant top_N: integer := 256;
	constant top_twiddleBits: integer := twBits;
	constant top_twiddleDelay: integer := 7;
	constant top_order: integer := 8;
	constant top_delay: integer := 376;

		-- ====== FFT instance 'A' (N=16) ======
		constant A_N: integer := 16;
		constant A_twiddleBits: integer := twBits;
		constant A_twiddleDelay: integer := 2;
		constant A_order: integer := 4;
		constant A_delay: integer := 48;

			-- ====== FFT instance 'AA' (N=4) ======
			constant AA_N: integer := 4;
			constant AA_order: integer := 2;
			constant AA_delay: integer := 12;

			-- ====== FFT instance 'AB' (N=4) ======
			constant AB_N: integer := 4;
			constant AB_order: integer := 2;
			constant AB_delay: integer := 12;

		-- ====== FFT instance 'B' (N=16) ======
		constant B_N: integer := 16;
		constant B_twiddleBits: integer := twBits;
		constant B_twiddleDelay: integer := 2;
		constant B_order: integer := 4;
		constant B_delay: integer := 48;

			-- ====== FFT instance 'BA' (N=4) ======
			constant BA_N: integer := 4;
			constant BA_order: integer := 2;
			constant BA_delay: integer := 12;

			-- ====== FFT instance 'BB' (N=4) ======
			constant BB_N: integer := 4;
			constant BB_order: integer := 2;
			constant BB_delay: integer := 12;

	--=======================================

	-- ====== FFT instance 'top' (N=256) ======
	signal top_in, top_out, top_rbIn: complex;
	signal top_phase: unsigned(top_order-1 downto 0);
	signal top_bitPermIn,top_bitPermOut: unsigned(A_order-1 downto 0);
	-- twiddle generator
	signal top_twAddr: unsigned(top_order-1 downto 0);
	signal top_twData: complex;
	signal top_romAddr: unsigned(top_order-4 downto 0);
	signal top_romData: std_logic_vector(top_twiddleBits*2-3 downto 0);
	signal top_rP0: unsigned(4-1 downto 0);
	signal top_rP1: unsigned(4-1 downto 0);
	signal top_rCnt: unsigned(1-1 downto 0);
	signal top_rbInPhase: unsigned(B_order-1 downto 0);

		-- ====== FFT instance 'A' (N=16) ======
		signal A_in, A_out, A_rbIn: complex;
		signal A_phase: unsigned(A_order-1 downto 0);
		signal A_bitPermIn,A_bitPermOut: unsigned(AA_order-1 downto 0);
		-- twiddle generator
		signal A_twAddr: unsigned(A_order-1 downto 0);
		signal A_twData: complex;
		signal A_romAddr: unsigned(A_order-4 downto 0);
		signal A_romData: std_logic_vector(A_twiddleBits*2-3 downto 0);

			-- ====== FFT instance 'AA' (N=4) ======
			signal AA_in, AA_out: complex;
			signal AA_phase: unsigned(2-1 downto 0);

			-- ====== FFT instance 'AB' (N=4) ======
			signal AB_in, AB_out: complex;
			signal AB_phase: unsigned(2-1 downto 0);

		-- ====== FFT instance 'B' (N=16) ======
		signal B_in, B_out, B_rbIn: complex;
		signal B_phase: unsigned(B_order-1 downto 0);
		signal B_bitPermIn,B_bitPermOut: unsigned(BA_order-1 downto 0);
		-- twiddle generator
		signal B_twAddr: unsigned(B_order-1 downto 0);
		signal B_twData: complex;
		signal B_romAddr: unsigned(B_order-4 downto 0);
		signal B_romData: std_logic_vector(B_twiddleBits*2-3 downto 0);

			-- ====== FFT instance 'BA' (N=4) ======
			signal BA_in, BA_out: complex;
			signal BA_phase: unsigned(2-1 downto 0);

			-- ====== FFT instance 'BB' (N=4) ======
			signal BB_in, BB_out: complex;
			signal BB_phase: unsigned(2-1 downto 0);
begin
	top_in <= din;
	top_phase <= phase;
	dout <= top_out;
	-- ====== FFT instance 'top' (N=256) ======
	top_core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>top_twiddleBits,
			subOrder1=>A_order,
			subOrder2=>B_order,
			twiddleDelay=>top_twiddleDelay,
			multDelay=>8,
			subDelay1=>A_delay,
			subDelay2=>64,
			round=>true,
			customSubOrder=>true)
		port map(
			clk=>clk, phase=>top_phase, phaseOut=>open,
			subOut1=>A_out,
			subIn2=>top_rbIn,
			subPhase2=>top_rbInPhase,
			twAddr=>top_twAddr, twData=>top_twData,
			bitPermIn=>top_bitPermIn, bitPermOut=>top_bitPermOut);
		
	A_in <= top_in;
	top_out <= B_out;
	A_phase <= top_phase(A_order-1 downto 0);
	top_bitPermOut <= top_bitPermIn(1)&top_bitPermIn(0)&top_bitPermIn(3)&top_bitPermIn(2);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom256 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(1)&top_rP0(0)&top_rP0(3)&top_rP0(2) when top_rCnt(0)='1' else top_rP0;
		
	top_rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBits, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>top_rbIn, phase=>top_rbInPhase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP1);
		
	B_phase <= top_rbInPhase-0;

		-- ====== FFT instance 'A' (N=16) ======
		A_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>A_twiddleBits,
				subOrder1=>AA_order,
				subOrder2=>AB_order,
				twiddleDelay=>A_twiddleDelay,
				multDelay=>8,
				subDelay1=>AA_delay,
				subDelay2=>12,
				round=>true,
				customSubOrder=>true)
			port map(
				clk=>clk, phase=>A_phase, phaseOut=>open,
				subOut1=>AA_out,
				subIn2=>AB_in,
				subPhase2=>AB_phase,
				twAddr=>A_twAddr, twData=>A_twData,
				bitPermIn=>A_bitPermIn, bitPermOut=>A_bitPermOut);
			
		AA_in <= A_in;
		A_out <= AB_out;
		AA_phase <= A_phase(AA_order-1 downto 0);
		A_bitPermOut <= A_bitPermIn;
		A_tw: entity twiddleGenerator16 port map(clk, A_twAddr, A_twData);

			-- ====== FFT instance 'AA' (N=4) ======
			AA_inst: entity fft4_serial4
				generic map(dataBits=>dataBits, scale=>SCALE_NONE)
				port map(clk=>clk, din=>AA_in, phase=>AA_phase, dout=>AA_out);

			-- ====== FFT instance 'AB' (N=4) ======
			AB_inst: entity fft4_serial4
				generic map(dataBits=>dataBits, scale=>SCALE_NONE)
				port map(clk=>clk, din=>AB_in, phase=>AB_phase, dout=>AB_out);

		-- ====== FFT instance 'B' (N=16) ======
		B_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>B_twiddleBits,
				subOrder1=>BA_order,
				subOrder2=>BB_order,
				twiddleDelay=>B_twiddleDelay,
				multDelay=>8,
				subDelay1=>BA_delay,
				subDelay2=>12,
				round=>true,
				customSubOrder=>true)
			port map(
				clk=>clk, phase=>B_phase, phaseOut=>open,
				subOut1=>BA_out,
				subIn2=>BB_in,
				subPhase2=>BB_phase,
				twAddr=>B_twAddr, twData=>B_twData,
				bitPermIn=>B_bitPermIn, bitPermOut=>B_bitPermOut);
			
		BA_in <= B_in;
		B_out <= BB_out;
		BA_phase <= B_phase(BA_order-1 downto 0);
		B_bitPermOut <= B_bitPermIn;
		B_tw: entity twiddleGenerator16 port map(clk, B_twAddr, B_twData);

			-- ====== FFT instance 'BA' (N=4) ======
			BA_inst: entity fft4_serial4
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BA_in, phase=>BA_phase, dout=>BA_out);

			-- ====== FFT instance 'BB' (N=4) ======
			BB_inst: entity fft4_serial4
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BB_in, phase=>BB_phase, dout=>BB_out);
end ar;


-- instantiation (python):

--FFTConfiguration(256, 
--	FFTConfiguration(16, 
--		FFTBase(4, 'fft4_serial4', 'SCALE_NONE', 12),
--		FFTBase(4, 'fft4_serial4', 'SCALE_NONE', 12),
--	twiddleBits='twBits'),
--	FFTConfiguration(16, 
--		FFTBase(4, 'fft4_serial4', 'SCALE_DIV_N', 12),
--		FFTBase(4, 'fft4_serial4', 'SCALE_DIV_N', 12),
--	twiddleBits='twBits'),
--twiddleBits='twBits')
