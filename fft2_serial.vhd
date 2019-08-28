library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft2_noPipeline;

-- be sure to add a multi-cycle timing constraint of 2 cycles
-- from fftIn_2Cycle/Q to fftOut_2Cycle/D:
-- set_multicycle_path -from [get_pins -hierarchical *fftIn_2Cycle*/C] -to [get_pins -hierarchical *fftOut_2Cycle*/D] -setup 2
-- set_multicycle_path -from [get_pins -hierarchical *fftIn_2Cycle*/C] -to [get_pins -hierarchical *fftOut_2Cycle*/D] -hold 1

entity fft2_serial is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			-- inverse is ignored because ifft-2 is equivalent to fft-2
			inverse: boolean := true;
			round: boolean := true);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(0 downto 0);
		dout: out complex
		);
end entity;

architecture ar of fft2_serial is
	signal ph1: unsigned(0 downto 0);
	signal shiftIn,fftIn_2Cycle,fftOut0,fftOut_2Cycle: complexArray(1 downto 0);
	signal shiftOut,shiftOutNext: complexArray(1 downto 0);
begin
	shiftIn <= din & shiftIn(1 downto 1) when rising_edge(clk);
	fftIn_2Cycle <= shiftIn when phase=0 and rising_edge(clk);
	-- 3 cycles
	
	fft1: entity fft2_noPipeline
		generic map(dataBits=>dataBits, scale=>scale, round=>round)
		port map(fftIn_2Cycle, fftOut0);
	fftOut_2Cycle <= fftOut0 when phase=0 and rising_edge(clk);
	-- 5 cycles
	
	shiftOutNext <= fftOut_2Cycle when phase=1 else
					to_complex(0,0) & shiftOut(1 downto 1);
	shiftOut <= shiftOutNext when rising_edge(clk);
	-- 6 cycles
	
	dout <= shiftOut(0); -- when rising_edge(clk);
	-- 6 cycles
end ar;
