
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 2048
-- fft bit order: (10 downto 0) [0,1,2,4,3,9,8,7,6,5,10]
entity fft1024_moredsp2_ireorderer is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(11-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_moredsp2_ireorderer is
	signal rP0: unsigned(11-1 downto 0);
	signal rP1: unsigned(11-1 downto 0);
	signal rP2: unsigned(11-1 downto 0);
	signal rP3: unsigned(11-1 downto 0);
	signal rCnt: unsigned(3-1 downto 0);
begin
	rb: entity reorderBuffer
		generic map(N=>11, dataBits=>dataBits, repPeriod=>6, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP3);
	rP1 <= rP0(0)&rP0(1)&rP0(2)&rP0(4)&rP0(3)&rP0(9)&rP0(8)&rP0(7)&rP0(6)&rP0(5)&rP0(10) when rCnt(0)='1' else rP0;
	rP2 <= rP1(10)&rP1(5)&rP1(6)&rP1(8)&rP1(7)&rP1(1)&rP1(2)&rP1(4)&rP1(3)&rP1(9)&rP1(0) when rCnt(1)='1' else rP1;
	rP3 <= rP2(10)&rP2(1)&rP2(7)&rP2(6)&rP2(8)&rP2(9)&rP2(3)&rP2(2)&rP2(4)&rP2(5)&rP2(0) when rCnt(2)='1' else rP2;
end ar;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 2048
-- fft bit order: (10 downto 0) [0,1,2,3,4,5,6,7,8,9,10]
entity fft1024_moredsp2_oreorderer is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(11-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_moredsp2_oreorderer is
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

