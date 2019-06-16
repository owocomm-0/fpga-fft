library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft2_noPipeline;

entity fft2_serial2 is
	generic(dataBits: integer := 18;
			scale: scalingModes := SCALE_NONE;
			round: boolean := false);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(0 downto 0);
		dout: out complex
		);
end entity;

architecture ar of fft2_serial2 is
	signal ph1: unsigned(0 downto 0);
	signal shiftIn,fftIn_2Cycle,fftOut0,fftOut_2Cycle: complexArray(1 downto 0);
	signal shiftOut,shiftOutNext: complexArray(1 downto 0);
begin
	shiftIn <= din & shiftIn(1 downto 1) when rising_edge(clk);
	-- 2 cycles
	
	fft1: entity fft2_noPipeline
		generic map(dataBits=>dataBits, scale=>scale, round=>round)
		port map(shiftIn, fftOut0);
	
	shiftOutNext <= fftOut0 when phase=0 else
					to_complex(0,0) & shiftOut(1 downto 1);
	shiftOut <= shiftOutNext when rising_edge(clk);
	-- 3 cycles
	
	dout <= shiftOut(0); -- when rising_edge(clk);
	-- 3 cycles
end ar;
