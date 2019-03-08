
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
use work.twiddleGenerator4;
use work.fft2_serial;

-- data input bit order: (7 downto 0) [0,1,3,2,7,6,5,4]
-- data output bit order: (7 downto 0) [0,1,2,3,4,5,6,7]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 418
entity fft256_generated is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(8-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft256_generated is
	-- ====== FFT instance 'top' (N=256) ======
	constant top_N: integer := 256;
	constant top_twiddleBits: integer := 12;
	constant top_twiddleDelay: integer := 7;
	constant top_order: integer := 8;
	constant top_delay: integer := 418;

		-- ====== FFT instance 'A' (N=16) ======
		constant A_N: integer := 16;
		constant A_twiddleBits: integer := 12;
		constant A_twiddleDelay: integer := 2;
		constant A_order: integer := 4;
		constant A_delay: integer := 70;

			-- ====== FFT instance 'AA' (N=4) ======
			constant AA_N: integer := 4;
			constant AA_twiddleBits: integer := 12;
			constant AA_twiddleDelay: integer := 2;
			constant AA_order: integer := 2;
			constant AA_delay: integer := 22;

				-- ====== FFT instance 'AAA' (N=2) ======
				constant AAA_N: integer := 2;
				constant AAA_order: integer := 1;
				constant AAA_delay: integer := 6;

				-- ====== FFT instance 'AAB' (N=2) ======
				constant AAB_N: integer := 2;
				constant AAB_order: integer := 1;
				constant AAB_delay: integer := 6;

			-- ====== FFT instance 'AB' (N=4) ======
			constant AB_N: integer := 4;
			constant AB_twiddleBits: integer := 12;
			constant AB_twiddleDelay: integer := 2;
			constant AB_order: integer := 2;
			constant AB_delay: integer := 22;

				-- ====== FFT instance 'ABA' (N=2) ======
				constant ABA_N: integer := 2;
				constant ABA_order: integer := 1;
				constant ABA_delay: integer := 6;

				-- ====== FFT instance 'ABB' (N=2) ======
				constant ABB_N: integer := 2;
				constant ABB_order: integer := 1;
				constant ABB_delay: integer := 6;

		-- ====== FFT instance 'B' (N=16) ======
		constant B_N: integer := 16;
		constant B_twiddleBits: integer := 12;
		constant B_twiddleDelay: integer := 2;
		constant B_order: integer := 4;
		constant B_delay: integer := 70;

			-- ====== FFT instance 'BA' (N=4) ======
			constant BA_N: integer := 4;
			constant BA_twiddleBits: integer := 12;
			constant BA_twiddleDelay: integer := 2;
			constant BA_order: integer := 2;
			constant BA_delay: integer := 22;

				-- ====== FFT instance 'BAA' (N=2) ======
				constant BAA_N: integer := 2;
				constant BAA_order: integer := 1;
				constant BAA_delay: integer := 6;

				-- ====== FFT instance 'BAB' (N=2) ======
				constant BAB_N: integer := 2;
				constant BAB_order: integer := 1;
				constant BAB_delay: integer := 6;

			-- ====== FFT instance 'BB' (N=4) ======
			constant BB_N: integer := 4;
			constant BB_twiddleBits: integer := 12;
			constant BB_twiddleDelay: integer := 2;
			constant BB_order: integer := 2;
			constant BB_delay: integer := 22;

				-- ====== FFT instance 'BBA' (N=2) ======
				constant BBA_N: integer := 2;
				constant BBA_order: integer := 1;
				constant BBA_delay: integer := 6;

				-- ====== FFT instance 'BBB' (N=2) ======
				constant BBB_N: integer := 2;
				constant BBB_order: integer := 1;
				constant BBB_delay: integer := 6;

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
	signal top_rP2: unsigned(4-1 downto 0);
	signal top_rCnt: unsigned(2-1 downto 0);
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
		signal A_rP0: unsigned(2-1 downto 0);
		signal A_rP1: unsigned(2-1 downto 0);
		signal A_rCnt: unsigned(1-1 downto 0);
		signal A_rbInPhase: unsigned(AB_order-1 downto 0);

			-- ====== FFT instance 'AA' (N=4) ======
			signal AA_in, AA_out, AA_rbIn: complex;
			signal AA_phase: unsigned(AA_order-1 downto 0);
			signal AA_bitPermIn,AA_bitPermOut: unsigned(AAA_order-1 downto 0);
			-- twiddle generator
			signal AA_twAddr: unsigned(AA_order-1 downto 0);
			signal AA_twData: complex;
			signal AA_romAddr: unsigned(AA_order-4 downto 0);
			signal AA_romData: std_logic_vector(AA_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'AAA' (N=2) ======
				signal AAA_in, AAA_out: complex;
				signal AAA_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'AAB' (N=2) ======
				signal AAB_in, AAB_out: complex;
				signal AAB_phase: unsigned(1-1 downto 0);

			-- ====== FFT instance 'AB' (N=4) ======
			signal AB_in, AB_out, AB_rbIn: complex;
			signal AB_phase: unsigned(AB_order-1 downto 0);
			signal AB_bitPermIn,AB_bitPermOut: unsigned(ABA_order-1 downto 0);
			-- twiddle generator
			signal AB_twAddr: unsigned(AB_order-1 downto 0);
			signal AB_twData: complex;
			signal AB_romAddr: unsigned(AB_order-4 downto 0);
			signal AB_romData: std_logic_vector(AB_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'ABA' (N=2) ======
				signal ABA_in, ABA_out: complex;
				signal ABA_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'ABB' (N=2) ======
				signal ABB_in, ABB_out: complex;
				signal ABB_phase: unsigned(1-1 downto 0);

		-- ====== FFT instance 'B' (N=16) ======
		signal B_in, B_out, B_rbIn: complex;
		signal B_phase: unsigned(B_order-1 downto 0);
		signal B_bitPermIn,B_bitPermOut: unsigned(BA_order-1 downto 0);
		-- twiddle generator
		signal B_twAddr: unsigned(B_order-1 downto 0);
		signal B_twData: complex;
		signal B_romAddr: unsigned(B_order-4 downto 0);
		signal B_romData: std_logic_vector(B_twiddleBits*2-3 downto 0);
		signal B_rP0: unsigned(2-1 downto 0);
		signal B_rP1: unsigned(2-1 downto 0);
		signal B_rCnt: unsigned(1-1 downto 0);
		signal B_rbInPhase: unsigned(BB_order-1 downto 0);

			-- ====== FFT instance 'BA' (N=4) ======
			signal BA_in, BA_out, BA_rbIn: complex;
			signal BA_phase: unsigned(BA_order-1 downto 0);
			signal BA_bitPermIn,BA_bitPermOut: unsigned(BAA_order-1 downto 0);
			-- twiddle generator
			signal BA_twAddr: unsigned(BA_order-1 downto 0);
			signal BA_twData: complex;
			signal BA_romAddr: unsigned(BA_order-4 downto 0);
			signal BA_romData: std_logic_vector(BA_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'BAA' (N=2) ======
				signal BAA_in, BAA_out: complex;
				signal BAA_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'BAB' (N=2) ======
				signal BAB_in, BAB_out: complex;
				signal BAB_phase: unsigned(1-1 downto 0);

			-- ====== FFT instance 'BB' (N=4) ======
			signal BB_in, BB_out, BB_rbIn: complex;
			signal BB_phase: unsigned(BB_order-1 downto 0);
			signal BB_bitPermIn,BB_bitPermOut: unsigned(BBA_order-1 downto 0);
			-- twiddle generator
			signal BB_twAddr: unsigned(BB_order-1 downto 0);
			signal BB_twData: complex;
			signal BB_romAddr: unsigned(BB_order-4 downto 0);
			signal BB_romData: std_logic_vector(BB_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'BBA' (N=2) ======
				signal BBA_in, BBA_out: complex;
				signal BBA_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'BBB' (N=2) ======
				signal BBB_in, BBB_out: complex;
				signal BBB_phase: unsigned(1-1 downto 0);
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
			subDelay1=>A_delay,
			subDelay2=>86,
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
	top_bitPermOut <= top_bitPermIn(0)&top_bitPermIn(1)&top_bitPermIn(2)&top_bitPermIn(3);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom256 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(0)&top_rP0(1)&top_rP0(3)&top_rP0(2) when top_rCnt(0)='1' else top_rP0;
	top_rP2 <= top_rP1(2)&top_rP1(3)&top_rP1(0)&top_rP1(1) when top_rCnt(1)='1' else top_rP1;
		
	top_rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>top_rbIn, phase=>top_rbInPhase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP2);
		
	B_phase <= top_rbInPhase-0;

		-- ====== FFT instance 'A' (N=16) ======
		A_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>A_twiddleBits,
				subOrder1=>AA_order,
				subOrder2=>AB_order,
				twiddleDelay=>A_twiddleDelay,
				subDelay1=>AA_delay,
				subDelay2=>26,
				customSubOrder=>true)
			port map(
				clk=>clk, phase=>A_phase, phaseOut=>open,
				subOut1=>AA_out,
				subIn2=>A_rbIn,
				subPhase2=>A_rbInPhase,
				twAddr=>A_twAddr, twData=>A_twData,
				bitPermIn=>A_bitPermIn, bitPermOut=>A_bitPermOut);
			
		AA_in <= A_in;
		A_out <= AB_out;
		AA_phase <= A_phase(AA_order-1 downto 0);
		A_bitPermOut <= A_bitPermIn(0)&A_bitPermIn(1);
		A_tw: entity twiddleGenerator16 port map(clk, A_twAddr, A_twData);
		A_rP1 <= A_rP0(0)&A_rP0(1) when A_rCnt(0)='1' else A_rP0;
			
		A_rb: entity reorderBuffer
			generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>A_rbIn, phase=>A_rbInPhase, dout=>AB_in,
				bitPermIn=>A_rP0, bitPermCount=>A_rCnt, bitPermOut=>A_rP1);
			
		AB_phase <= A_rbInPhase-0;

			-- ====== FFT instance 'AA' (N=4) ======
			AA_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>AA_twiddleBits,
					subOrder1=>AAA_order,
					subOrder2=>AAB_order,
					twiddleDelay=>AA_twiddleDelay,
					subDelay1=>AAA_delay,
					subDelay2=>6,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>AA_phase, phaseOut=>open,
					subOut1=>AAA_out,
					subIn2=>AAB_in,
					subPhase2=>AAB_phase,
					twAddr=>AA_twAddr, twData=>AA_twData,
					bitPermIn=>AA_bitPermIn, bitPermOut=>AA_bitPermOut);
				
			AAA_in <= AA_in;
			AA_out <= AAB_out;
			AAA_phase <= AA_phase(AAA_order-1 downto 0);
			AA_bitPermOut <= AA_bitPermIn;
			AA_tw: entity twiddleGenerator4 port map(clk, AA_twAddr, AA_twData);

				-- ====== FFT instance 'AAA' (N=2) ======
				AAA_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>AAA_in, phase=>AAA_phase, dout=>AAA_out);

				-- ====== FFT instance 'AAB' (N=2) ======
				AAB_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>AAB_in, phase=>AAB_phase, dout=>AAB_out);

			-- ====== FFT instance 'AB' (N=4) ======
			AB_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>AB_twiddleBits,
					subOrder1=>ABA_order,
					subOrder2=>ABB_order,
					twiddleDelay=>AB_twiddleDelay,
					subDelay1=>ABA_delay,
					subDelay2=>6,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>AB_phase, phaseOut=>open,
					subOut1=>ABA_out,
					subIn2=>ABB_in,
					subPhase2=>ABB_phase,
					twAddr=>AB_twAddr, twData=>AB_twData,
					bitPermIn=>AB_bitPermIn, bitPermOut=>AB_bitPermOut);
				
			ABA_in <= AB_in;
			AB_out <= ABB_out;
			ABA_phase <= AB_phase(ABA_order-1 downto 0);
			AB_bitPermOut <= AB_bitPermIn;
			AB_tw: entity twiddleGenerator4 port map(clk, AB_twAddr, AB_twData);

				-- ====== FFT instance 'ABA' (N=2) ======
				ABA_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>ABA_in, phase=>ABA_phase, dout=>ABA_out);

				-- ====== FFT instance 'ABB' (N=2) ======
				ABB_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>ABB_in, phase=>ABB_phase, dout=>ABB_out);

		-- ====== FFT instance 'B' (N=16) ======
		B_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>B_twiddleBits,
				subOrder1=>BA_order,
				subOrder2=>BB_order,
				twiddleDelay=>B_twiddleDelay,
				subDelay1=>BA_delay,
				subDelay2=>26,
				customSubOrder=>true)
			port map(
				clk=>clk, phase=>B_phase, phaseOut=>open,
				subOut1=>BA_out,
				subIn2=>B_rbIn,
				subPhase2=>B_rbInPhase,
				twAddr=>B_twAddr, twData=>B_twData,
				bitPermIn=>B_bitPermIn, bitPermOut=>B_bitPermOut);
			
		BA_in <= B_in;
		B_out <= BB_out;
		BA_phase <= B_phase(BA_order-1 downto 0);
		B_bitPermOut <= B_bitPermIn(0)&B_bitPermIn(1);
		B_tw: entity twiddleGenerator16 port map(clk, B_twAddr, B_twData);
		B_rP1 <= B_rP0(0)&B_rP0(1) when B_rCnt(0)='1' else B_rP0;
			
		B_rb: entity reorderBuffer
			generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>B_rbIn, phase=>B_rbInPhase, dout=>BB_in,
				bitPermIn=>B_rP0, bitPermCount=>B_rCnt, bitPermOut=>B_rP1);
			
		BB_phase <= B_rbInPhase-0;

			-- ====== FFT instance 'BA' (N=4) ======
			BA_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>BA_twiddleBits,
					subOrder1=>BAA_order,
					subOrder2=>BAB_order,
					twiddleDelay=>BA_twiddleDelay,
					subDelay1=>BAA_delay,
					subDelay2=>6,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>BA_phase, phaseOut=>open,
					subOut1=>BAA_out,
					subIn2=>BAB_in,
					subPhase2=>BAB_phase,
					twAddr=>BA_twAddr, twData=>BA_twData,
					bitPermIn=>BA_bitPermIn, bitPermOut=>BA_bitPermOut);
				
			BAA_in <= BA_in;
			BA_out <= BAB_out;
			BAA_phase <= BA_phase(BAA_order-1 downto 0);
			BA_bitPermOut <= BA_bitPermIn;
			BA_tw: entity twiddleGenerator4 port map(clk, BA_twAddr, BA_twData);

				-- ====== FFT instance 'BAA' (N=2) ======
				BAA_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
					port map(clk=>clk, din=>BAA_in, phase=>BAA_phase, dout=>BAA_out);

				-- ====== FFT instance 'BAB' (N=2) ======
				BAB_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
					port map(clk=>clk, din=>BAB_in, phase=>BAB_phase, dout=>BAB_out);

			-- ====== FFT instance 'BB' (N=4) ======
			BB_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>BB_twiddleBits,
					subOrder1=>BBA_order,
					subOrder2=>BBB_order,
					twiddleDelay=>BB_twiddleDelay,
					subDelay1=>BBA_delay,
					subDelay2=>6,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>BB_phase, phaseOut=>open,
					subOut1=>BBA_out,
					subIn2=>BBB_in,
					subPhase2=>BBB_phase,
					twAddr=>BB_twAddr, twData=>BB_twData,
					bitPermIn=>BB_bitPermIn, bitPermOut=>BB_bitPermOut);
				
			BBA_in <= BB_in;
			BB_out <= BBB_out;
			BBA_phase <= BB_phase(BBA_order-1 downto 0);
			BB_bitPermOut <= BB_bitPermIn;
			BB_tw: entity twiddleGenerator4 port map(clk, BB_twAddr, BB_twData);

				-- ====== FFT instance 'BBA' (N=2) ======
				BBA_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
					port map(clk=>clk, din=>BBA_in, phase=>BBA_phase, dout=>BBA_out);

				-- ====== FFT instance 'BBB' (N=2) ======
				BBB_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
					port map(clk=>clk, din=>BBB_in, phase=>BBB_phase, dout=>BBB_out);
end ar;

