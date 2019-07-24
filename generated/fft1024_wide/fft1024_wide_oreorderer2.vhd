
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 2048
-- fft bit order: (10 downto 0) [0,1,2,3,4,5,6,7,8,9,10]
entity fft1024_wide_oreorderer2 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(11-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_oreorderer2 is
	signal rP0: unsigned(11-1 downto 0);
	signal rP1: unsigned(11-1 downto 0);
	signal rCnt: unsigned(1-1 downto 0);


begin
	rb: entity reorderBuffer
		generic map(N=>11, dataBits=>dataBits, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP1);
	rP1 <= rP0(0)&rP0(1)&rP0(2)&rP0(3)&rP0(4)&rP0(5)&rP0(6)&rP0(7)&rP0(8)&rP0(9)&rP0(10) when rCnt(0)='1' else rP0;

end ar;
