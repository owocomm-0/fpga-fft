
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 4096
-- fft bit order: (11 downto 0) [1,0,3,2,5,4,9,8,7,6,11,10]
entity fft1024_wide_ireorderer4 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(12-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_ireorderer4 is
	signal rP0: unsigned(12-1 downto 0);
	signal rP1: unsigned(12-1 downto 0);
	signal rP2: unsigned(12-1 downto 0);
	signal rCnt: unsigned(2-1 downto 0);


begin
	rb: entity reorderBuffer
		generic map(N=>12, dataBits=>dataBits, repPeriod=>4, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP2);
	rP1 <= rP0(1)&rP0(0)&rP0(3)&rP0(2)&rP0(5)&rP0(4)&rP0(9)&rP0(8)&rP0(7)&rP0(6)&rP0(11)&rP0(10) when rCnt(0)='1' else rP0;
	rP2 <= rP1(11)&rP1(10)&rP1(7)&rP1(6)&rP1(9)&rP1(8)&rP1(3)&rP1(2)&rP1(5)&rP1(4)&rP1(1)&rP1(0) when rCnt(1)='1' else rP1;

end ar;
