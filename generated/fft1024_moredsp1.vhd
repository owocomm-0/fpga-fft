-- instance name: fft1024_moredsp1

-- layout:
--1024: twiddleBits=16, delay=1282
--	64: twiddleBits=12, delay=166
--		16: twiddleBits=12, delay=70
--			4: twiddleBits=12, delay=22
--				2: base, 'fft2_serial', scale='SCALE_NONE', delay=6
--				2: base, 'fft2_serial', scale='SCALE_NONE', delay=6
--			4: twiddleBits=12, delay=22
--				2: base, 'fft2_serial', scale='SCALE_NONE', delay=6
--				2: base, 'fft2_serial', scale='SCALE_NONE', delay=6
--		4: twiddleBits=12, delay=22
--			2: base, 'fft2_serial', scale='SCALE_NONE', delay=6
--			2: base, 'fft2_serial', scale='SCALE_DIV_N', delay=6
--	16: twiddleBits=12, delay=70
--		4: twiddleBits=12, delay=22
--			2: base, 'fft2_serial', scale='SCALE_DIV_N', delay=6
--			2: base, 'fft2_serial', scale='SCALE_DIV_N', delay=6
--		4: twiddleBits=12, delay=22
--			2: base, 'fft2_serial', scale='SCALE_DIV_N', delay=6
--			2: base, 'fft2_serial', scale='SCALE_DIV_N', delay=6



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
use work.twiddleRom64;
use work.twiddleGenerator16;
use work.twiddleGenerator4;
use work.fft2_serial;

-- data input bit order: (9 downto 0) [0,1,3,2,5,4,9,8,7,6]
-- data output bit order: (9 downto 0) [0,1,2,3,4,5,6,7,8,9]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 1282
entity fft1024_moredsp1 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(10-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_moredsp1 is
	-- ====== FFT instance 'top' (N=1024) ======
	constant top_N: integer := 1024;
	constant top_twiddleBits: integer := 16;
	constant top_twiddleDelay: integer := 7;
	constant top_order: integer := 10;
	constant top_delay: integer := 1282;

		-- ====== FFT instance 'A' (N=64) ======
		constant A_N: integer := 64;
		constant A_twiddleBits: integer := 12;
		constant A_twiddleDelay: integer := 7;
		constant A_order: integer := 6;
		constant A_delay: integer := 166;

			-- ====== FFT instance 'AA' (N=16) ======
			constant AA_N: integer := 16;
			constant AA_twiddleBits: integer := 12;
			constant AA_twiddleDelay: integer := 2;
			constant AA_order: integer := 4;
			constant AA_delay: integer := 70;

				-- ====== FFT instance 'AAA' (N=4) ======
				constant AAA_N: integer := 4;
				constant AAA_twiddleBits: integer := 12;
				constant AAA_twiddleDelay: integer := 2;
				constant AAA_order: integer := 2;
				constant AAA_delay: integer := 22;

					-- ====== FFT instance 'AAAA' (N=2) ======
					constant AAAA_N: integer := 2;
					constant AAAA_order: integer := 1;
					constant AAAA_delay: integer := 6;

					-- ====== FFT instance 'AAAB' (N=2) ======
					constant AAAB_N: integer := 2;
					constant AAAB_order: integer := 1;
					constant AAAB_delay: integer := 6;

				-- ====== FFT instance 'AAB' (N=4) ======
				constant AAB_N: integer := 4;
				constant AAB_twiddleBits: integer := 12;
				constant AAB_twiddleDelay: integer := 2;
				constant AAB_order: integer := 2;
				constant AAB_delay: integer := 22;

					-- ====== FFT instance 'AABA' (N=2) ======
					constant AABA_N: integer := 2;
					constant AABA_order: integer := 1;
					constant AABA_delay: integer := 6;

					-- ====== FFT instance 'AABB' (N=2) ======
					constant AABB_N: integer := 2;
					constant AABB_order: integer := 1;
					constant AABB_delay: integer := 6;

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

	-- ====== FFT instance 'top' (N=1024) ======
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

		-- ====== FFT instance 'A' (N=64) ======
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

			-- ====== FFT instance 'AA' (N=16) ======
			signal AA_in, AA_out, AA_rbIn: complex;
			signal AA_phase: unsigned(AA_order-1 downto 0);
			signal AA_bitPermIn,AA_bitPermOut: unsigned(AAA_order-1 downto 0);
			-- twiddle generator
			signal AA_twAddr: unsigned(AA_order-1 downto 0);
			signal AA_twData: complex;
			signal AA_romAddr: unsigned(AA_order-4 downto 0);
			signal AA_romData: std_logic_vector(AA_twiddleBits*2-3 downto 0);
			signal AA_rP0: unsigned(2-1 downto 0);
			signal AA_rP1: unsigned(2-1 downto 0);
			signal AA_rCnt: unsigned(1-1 downto 0);
			signal AA_rbInPhase: unsigned(AAB_order-1 downto 0);

				-- ====== FFT instance 'AAA' (N=4) ======
				signal AAA_in, AAA_out, AAA_rbIn: complex;
				signal AAA_phase: unsigned(AAA_order-1 downto 0);
				signal AAA_bitPermIn,AAA_bitPermOut: unsigned(AAAA_order-1 downto 0);
				-- twiddle generator
				signal AAA_twAddr: unsigned(AAA_order-1 downto 0);
				signal AAA_twData: complex;
				signal AAA_romAddr: unsigned(AAA_order-4 downto 0);
				signal AAA_romData: std_logic_vector(AAA_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'AAAA' (N=2) ======
					signal AAAA_in, AAAA_out: complex;
					signal AAAA_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'AAAB' (N=2) ======
					signal AAAB_in, AAAB_out: complex;
					signal AAAB_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'AAB' (N=4) ======
				signal AAB_in, AAB_out, AAB_rbIn: complex;
				signal AAB_phase: unsigned(AAB_order-1 downto 0);
				signal AAB_bitPermIn,AAB_bitPermOut: unsigned(AABA_order-1 downto 0);
				-- twiddle generator
				signal AAB_twAddr: unsigned(AAB_order-1 downto 0);
				signal AAB_twData: complex;
				signal AAB_romAddr: unsigned(AAB_order-4 downto 0);
				signal AAB_romData: std_logic_vector(AAB_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'AABA' (N=2) ======
					signal AABA_in, AABA_out: complex;
					signal AABA_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'AABB' (N=2) ======
					signal AABB_in, AABB_out: complex;
					signal AABB_phase: unsigned(1-1 downto 0);

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
	-- ====== FFT instance 'top' (N=1024) ======
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
	top_bitPermOut <= top_bitPermIn(0)&top_bitPermIn(1)&top_bitPermIn(2)&top_bitPermIn(3)&top_bitPermIn(4)&top_bitPermIn(5);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom1024 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(0)&top_rP0(1)&top_rP0(3)&top_rP0(2) when top_rCnt(0)='1' else top_rP0;
	top_rP2 <= top_rP1(2)&top_rP1(3)&top_rP1(0)&top_rP1(1) when top_rCnt(1)='1' else top_rP1;
		
	top_rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>top_rbIn, phase=>top_rbInPhase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP2);
		
	B_phase <= top_rbInPhase-0;

		-- ====== FFT instance 'A' (N=64) ======
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
		A_bitPermOut <= A_bitPermIn(0)&A_bitPermIn(1)&A_bitPermIn(2)&A_bitPermIn(3);
		A_tw: entity twiddleGenerator generic map(A_twiddleBits, A_order)
			port map(clk, A_twAddr, A_twData, A_romAddr, A_romData);
		A_rom: entity twiddleRom64 port map(clk, A_romAddr,A_romData);
		A_rP1 <= A_rP0(0)&A_rP0(1) when A_rCnt(0)='1' else A_rP0;
			
		A_rb: entity reorderBuffer
			generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>A_rbIn, phase=>A_rbInPhase, dout=>AB_in,
				bitPermIn=>A_rP0, bitPermCount=>A_rCnt, bitPermOut=>A_rP1);
			
		AB_phase <= A_rbInPhase-0;

			-- ====== FFT instance 'AA' (N=16) ======
			AA_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>AA_twiddleBits,
					subOrder1=>AAA_order,
					subOrder2=>AAB_order,
					twiddleDelay=>AA_twiddleDelay,
					subDelay1=>AAA_delay,
					subDelay2=>26,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>AA_phase, phaseOut=>open,
					subOut1=>AAA_out,
					subIn2=>AA_rbIn,
					subPhase2=>AA_rbInPhase,
					twAddr=>AA_twAddr, twData=>AA_twData,
					bitPermIn=>AA_bitPermIn, bitPermOut=>AA_bitPermOut);
				
			AAA_in <= AA_in;
			AA_out <= AAB_out;
			AAA_phase <= AA_phase(AAA_order-1 downto 0);
			AA_bitPermOut <= AA_bitPermIn(0)&AA_bitPermIn(1);
			AA_tw: entity twiddleGenerator16 port map(clk, AA_twAddr, AA_twData);
			AA_rP1 <= AA_rP0(0)&AA_rP0(1) when AA_rCnt(0)='1' else AA_rP0;
				
			AA_rb: entity reorderBuffer
				generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
				port map(clk, din=>AA_rbIn, phase=>AA_rbInPhase, dout=>AAB_in,
					bitPermIn=>AA_rP0, bitPermCount=>AA_rCnt, bitPermOut=>AA_rP1);
				
			AAB_phase <= AA_rbInPhase-0;

				-- ====== FFT instance 'AAA' (N=4) ======
				AAA_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>AAA_twiddleBits,
						subOrder1=>AAAA_order,
						subOrder2=>AAAB_order,
						twiddleDelay=>AAA_twiddleDelay,
						subDelay1=>AAAA_delay,
						subDelay2=>6,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>AAA_phase, phaseOut=>open,
						subOut1=>AAAA_out,
						subIn2=>AAAB_in,
						subPhase2=>AAAB_phase,
						twAddr=>AAA_twAddr, twData=>AAA_twData,
						bitPermIn=>AAA_bitPermIn, bitPermOut=>AAA_bitPermOut);
					
				AAAA_in <= AAA_in;
				AAA_out <= AAAB_out;
				AAAA_phase <= AAA_phase(AAAA_order-1 downto 0);
				AAA_bitPermOut <= AAA_bitPermIn;
				AAA_tw: entity twiddleGenerator4 port map(clk, AAA_twAddr, AAA_twData);

					-- ====== FFT instance 'AAAA' (N=2) ======
					AAAA_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>AAAA_in, phase=>AAAA_phase, dout=>AAAA_out);

					-- ====== FFT instance 'AAAB' (N=2) ======
					AAAB_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>AAAB_in, phase=>AAAB_phase, dout=>AAAB_out);

				-- ====== FFT instance 'AAB' (N=4) ======
				AAB_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>AAB_twiddleBits,
						subOrder1=>AABA_order,
						subOrder2=>AABB_order,
						twiddleDelay=>AAB_twiddleDelay,
						subDelay1=>AABA_delay,
						subDelay2=>6,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>AAB_phase, phaseOut=>open,
						subOut1=>AABA_out,
						subIn2=>AABB_in,
						subPhase2=>AABB_phase,
						twAddr=>AAB_twAddr, twData=>AAB_twData,
						bitPermIn=>AAB_bitPermIn, bitPermOut=>AAB_bitPermOut);
					
				AABA_in <= AAB_in;
				AAB_out <= AABB_out;
				AABA_phase <= AAB_phase(AABA_order-1 downto 0);
				AAB_bitPermOut <= AAB_bitPermIn;
				AAB_tw: entity twiddleGenerator4 port map(clk, AAB_twAddr, AAB_twData);

					-- ====== FFT instance 'AABA' (N=2) ======
					AABA_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>AABA_in, phase=>AABA_phase, dout=>AABA_out);

					-- ====== FFT instance 'AABB' (N=2) ======
					AABB_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>AABB_in, phase=>AABB_phase, dout=>AABB_out);

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
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
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


-- instantiation (python):

--FFTConfiguration(1024, 
--	FFTConfiguration(64, 
--		FFTConfiguration(16, 
--			FFTConfiguration(4, 
--				FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6),
--				FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6),
--			twiddleBits=12),
--			FFTConfiguration(4, 
--				FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6),
--				FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6),
--			twiddleBits=12),
--		twiddleBits=12),
--		FFTConfiguration(4, 
--			FFTBase(2, 'fft2_serial', 'SCALE_NONE', 6),
--			FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6),
--		twiddleBits=12),
--	twiddleBits=12),
--	FFTConfiguration(16, 
--		FFTConfiguration(4, 
--			FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6),
--			FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6),
--		twiddleBits=12),
--		FFTConfiguration(4, 
--			FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6),
--			FFTBase(2, 'fft2_serial', 'SCALE_DIV_N', 6),
--		twiddleBits=12),
--	twiddleBits=12),
--twiddleBits=16)
