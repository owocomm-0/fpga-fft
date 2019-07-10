library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_complex;
use work.fft_spdf_halfstage;


-- N should be set to the log2 of the whole frame length. 
-- total delay is fft_spdf_halfstage_delay(N, false) + fft_spdf_halfstage_delay(N, true)
entity fft_spdf_stage is
	generic(N, dataBits, bitGrowth: integer;
			inverse: boolean := true);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(N-1 downto 0);
		dout: out complex);
end entity;

architecture a of fft_spdf_stage is
	signal ph1: unsigned(N-1 downto 0);
	signal tmp: complex;
begin
	s1: entity fft_spdf_halfstage
		generic map(N=>N, dataBits=>dataBits+bitGrowth, butterfly2=>false, inverse=>inverse)
		port map(clk=>clk, din=>din, phase=>phase, dout=>tmp);
	
	ph1 <= phase - fft_spdf_halfstage_delay(N, false);
	
	s2: entity fft_spdf_halfstage
		generic map(N=>N, dataBits=>dataBits+bitGrowth, butterfly2=>true, inverse=>inverse)
		port map(clk=>clk, din=>tmp, phase=>ph1, dout=>dout);
end a;

	
