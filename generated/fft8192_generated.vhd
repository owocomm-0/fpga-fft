
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
use work.twiddleRom8192;
use work.twiddleRom128;
use work.twiddleGenerator16;
use work.twiddleGenerator4;
use work.fft2_serial;
use work.fft4_serial3;
use work.twiddleGenerator8;
use work.twiddleRom64;

-- data input bit order: (12 downto 0) [0,1,3,2,6,5,4,12,11,10,9,8,7]
-- data output bit order: (12 downto 0) [0,1,2,3,5,4,6,7,8,10,9,11,12]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 8656
entity fft8192_generated is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(13-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft8192_generated is
	-- ====== FFT instance 'top' (N=8192) ======
	constant top_N: integer := 8192;
	constant top_twiddleBits: integer := 16;
	constant top_twiddleDelay: integer := 7;
	constant top_order: integer := 13;
	constant top_delay: integer := 8656;

		-- ====== FFT instance 'A' (N=128) ======
		constant A_N: integer := 128;
		constant A_twiddleBits: integer := 12;
		constant A_twiddleDelay: integer := 7;
		constant A_order: integer := 7;
		constant A_delay: integer := 239;

			-- ====== FFT instance 'AA' (N=16) ======
			constant AA_N: integer := 16;
			constant AA_twiddleBits: integer := 12;
			constant AA_twiddleDelay: integer := 2;
			constant AA_order: integer := 4;
			constant AA_delay: integer := 55;

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
				constant AAB_order: integer := 2;
				constant AAB_delay: integer := 11;

			-- ====== FFT instance 'AB' (N=8) ======
			constant AB_N: integer := 8;
			constant AB_twiddleBits: integer := 12;
			constant AB_twiddleDelay: integer := 2;
			constant AB_order: integer := 3;
			constant AB_delay: integer := 42;

				-- ====== FFT instance 'ABA' (N=4) ======
				constant ABA_N: integer := 4;
				constant ABA_twiddleBits: integer := 12;
				constant ABA_twiddleDelay: integer := 2;
				constant ABA_order: integer := 2;
				constant ABA_delay: integer := 22;

					-- ====== FFT instance 'ABAA' (N=2) ======
					constant ABAA_N: integer := 2;
					constant ABAA_order: integer := 1;
					constant ABAA_delay: integer := 6;

					-- ====== FFT instance 'ABAB' (N=2) ======
					constant ABAB_N: integer := 2;
					constant ABAB_order: integer := 1;
					constant ABAB_delay: integer := 6;

				-- ====== FFT instance 'ABB' (N=2) ======
				constant ABB_N: integer := 2;
				constant ABB_order: integer := 1;
				constant ABB_delay: integer := 6;

		-- ====== FFT instance 'B' (N=64) ======
		constant B_N: integer := 64;
		constant B_twiddleBits: integer := 12;
		constant B_twiddleDelay: integer := 7;
		constant B_order: integer := 6;
		constant B_delay: integer := 155;

			-- ====== FFT instance 'BA' (N=16) ======
			constant BA_N: integer := 16;
			constant BA_twiddleBits: integer := 12;
			constant BA_twiddleDelay: integer := 2;
			constant BA_order: integer := 4;
			constant BA_delay: integer := 59;

				-- ====== FFT instance 'BAA' (N=4) ======
				constant BAA_N: integer := 4;
				constant BAA_order: integer := 2;
				constant BAA_delay: integer := 11;

				-- ====== FFT instance 'BAB' (N=4) ======
				constant BAB_N: integer := 4;
				constant BAB_twiddleBits: integer := 12;
				constant BAB_twiddleDelay: integer := 2;
				constant BAB_order: integer := 2;
				constant BAB_delay: integer := 22;

					-- ====== FFT instance 'BABA' (N=2) ======
					constant BABA_N: integer := 2;
					constant BABA_order: integer := 1;
					constant BABA_delay: integer := 6;

					-- ====== FFT instance 'BABB' (N=2) ======
					constant BABB_N: integer := 2;
					constant BABB_order: integer := 1;
					constant BABB_delay: integer := 6;

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

	-- ====== FFT instance 'top' (N=8192) ======
	signal top_in, top_out, top_rbIn: complex;
	signal top_phase: unsigned(top_order-1 downto 0);
	signal top_bitPermIn,top_bitPermOut: unsigned(A_order-1 downto 0);
	-- twiddle generator
	signal top_twAddr: unsigned(top_order-1 downto 0);
	signal top_twData: complex;
	signal top_romAddr: unsigned(top_order-4 downto 0);
	signal top_romData: std_logic_vector(top_twiddleBits*2-3 downto 0);
	signal top_rP0: unsigned(6-1 downto 0);
	signal top_rP1: unsigned(6-1 downto 0);
	signal top_rP2: unsigned(6-1 downto 0);
	signal top_rP3: unsigned(6-1 downto 0);
	signal top_rCnt: unsigned(3-1 downto 0);
	signal top_rbInPhase: unsigned(B_order-1 downto 0);

		-- ====== FFT instance 'A' (N=128) ======
		signal A_in, A_out, A_rbIn: complex;
		signal A_phase: unsigned(A_order-1 downto 0);
		signal A_bitPermIn,A_bitPermOut: unsigned(AA_order-1 downto 0);
		-- twiddle generator
		signal A_twAddr: unsigned(A_order-1 downto 0);
		signal A_twData: complex;
		signal A_romAddr: unsigned(A_order-4 downto 0);
		signal A_romData: std_logic_vector(A_twiddleBits*2-3 downto 0);
		signal A_rP0: unsigned(3-1 downto 0);
		signal A_rP1: unsigned(3-1 downto 0);
		signal A_rP2: unsigned(3-1 downto 0);
		signal A_rCnt: unsigned(2-1 downto 0);
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
				signal AAB_in, AAB_out: complex;
				signal AAB_phase: unsigned(2-1 downto 0);

			-- ====== FFT instance 'AB' (N=8) ======
			signal AB_in, AB_out, AB_rbIn: complex;
			signal AB_phase: unsigned(AB_order-1 downto 0);
			signal AB_bitPermIn,AB_bitPermOut: unsigned(ABA_order-1 downto 0);
			-- twiddle generator
			signal AB_twAddr: unsigned(AB_order-1 downto 0);
			signal AB_twData: complex;
			signal AB_romAddr: unsigned(AB_order-4 downto 0);
			signal AB_romData: std_logic_vector(AB_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'ABA' (N=4) ======
				signal ABA_in, ABA_out, ABA_rbIn: complex;
				signal ABA_phase: unsigned(ABA_order-1 downto 0);
				signal ABA_bitPermIn,ABA_bitPermOut: unsigned(ABAA_order-1 downto 0);
				-- twiddle generator
				signal ABA_twAddr: unsigned(ABA_order-1 downto 0);
				signal ABA_twData: complex;
				signal ABA_romAddr: unsigned(ABA_order-4 downto 0);
				signal ABA_romData: std_logic_vector(ABA_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'ABAA' (N=2) ======
					signal ABAA_in, ABAA_out: complex;
					signal ABAA_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'ABAB' (N=2) ======
					signal ABAB_in, ABAB_out: complex;
					signal ABAB_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'ABB' (N=2) ======
				signal ABB_in, ABB_out: complex;
				signal ABB_phase: unsigned(1-1 downto 0);

		-- ====== FFT instance 'B' (N=64) ======
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

			-- ====== FFT instance 'BA' (N=16) ======
			signal BA_in, BA_out, BA_rbIn: complex;
			signal BA_phase: unsigned(BA_order-1 downto 0);
			signal BA_bitPermIn,BA_bitPermOut: unsigned(BAA_order-1 downto 0);
			-- twiddle generator
			signal BA_twAddr: unsigned(BA_order-1 downto 0);
			signal BA_twData: complex;
			signal BA_romAddr: unsigned(BA_order-4 downto 0);
			signal BA_romData: std_logic_vector(BA_twiddleBits*2-3 downto 0);
			signal BA_rP0: unsigned(2-1 downto 0);
			signal BA_rP1: unsigned(2-1 downto 0);
			signal BA_rCnt: unsigned(1-1 downto 0);
			signal BA_rbInPhase: unsigned(BAB_order-1 downto 0);

				-- ====== FFT instance 'BAA' (N=4) ======
				signal BAA_in, BAA_out: complex;
				signal BAA_phase: unsigned(2-1 downto 0);

				-- ====== FFT instance 'BAB' (N=4) ======
				signal BAB_in, BAB_out, BAB_rbIn: complex;
				signal BAB_phase: unsigned(BAB_order-1 downto 0);
				signal BAB_bitPermIn,BAB_bitPermOut: unsigned(BABA_order-1 downto 0);
				-- twiddle generator
				signal BAB_twAddr: unsigned(BAB_order-1 downto 0);
				signal BAB_twData: complex;
				signal BAB_romAddr: unsigned(BAB_order-4 downto 0);
				signal BAB_romData: std_logic_vector(BAB_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'BABA' (N=2) ======
					signal BABA_in, BABA_out: complex;
					signal BABA_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'BABB' (N=2) ======
					signal BABB_in, BABB_out: complex;
					signal BABB_phase: unsigned(1-1 downto 0);

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
	-- ====== FFT instance 'top' (N=8192) ======
	top_core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>top_twiddleBits,
			subOrder1=>A_order,
			subOrder2=>B_order,
			twiddleDelay=>top_twiddleDelay,
			subDelay1=>A_delay,
			subDelay2=>219,
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
	top_bitPermOut <= top_bitPermIn(0)&top_bitPermIn(1)&top_bitPermIn(2)&top_bitPermIn(4)&top_bitPermIn(3)&top_bitPermIn(5)&top_bitPermIn(6);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom8192 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(1)&top_rP0(0)&top_rP0(3)&top_rP0(2)&top_rP0(5)&top_rP0(4) when top_rCnt(0)='1' else top_rP0;
	top_rP2 <= top_rP1 when top_rCnt(1)='1' else top_rP1;
	top_rP3 <= top_rP2 when top_rCnt(2)='1' else top_rP2;
		
	top_rb: entity reorderBuffer
		generic map(N=>6, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>top_rbIn, phase=>top_rbInPhase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP3);
		
	B_phase <= top_rbInPhase-0;

		-- ====== FFT instance 'A' (N=128) ======
		A_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>A_twiddleBits,
				subOrder1=>AA_order,
				subOrder2=>AB_order,
				twiddleDelay=>A_twiddleDelay,
				subDelay1=>AA_delay,
				subDelay2=>50,
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
		A_bitPermOut <= A_bitPermIn(1)&A_bitPermIn(0)&A_bitPermIn(2)&A_bitPermIn(3);
		A_tw: entity twiddleGenerator generic map(A_twiddleBits, A_order)
			port map(clk, A_twAddr, A_twData, A_romAddr, A_romData);
		A_rom: entity twiddleRom128 port map(clk, A_romAddr,A_romData);
		A_rP1 <= A_rP0(0)&A_rP0(1)&A_rP0(2) when A_rCnt(0)='1' else A_rP0;
		A_rP2 <= A_rP1 when A_rCnt(1)='1' else A_rP1;
			
		A_rb: entity reorderBuffer
			generic map(N=>3, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>A_rbIn, phase=>A_rbInPhase, dout=>AB_in,
				bitPermIn=>A_rP0, bitPermCount=>A_rCnt, bitPermOut=>A_rP2);
			
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
					subDelay2=>11,
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
			AA_bitPermOut <= AA_bitPermIn(0)&AA_bitPermIn(1);
			AA_tw: entity twiddleGenerator16 port map(clk, AA_twAddr, AA_twData);

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
				AAB_inst: entity fft4_serial3
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>AAB_in, phase=>AAB_phase, dout=>AAB_out);

			-- ====== FFT instance 'AB' (N=8) ======
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
			AB_bitPermOut <= AB_bitPermIn(0)&AB_bitPermIn(1);
			AB_tw: entity twiddleGenerator8 port map(clk, AB_twAddr, AB_twData);

				-- ====== FFT instance 'ABA' (N=4) ======
				ABA_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>ABA_twiddleBits,
						subOrder1=>ABAA_order,
						subOrder2=>ABAB_order,
						twiddleDelay=>ABA_twiddleDelay,
						subDelay1=>ABAA_delay,
						subDelay2=>6,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>ABA_phase, phaseOut=>open,
						subOut1=>ABAA_out,
						subIn2=>ABAB_in,
						subPhase2=>ABAB_phase,
						twAddr=>ABA_twAddr, twData=>ABA_twData,
						bitPermIn=>ABA_bitPermIn, bitPermOut=>ABA_bitPermOut);
					
				ABAA_in <= ABA_in;
				ABA_out <= ABAB_out;
				ABAA_phase <= ABA_phase(ABAA_order-1 downto 0);
				ABA_bitPermOut <= ABA_bitPermIn;
				ABA_tw: entity twiddleGenerator4 port map(clk, ABA_twAddr, ABA_twData);

					-- ====== FFT instance 'ABAA' (N=2) ======
					ABAA_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>ABAA_in, phase=>ABAA_phase, dout=>ABAA_out);

					-- ====== FFT instance 'ABAB' (N=2) ======
					ABAB_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_NONE)
						port map(clk=>clk, din=>ABAB_in, phase=>ABAB_phase, dout=>ABAB_out);

				-- ====== FFT instance 'ABB' (N=2) ======
				ABB_inst: entity fft2_serial
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
					port map(clk=>clk, din=>ABB_in, phase=>ABB_phase, dout=>ABB_out);

		-- ====== FFT instance 'B' (N=64) ======
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
		B_bitPermOut <= B_bitPermIn(0)&B_bitPermIn(1)&B_bitPermIn(3)&B_bitPermIn(2);
		B_tw: entity twiddleGenerator generic map(B_twiddleBits, B_order)
			port map(clk, B_twAddr, B_twData, B_romAddr, B_romData);
		B_rom: entity twiddleRom64 port map(clk, B_romAddr,B_romData);
		B_rP1 <= B_rP0(0)&B_rP0(1) when B_rCnt(0)='1' else B_rP0;
			
		B_rb: entity reorderBuffer
			generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>B_rbIn, phase=>B_rbInPhase, dout=>BB_in,
				bitPermIn=>B_rP0, bitPermCount=>B_rCnt, bitPermOut=>B_rP1);
			
		BB_phase <= B_rbInPhase-0;

			-- ====== FFT instance 'BA' (N=16) ======
			BA_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>BA_twiddleBits,
					subOrder1=>BAA_order,
					subOrder2=>BAB_order,
					twiddleDelay=>BA_twiddleDelay,
					subDelay1=>BAA_delay,
					subDelay2=>26,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>BA_phase, phaseOut=>open,
					subOut1=>BAA_out,
					subIn2=>BA_rbIn,
					subPhase2=>BA_rbInPhase,
					twAddr=>BA_twAddr, twData=>BA_twData,
					bitPermIn=>BA_bitPermIn, bitPermOut=>BA_bitPermOut);
				
			BAA_in <= BA_in;
			BA_out <= BAB_out;
			BAA_phase <= BA_phase(BAA_order-1 downto 0);
			BA_bitPermOut <= BA_bitPermIn;
			BA_tw: entity twiddleGenerator16 port map(clk, BA_twAddr, BA_twData);
			BA_rP1 <= BA_rP0(0)&BA_rP0(1) when BA_rCnt(0)='1' else BA_rP0;
				
			BA_rb: entity reorderBuffer
				generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
				port map(clk, din=>BA_rbIn, phase=>BA_rbInPhase, dout=>BAB_in,
					bitPermIn=>BA_rP0, bitPermCount=>BA_rCnt, bitPermOut=>BA_rP1);
				
			BAB_phase <= BA_rbInPhase-0;

				-- ====== FFT instance 'BAA' (N=4) ======
				BAA_inst: entity fft4_serial3
					generic map(dataBits=>dataBits, scale=>SCALE_DIV_SQRT_N)
					port map(clk=>clk, din=>BAA_in, phase=>BAA_phase, dout=>BAA_out);

				-- ====== FFT instance 'BAB' (N=4) ======
				BAB_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>BAB_twiddleBits,
						subOrder1=>BABA_order,
						subOrder2=>BABB_order,
						twiddleDelay=>BAB_twiddleDelay,
						subDelay1=>BABA_delay,
						subDelay2=>6,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>BAB_phase, phaseOut=>open,
						subOut1=>BABA_out,
						subIn2=>BABB_in,
						subPhase2=>BABB_phase,
						twAddr=>BAB_twAddr, twData=>BAB_twData,
						bitPermIn=>BAB_bitPermIn, bitPermOut=>BAB_bitPermOut);
					
				BABA_in <= BAB_in;
				BAB_out <= BABB_out;
				BABA_phase <= BAB_phase(BABA_order-1 downto 0);
				BAB_bitPermOut <= BAB_bitPermIn;
				BAB_tw: entity twiddleGenerator4 port map(clk, BAB_twAddr, BAB_twData);

					-- ====== FFT instance 'BABA' (N=2) ======
					BABA_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
						port map(clk=>clk, din=>BABA_in, phase=>BABA_phase, dout=>BABA_out);

					-- ====== FFT instance 'BABB' (N=2) ======
					BABB_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
						port map(clk=>clk, din=>BABB_in, phase=>BABB_phase, dout=>BABB_out);

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

