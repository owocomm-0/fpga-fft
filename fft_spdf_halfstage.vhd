library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_complex;
use work.complexRamDelay;
use work.spdf_butterflyA;

-- total delay: (2**N)/2 + bf_delay + 1 if butterfly2=0
--              (2**N)/4 + bf_delay + 1 if butterfly2=1
-- N should be set to the log2 of the whole frame length. 
-- delay line length is automatically set to frameSize/4 when butterfly2 is true.

-- if modifying this file and delay is changed, update the following locations:
-- - fft_spdf_halfstage_delay()
-- - gen_fft_modules.py
entity fft_spdf_halfstage is
	generic(N, dataBits: integer;
			butterfly2: boolean := false;
			inverse: boolean := true);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(N-1 downto 0);
		dout: out complex);
end entity;
architecture a of fft_spdf_halfstage is
	constant bfDelay: integer := 2;
	constant delay: integer := iif(butterfly2, 2**(N-2), 2**(N-1));
	
	signal ph, ph1: unsigned(N-1 downto 0);
	
	-- sel controls i/o muxes and selB controls butterfly twiddle mode.
	signal sel, selNext, selB, selBNext: std_logic;
	signal din1, delayMuxA, delayMux: complex;
	signal outMuxA, outMux: complex;
	signal delayOut: complex;
	signal bfIn, bfOut, bfOutA, bfOutB: complexArray(1 downto 0);
begin
	din1 <= din; -- when rising_edge(clk);
	ph <= phase; -- when rising_edge(clk);
	
	-- input delay
	del1: entity sr_complex generic map(len=>bfDelay)
		port map(clk=>clk, din=>din1, dout=>delayMuxA);
	
	-- input mux
	delayMux <= delayMuxA when sel='0' else
		bfOutA(1) when selB='0' else
		bfOutB(1);
	
	-- ram delay
	del_ram: entity complexRamDelay
		generic map(dataBits=>dataBits, delay=>delay-bfDelay)
		port map(clk=>clk, din=>delayMux, dout=>delayOut);
	
	-- output delay
	del2: entity sr_complex generic map(len=>bfDelay)
		port map(clk=>clk, din=>delayOut, dout=>outMuxA);
	
	-- output mux
	outMux <= outMuxA when sel='0' else
		bfOutA(0) when selB='0' else
		bfOutB(0);
	
	
	-- butterfly
	bf: entity spdf_butterflyA
		generic map(dataBits=>dataBits)
		port map(clk=>clk, din=>bfIn, dout=>bfOut);
	
	-- apply post-butterfly transformations (twiddles)
	bfOutA <= bfOut;
g1: if not inverse generate
	g3:	if not butterfly2 generate
			-- swap real and imaginary part of A-B
			bfOutB <= (complex_swap(bfOut(1)), bfOut(0));
		end generate;
	g4: if butterfly2 generate
			-- swap imaginary part among (A+B) and (A-B);
			-- equivalent to inverting the imaginary part of the 'B' input.
			bfOutB <= (to_complex(bfOut(1).re, bfOut(0).im),
						to_complex(bfOut(0).re, bfOut(1).im));
		end generate;
	end generate;
g2: if inverse generate
	g5:	if not butterfly2 generate
			-- swap real and imaginary part of A-B
			bfOutB <= (complex_swap(bfOut(1)), bfOut(0));
		end generate;
	g6: if butterfly2 generate
			-- swap real part among (A+B) and (A-B);
			-- equivalent to inverting the real part of the 'B' input.
			bfOutB <= (to_complex(bfOut(0).re, bfOut(1).im),
						to_complex(bfOut(1).re, bfOut(0).im));
		end generate;
	end generate;
	

	bfIn(0) <= delayOut;
	bfIn(1) <= din1;
	
	-- control logic
	ph1 <= ph-bfDelay+1;
	
	-- if we are the first stage, MSB of the frame index controls
	-- i/o muxes, and MSB-1 controls butterfly twiddle mode.
	-- if we are the second stage, the controls are flipped.
g3:	if not butterfly2 generate
		selNext <= ph1(ph1'left);
		selBNext <= ph1(ph1'left-1);
	end generate;
g4: if butterfly2 generate
		selNext <= ph1(ph1'left-1);
		selBNext <= ph1(ph1'left);
	end generate;
	sel <= selNext when rising_edge(clk);
	selB <= selBNext when rising_edge(clk);
	
	dout <= outMux when rising_edge(clk);
end a;
