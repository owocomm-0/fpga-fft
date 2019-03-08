
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
use work.twiddleRom16384;
use work.twiddleRom4096;
use work.twiddleRom64;
use work.twiddleGenerator16;
use work.twiddleGenerator4;
use work.fft2_serial;
use work.fft4_serial3;

-- data input bit order: (13 downto 0) [0,1,3,2,5,4,11,10,9,8,7,6,13,12]
-- data output bit order: (13 downto 0) [0,1,2,3,4,5,7,6,8,9,11,10,12,13]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 20888
entity fft16384_generated is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(14-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft16384_generated is
	-- ====== FFT instance 'top' (N=16384) ======
	constant top_N: integer := 16384;
	constant top_twiddleBits: integer := 16;
	constant top_twiddleDelay: integer := 7;
	constant top_order: integer := 14;
	constant top_delay: integer := 20888;

		-- ====== FFT instance 'A' (N=4096) ======
		constant A_N: integer := 4096;
		constant A_twiddleBits: integer := 16;
		constant A_twiddleDelay: integer := 7;
		constant A_order: integer := 12;
		constant A_delay: integer := 4472;

			-- ====== FFT instance 'AA' (N=64) ======
			constant AA_N: integer := 64;
			constant AA_twiddleBits: integer := 12;
			constant AA_twiddleDelay: integer := 7;
			constant AA_order: integer := 6;
			constant AA_delay: integer := 151;

				-- ====== FFT instance 'AAA' (N=16) ======
				constant AAA_N: integer := 16;
				constant AAA_twiddleBits: integer := 12;
				constant AAA_twiddleDelay: integer := 2;
				constant AAA_order: integer := 4;
				constant AAA_delay: integer := 55;

					-- ====== FFT instance 'AAAA' (N=4) ======
					constant AAAA_N: integer := 4;
					constant AAAA_twiddleBits: integer := 12;
					constant AAAA_twiddleDelay: integer := 2;
					constant AAAA_order: integer := 2;
					constant AAAA_delay: integer := 22;

						-- ====== FFT instance 'AAAAA' (N=2) ======
						constant AAAAA_N: integer := 2;
						constant AAAAA_order: integer := 1;
						constant AAAAA_delay: integer := 6;

						-- ====== FFT instance 'AAAAB' (N=2) ======
						constant AAAAB_N: integer := 2;
						constant AAAAB_order: integer := 1;
						constant AAAAB_delay: integer := 6;

					-- ====== FFT instance 'AAAB' (N=4) ======
					constant AAAB_N: integer := 4;
					constant AAAB_order: integer := 2;
					constant AAAB_delay: integer := 11;

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

			-- ====== FFT instance 'AB' (N=64) ======
			constant AB_N: integer := 64;
			constant AB_twiddleBits: integer := 12;
			constant AB_twiddleDelay: integer := 7;
			constant AB_order: integer := 6;
			constant AB_delay: integer := 155;

				-- ====== FFT instance 'ABA' (N=16) ======
				constant ABA_N: integer := 16;
				constant ABA_twiddleBits: integer := 12;
				constant ABA_twiddleDelay: integer := 2;
				constant ABA_order: integer := 4;
				constant ABA_delay: integer := 59;

					-- ====== FFT instance 'ABAA' (N=4) ======
					constant ABAA_N: integer := 4;
					constant ABAA_order: integer := 2;
					constant ABAA_delay: integer := 11;

					-- ====== FFT instance 'ABAB' (N=4) ======
					constant ABAB_N: integer := 4;
					constant ABAB_twiddleBits: integer := 12;
					constant ABAB_twiddleDelay: integer := 2;
					constant ABAB_order: integer := 2;
					constant ABAB_delay: integer := 22;

						-- ====== FFT instance 'ABABA' (N=2) ======
						constant ABABA_N: integer := 2;
						constant ABABA_order: integer := 1;
						constant ABABA_delay: integer := 6;

						-- ====== FFT instance 'ABABB' (N=2) ======
						constant ABABB_N: integer := 2;
						constant ABABB_order: integer := 1;
						constant ABABB_delay: integer := 6;

				-- ====== FFT instance 'ABB' (N=4) ======
				constant ABB_N: integer := 4;
				constant ABB_twiddleBits: integer := 12;
				constant ABB_twiddleDelay: integer := 2;
				constant ABB_order: integer := 2;
				constant ABB_delay: integer := 22;

					-- ====== FFT instance 'ABBA' (N=2) ======
					constant ABBA_N: integer := 2;
					constant ABBA_order: integer := 1;
					constant ABBA_delay: integer := 6;

					-- ====== FFT instance 'ABBB' (N=2) ======
					constant ABBB_N: integer := 2;
					constant ABBB_order: integer := 1;
					constant ABBB_delay: integer := 6;

		-- ====== FFT instance 'B' (N=4) ======
		constant B_N: integer := 4;
		constant B_twiddleBits: integer := 12;
		constant B_twiddleDelay: integer := 2;
		constant B_order: integer := 2;
		constant B_delay: integer := 22;

			-- ====== FFT instance 'BA' (N=2) ======
			constant BA_N: integer := 2;
			constant BA_order: integer := 1;
			constant BA_delay: integer := 6;

			-- ====== FFT instance 'BB' (N=2) ======
			constant BB_N: integer := 2;
			constant BB_order: integer := 1;
			constant BB_delay: integer := 6;

	--=======================================

	-- ====== FFT instance 'top' (N=16384) ======
	signal top_in, top_out, top_rbIn: complex;
	signal top_phase: unsigned(top_order-1 downto 0);
	signal top_bitPermIn,top_bitPermOut: unsigned(A_order-1 downto 0);
	-- twiddle generator
	signal top_twAddr: unsigned(top_order-1 downto 0);
	signal top_twData: complex;
	signal top_romAddr: unsigned(top_order-4 downto 0);
	signal top_romData: std_logic_vector(top_twiddleBits*2-3 downto 0);
	signal top_rP0: unsigned(2-1 downto 0);
	signal top_rP1: unsigned(2-1 downto 0);
	signal top_rCnt: unsigned(1-1 downto 0);
	signal top_rbInPhase: unsigned(B_order-1 downto 0);

		-- ====== FFT instance 'A' (N=4096) ======
		signal A_in, A_out, A_rbIn: complex;
		signal A_phase: unsigned(A_order-1 downto 0);
		signal A_bitPermIn,A_bitPermOut: unsigned(AA_order-1 downto 0);
		-- twiddle generator
		signal A_twAddr: unsigned(A_order-1 downto 0);
		signal A_twData: complex;
		signal A_romAddr: unsigned(A_order-4 downto 0);
		signal A_romData: std_logic_vector(A_twiddleBits*2-3 downto 0);
		signal A_rP0: unsigned(6-1 downto 0);
		signal A_rP1: unsigned(6-1 downto 0);
		signal A_rP2: unsigned(6-1 downto 0);
		signal A_rP3: unsigned(6-1 downto 0);
		signal A_rCnt: unsigned(3-1 downto 0);
		signal A_rbInPhase: unsigned(AB_order-1 downto 0);

			-- ====== FFT instance 'AA' (N=64) ======
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

				-- ====== FFT instance 'AAA' (N=16) ======
				signal AAA_in, AAA_out, AAA_rbIn: complex;
				signal AAA_phase: unsigned(AAA_order-1 downto 0);
				signal AAA_bitPermIn,AAA_bitPermOut: unsigned(AAAA_order-1 downto 0);
				-- twiddle generator
				signal AAA_twAddr: unsigned(AAA_order-1 downto 0);
				signal AAA_twData: complex;
				signal AAA_romAddr: unsigned(AAA_order-4 downto 0);
				signal AAA_romData: std_logic_vector(AAA_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'AAAA' (N=4) ======
					signal AAAA_in, AAAA_out, AAAA_rbIn: complex;
					signal AAAA_phase: unsigned(AAAA_order-1 downto 0);
					signal AAAA_bitPermIn,AAAA_bitPermOut: unsigned(AAAAA_order-1 downto 0);
					-- twiddle generator
					signal AAAA_twAddr: unsigned(AAAA_order-1 downto 0);
					signal AAAA_twData: complex;
					signal AAAA_romAddr: unsigned(AAAA_order-4 downto 0);
					signal AAAA_romData: std_logic_vector(AAAA_twiddleBits*2-3 downto 0);

						-- ====== FFT instance 'AAAAA' (N=2) ======
						signal AAAAA_in, AAAAA_out: complex;
						signal AAAAA_phase: unsigned(1-1 downto 0);

						-- ====== FFT instance 'AAAAB' (N=2) ======
						signal AAAAB_in, AAAAB_out: complex;
						signal AAAAB_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'AAAB' (N=4) ======
					signal AAAB_in, AAAB_out: complex;
					signal AAAB_phase: unsigned(2-1 downto 0);

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

			-- ====== FFT instance 'AB' (N=64) ======
			signal AB_in, AB_out, AB_rbIn: complex;
			signal AB_phase: unsigned(AB_order-1 downto 0);
			signal AB_bitPermIn,AB_bitPermOut: unsigned(ABA_order-1 downto 0);
			-- twiddle generator
			signal AB_twAddr: unsigned(AB_order-1 downto 0);
			signal AB_twData: complex;
			signal AB_romAddr: unsigned(AB_order-4 downto 0);
			signal AB_romData: std_logic_vector(AB_twiddleBits*2-3 downto 0);
			signal AB_rP0: unsigned(2-1 downto 0);
			signal AB_rP1: unsigned(2-1 downto 0);
			signal AB_rCnt: unsigned(1-1 downto 0);
			signal AB_rbInPhase: unsigned(ABB_order-1 downto 0);

				-- ====== FFT instance 'ABA' (N=16) ======
				signal ABA_in, ABA_out, ABA_rbIn: complex;
				signal ABA_phase: unsigned(ABA_order-1 downto 0);
				signal ABA_bitPermIn,ABA_bitPermOut: unsigned(ABAA_order-1 downto 0);
				-- twiddle generator
				signal ABA_twAddr: unsigned(ABA_order-1 downto 0);
				signal ABA_twData: complex;
				signal ABA_romAddr: unsigned(ABA_order-4 downto 0);
				signal ABA_romData: std_logic_vector(ABA_twiddleBits*2-3 downto 0);
				signal ABA_rP0: unsigned(2-1 downto 0);
				signal ABA_rP1: unsigned(2-1 downto 0);
				signal ABA_rCnt: unsigned(1-1 downto 0);
				signal ABA_rbInPhase: unsigned(ABAB_order-1 downto 0);

					-- ====== FFT instance 'ABAA' (N=4) ======
					signal ABAA_in, ABAA_out: complex;
					signal ABAA_phase: unsigned(2-1 downto 0);

					-- ====== FFT instance 'ABAB' (N=4) ======
					signal ABAB_in, ABAB_out, ABAB_rbIn: complex;
					signal ABAB_phase: unsigned(ABAB_order-1 downto 0);
					signal ABAB_bitPermIn,ABAB_bitPermOut: unsigned(ABABA_order-1 downto 0);
					-- twiddle generator
					signal ABAB_twAddr: unsigned(ABAB_order-1 downto 0);
					signal ABAB_twData: complex;
					signal ABAB_romAddr: unsigned(ABAB_order-4 downto 0);
					signal ABAB_romData: std_logic_vector(ABAB_twiddleBits*2-3 downto 0);

						-- ====== FFT instance 'ABABA' (N=2) ======
						signal ABABA_in, ABABA_out: complex;
						signal ABABA_phase: unsigned(1-1 downto 0);

						-- ====== FFT instance 'ABABB' (N=2) ======
						signal ABABB_in, ABABB_out: complex;
						signal ABABB_phase: unsigned(1-1 downto 0);

				-- ====== FFT instance 'ABB' (N=4) ======
				signal ABB_in, ABB_out, ABB_rbIn: complex;
				signal ABB_phase: unsigned(ABB_order-1 downto 0);
				signal ABB_bitPermIn,ABB_bitPermOut: unsigned(ABBA_order-1 downto 0);
				-- twiddle generator
				signal ABB_twAddr: unsigned(ABB_order-1 downto 0);
				signal ABB_twData: complex;
				signal ABB_romAddr: unsigned(ABB_order-4 downto 0);
				signal ABB_romData: std_logic_vector(ABB_twiddleBits*2-3 downto 0);

					-- ====== FFT instance 'ABBA' (N=2) ======
					signal ABBA_in, ABBA_out: complex;
					signal ABBA_phase: unsigned(1-1 downto 0);

					-- ====== FFT instance 'ABBB' (N=2) ======
					signal ABBB_in, ABBB_out: complex;
					signal ABBB_phase: unsigned(1-1 downto 0);

		-- ====== FFT instance 'B' (N=4) ======
		signal B_in, B_out, B_rbIn: complex;
		signal B_phase: unsigned(B_order-1 downto 0);
		signal B_bitPermIn,B_bitPermOut: unsigned(BA_order-1 downto 0);
		-- twiddle generator
		signal B_twAddr: unsigned(B_order-1 downto 0);
		signal B_twData: complex;
		signal B_romAddr: unsigned(B_order-4 downto 0);
		signal B_romData: std_logic_vector(B_twiddleBits*2-3 downto 0);

			-- ====== FFT instance 'BA' (N=2) ======
			signal BA_in, BA_out: complex;
			signal BA_phase: unsigned(1-1 downto 0);

			-- ====== FFT instance 'BB' (N=2) ======
			signal BB_in, BB_out: complex;
			signal BB_phase: unsigned(1-1 downto 0);
begin
	top_in <= din;
	top_phase <= phase;
	dout <= top_out;
	-- ====== FFT instance 'top' (N=16384) ======
	top_core: entity fft3step_bram_generic3
		generic map(
			dataBits=>dataBits,
			twiddleBits=>top_twiddleBits,
			subOrder1=>A_order,
			subOrder2=>B_order,
			twiddleDelay=>top_twiddleDelay,
			subDelay1=>A_delay,
			subDelay2=>26,
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
	top_bitPermOut <= top_bitPermIn(0)&top_bitPermIn(1)&top_bitPermIn(2)&top_bitPermIn(3)&top_bitPermIn(5)&top_bitPermIn(4)&top_bitPermIn(6)&top_bitPermIn(7)&top_bitPermIn(9)&top_bitPermIn(8)&top_bitPermIn(10)&top_bitPermIn(11);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom16384 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(0)&top_rP0(1) when top_rCnt(0)='1' else top_rP0;
		
	top_rb: entity reorderBuffer
		generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk, din=>top_rbIn, phase=>top_rbInPhase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP1);
		
	B_phase <= top_rbInPhase-0;

		-- ====== FFT instance 'A' (N=4096) ======
		A_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>A_twiddleBits,
				subOrder1=>AA_order,
				subOrder2=>AB_order,
				twiddleDelay=>A_twiddleDelay,
				subDelay1=>AA_delay,
				subDelay2=>219,
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
		A_bitPermOut <= A_bitPermIn(0)&A_bitPermIn(1)&A_bitPermIn(3)&A_bitPermIn(2)&A_bitPermIn(4)&A_bitPermIn(5);
		A_tw: entity twiddleGenerator generic map(A_twiddleBits, A_order)
			port map(clk, A_twAddr, A_twData, A_romAddr, A_romData);
		A_rom: entity twiddleRom4096 port map(clk, A_romAddr,A_romData);
		A_rP1 <= A_rP0(1)&A_rP0(0)&A_rP0(3)&A_rP0(2)&A_rP0(5)&A_rP0(4) when A_rCnt(0)='1' else A_rP0;
		A_rP2 <= A_rP1 when A_rCnt(1)='1' else A_rP1;
		A_rP3 <= A_rP2 when A_rCnt(2)='1' else A_rP2;
			
		A_rb: entity reorderBuffer
			generic map(N=>6, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
			port map(clk, din=>A_rbIn, phase=>A_rbInPhase, dout=>AB_in,
				bitPermIn=>A_rP0, bitPermCount=>A_rCnt, bitPermOut=>A_rP3);
			
		AB_phase <= A_rbInPhase-0;

			-- ====== FFT instance 'AA' (N=64) ======
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
			AA_bitPermOut <= AA_bitPermIn(1)&AA_bitPermIn(0)&AA_bitPermIn(2)&AA_bitPermIn(3);
			AA_tw: entity twiddleGenerator generic map(AA_twiddleBits, AA_order)
				port map(clk, AA_twAddr, AA_twData, AA_romAddr, AA_romData);
			AA_rom: entity twiddleRom64 port map(clk, AA_romAddr,AA_romData);
			AA_rP1 <= AA_rP0(0)&AA_rP0(1) when AA_rCnt(0)='1' else AA_rP0;
				
			AA_rb: entity reorderBuffer
				generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
				port map(clk, din=>AA_rbIn, phase=>AA_rbInPhase, dout=>AAB_in,
					bitPermIn=>AA_rP0, bitPermCount=>AA_rCnt, bitPermOut=>AA_rP1);
				
			AAB_phase <= AA_rbInPhase-0;

				-- ====== FFT instance 'AAA' (N=16) ======
				AAA_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>AAA_twiddleBits,
						subOrder1=>AAAA_order,
						subOrder2=>AAAB_order,
						twiddleDelay=>AAA_twiddleDelay,
						subDelay1=>AAAA_delay,
						subDelay2=>11,
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
				AAA_bitPermOut <= AAA_bitPermIn(0)&AAA_bitPermIn(1);
				AAA_tw: entity twiddleGenerator16 port map(clk, AAA_twAddr, AAA_twData);

					-- ====== FFT instance 'AAAA' (N=4) ======
					AAAA_core: entity fft3step_bram_generic3
						generic map(
							dataBits=>dataBits,
							twiddleBits=>AAAA_twiddleBits,
							subOrder1=>AAAAA_order,
							subOrder2=>AAAAB_order,
							twiddleDelay=>AAAA_twiddleDelay,
							subDelay1=>AAAAA_delay,
							subDelay2=>6,
							customSubOrder=>true)
						port map(
							clk=>clk, phase=>AAAA_phase, phaseOut=>open,
							subOut1=>AAAAA_out,
							subIn2=>AAAAB_in,
							subPhase2=>AAAAB_phase,
							twAddr=>AAAA_twAddr, twData=>AAAA_twData,
							bitPermIn=>AAAA_bitPermIn, bitPermOut=>AAAA_bitPermOut);
						
					AAAAA_in <= AAAA_in;
					AAAA_out <= AAAAB_out;
					AAAAA_phase <= AAAA_phase(AAAAA_order-1 downto 0);
					AAAA_bitPermOut <= AAAA_bitPermIn;
					AAAA_tw: entity twiddleGenerator4 port map(clk, AAAA_twAddr, AAAA_twData);

						-- ====== FFT instance 'AAAAA' (N=2) ======
						AAAAA_inst: entity fft2_serial
							generic map(dataBits=>dataBits, scale=>SCALE_NONE)
							port map(clk=>clk, din=>AAAAA_in, phase=>AAAAA_phase, dout=>AAAAA_out);

						-- ====== FFT instance 'AAAAB' (N=2) ======
						AAAAB_inst: entity fft2_serial
							generic map(dataBits=>dataBits, scale=>SCALE_NONE)
							port map(clk=>clk, din=>AAAAB_in, phase=>AAAAB_phase, dout=>AAAAB_out);

					-- ====== FFT instance 'AAAB' (N=4) ======
					AAAB_inst: entity fft4_serial3
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

			-- ====== FFT instance 'AB' (N=64) ======
			AB_core: entity fft3step_bram_generic3
				generic map(
					dataBits=>dataBits,
					twiddleBits=>AB_twiddleBits,
					subOrder1=>ABA_order,
					subOrder2=>ABB_order,
					twiddleDelay=>AB_twiddleDelay,
					subDelay1=>ABA_delay,
					subDelay2=>26,
					customSubOrder=>true)
				port map(
					clk=>clk, phase=>AB_phase, phaseOut=>open,
					subOut1=>ABA_out,
					subIn2=>AB_rbIn,
					subPhase2=>AB_rbInPhase,
					twAddr=>AB_twAddr, twData=>AB_twData,
					bitPermIn=>AB_bitPermIn, bitPermOut=>AB_bitPermOut);
				
			ABA_in <= AB_in;
			AB_out <= ABB_out;
			ABA_phase <= AB_phase(ABA_order-1 downto 0);
			AB_bitPermOut <= AB_bitPermIn(0)&AB_bitPermIn(1)&AB_bitPermIn(3)&AB_bitPermIn(2);
			AB_tw: entity twiddleGenerator generic map(AB_twiddleBits, AB_order)
				port map(clk, AB_twAddr, AB_twData, AB_romAddr, AB_romData);
			AB_rom: entity twiddleRom64 port map(clk, AB_romAddr,AB_romData);
			AB_rP1 <= AB_rP0(0)&AB_rP0(1) when AB_rCnt(0)='1' else AB_rP0;
				
			AB_rb: entity reorderBuffer
				generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
				port map(clk, din=>AB_rbIn, phase=>AB_rbInPhase, dout=>ABB_in,
					bitPermIn=>AB_rP0, bitPermCount=>AB_rCnt, bitPermOut=>AB_rP1);
				
			ABB_phase <= AB_rbInPhase-0;

				-- ====== FFT instance 'ABA' (N=16) ======
				ABA_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>ABA_twiddleBits,
						subOrder1=>ABAA_order,
						subOrder2=>ABAB_order,
						twiddleDelay=>ABA_twiddleDelay,
						subDelay1=>ABAA_delay,
						subDelay2=>26,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>ABA_phase, phaseOut=>open,
						subOut1=>ABAA_out,
						subIn2=>ABA_rbIn,
						subPhase2=>ABA_rbInPhase,
						twAddr=>ABA_twAddr, twData=>ABA_twData,
						bitPermIn=>ABA_bitPermIn, bitPermOut=>ABA_bitPermOut);
					
				ABAA_in <= ABA_in;
				ABA_out <= ABAB_out;
				ABAA_phase <= ABA_phase(ABAA_order-1 downto 0);
				ABA_bitPermOut <= ABA_bitPermIn;
				ABA_tw: entity twiddleGenerator16 port map(clk, ABA_twAddr, ABA_twData);
				ABA_rP1 <= ABA_rP0(0)&ABA_rP0(1) when ABA_rCnt(0)='1' else ABA_rP0;
					
				ABA_rb: entity reorderBuffer
					generic map(N=>2, dataBits=>dataBits, bitPermDelay=>0, dataPathDelay=>0)
					port map(clk, din=>ABA_rbIn, phase=>ABA_rbInPhase, dout=>ABAB_in,
						bitPermIn=>ABA_rP0, bitPermCount=>ABA_rCnt, bitPermOut=>ABA_rP1);
					
				ABAB_phase <= ABA_rbInPhase-0;

					-- ====== FFT instance 'ABAA' (N=4) ======
					ABAA_inst: entity fft4_serial3
						generic map(dataBits=>dataBits, scale=>SCALE_DIV_SQRT_N)
						port map(clk=>clk, din=>ABAA_in, phase=>ABAA_phase, dout=>ABAA_out);

					-- ====== FFT instance 'ABAB' (N=4) ======
					ABAB_core: entity fft3step_bram_generic3
						generic map(
							dataBits=>dataBits,
							twiddleBits=>ABAB_twiddleBits,
							subOrder1=>ABABA_order,
							subOrder2=>ABABB_order,
							twiddleDelay=>ABAB_twiddleDelay,
							subDelay1=>ABABA_delay,
							subDelay2=>6,
							customSubOrder=>true)
						port map(
							clk=>clk, phase=>ABAB_phase, phaseOut=>open,
							subOut1=>ABABA_out,
							subIn2=>ABABB_in,
							subPhase2=>ABABB_phase,
							twAddr=>ABAB_twAddr, twData=>ABAB_twData,
							bitPermIn=>ABAB_bitPermIn, bitPermOut=>ABAB_bitPermOut);
						
					ABABA_in <= ABAB_in;
					ABAB_out <= ABABB_out;
					ABABA_phase <= ABAB_phase(ABABA_order-1 downto 0);
					ABAB_bitPermOut <= ABAB_bitPermIn;
					ABAB_tw: entity twiddleGenerator4 port map(clk, ABAB_twAddr, ABAB_twData);

						-- ====== FFT instance 'ABABA' (N=2) ======
						ABABA_inst: entity fft2_serial
							generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
							port map(clk=>clk, din=>ABABA_in, phase=>ABABA_phase, dout=>ABABA_out);

						-- ====== FFT instance 'ABABB' (N=2) ======
						ABABB_inst: entity fft2_serial
							generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
							port map(clk=>clk, din=>ABABB_in, phase=>ABABB_phase, dout=>ABABB_out);

				-- ====== FFT instance 'ABB' (N=4) ======
				ABB_core: entity fft3step_bram_generic3
					generic map(
						dataBits=>dataBits,
						twiddleBits=>ABB_twiddleBits,
						subOrder1=>ABBA_order,
						subOrder2=>ABBB_order,
						twiddleDelay=>ABB_twiddleDelay,
						subDelay1=>ABBA_delay,
						subDelay2=>6,
						customSubOrder=>true)
					port map(
						clk=>clk, phase=>ABB_phase, phaseOut=>open,
						subOut1=>ABBA_out,
						subIn2=>ABBB_in,
						subPhase2=>ABBB_phase,
						twAddr=>ABB_twAddr, twData=>ABB_twData,
						bitPermIn=>ABB_bitPermIn, bitPermOut=>ABB_bitPermOut);
					
				ABBA_in <= ABB_in;
				ABB_out <= ABBB_out;
				ABBA_phase <= ABB_phase(ABBA_order-1 downto 0);
				ABB_bitPermOut <= ABB_bitPermIn;
				ABB_tw: entity twiddleGenerator4 port map(clk, ABB_twAddr, ABB_twData);

					-- ====== FFT instance 'ABBA' (N=2) ======
					ABBA_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
						port map(clk=>clk, din=>ABBA_in, phase=>ABBA_phase, dout=>ABBA_out);

					-- ====== FFT instance 'ABBB' (N=2) ======
					ABBB_inst: entity fft2_serial
						generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
						port map(clk=>clk, din=>ABBB_in, phase=>ABBB_phase, dout=>ABBB_out);

		-- ====== FFT instance 'B' (N=4) ======
		B_core: entity fft3step_bram_generic3
			generic map(
				dataBits=>dataBits,
				twiddleBits=>B_twiddleBits,
				subOrder1=>BA_order,
				subOrder2=>BB_order,
				twiddleDelay=>B_twiddleDelay,
				subDelay1=>BA_delay,
				subDelay2=>6,
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
		B_tw: entity twiddleGenerator4 port map(clk, B_twAddr, B_twData);

			-- ====== FFT instance 'BA' (N=2) ======
			BA_inst: entity fft2_serial
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BA_in, phase=>BA_phase, dout=>BA_out);

			-- ====== FFT instance 'BB' (N=2) ======
			BB_inst: entity fft2_serial
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BB_in, phase=>BB_phase, dout=>BB_out);
end ar;

