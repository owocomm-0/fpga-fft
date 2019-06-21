
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 1024
-- fft bit order: (9 downto 0) [1,0,3,2,5,4,9,8,7,6]
entity fft1024_wide_ireorderer1 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(10-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_ireorderer1 is
	signal rP0: unsigned(10-1 downto 0);
	signal rP1: unsigned(10-1 downto 0);
	signal rP2: unsigned(10-1 downto 0);
	signal rCnt: unsigned(2-1 downto 0);

begin
	rb: entity reorderBuffer
		generic map(N=>10, dataBits=>dataBits, repPeriod=>4, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP2);
	rP1 <= rP0(1)&rP0(0)&rP0(3)&rP0(2)&rP0(5)&rP0(4)&rP0(9)&rP0(8)&rP0(7)&rP0(6) when rCnt(0)='1' else rP0;
	rP2 <= rP1(7)&rP1(6)&rP1(9)&rP1(8)&rP1(5)&rP1(4)&rP1(1)&rP1(0)&rP1(3)&rP1(2) when rCnt(1)='1' else rP1;

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
-- delay is 1024
-- fft bit order: (9 downto 0) [0,1,2,3,5,4,6,7,8,9]
entity fft1024_wide_oreorderer1 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(10-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_oreorderer1 is
	signal rP0: unsigned(10-1 downto 0);
	signal rP1: unsigned(10-1 downto 0);
	signal rCnt: unsigned(1-1 downto 0);

begin
	rb: entity reorderBuffer
		generic map(N=>10, dataBits=>dataBits, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP1);
	rP1 <= rP0(0)&rP0(1)&rP0(2)&rP0(3)&rP0(5)&rP0(4)&rP0(6)&rP0(7)&rP0(8)&rP0(9) when rCnt(0)='1' else rP0;

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
-- fft bit order: (10 downto 0) [1,0,3,2,5,4,9,8,7,6,10]
entity fft1024_wide_ireorderer2 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(11-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_ireorderer2 is
	signal rP0: unsigned(11-1 downto 0);
	signal rP1: unsigned(11-1 downto 0);
	signal rP2: unsigned(11-1 downto 0);
	signal rP3: unsigned(11-1 downto 0);
	signal rP4: unsigned(11-1 downto 0);
	signal rCnt: unsigned(4-1 downto 0);

begin
	rb: entity reorderBuffer
		generic map(N=>11, dataBits=>dataBits, repPeriod=>14, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP4);
	rP1 <= rP0(1)&rP0(0)&rP0(3)&rP0(2)&rP0(5)&rP0(4)&rP0(9)&rP0(8)&rP0(7)&rP0(6)&rP0(10) when rCnt(0)='1' else rP0;
	rP2 <= rP1(6)&rP1(10)&rP1(8)&rP1(7)&rP1(4)&rP1(9)&rP1(0)&rP1(3)&rP1(2)&rP1(5)&rP1(1) when rCnt(1)='1' else rP1;
	rP3 <= rP2(4)&rP2(6)&rP2(8)&rP2(7)&rP2(0)&rP2(10)&rP2(1)&rP2(3)&rP2(2)&rP2(9)&rP2(5) when rCnt(2)='1' else rP2;
	rP4 <= rP3(1)&rP3(0)&rP3(8)&rP3(7)&rP3(5)&rP3(4)&rP3(9)&rP3(3)&rP3(2)&rP3(6)&rP3(10) when rCnt(3)='1' else rP3;

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
-- fft bit order: (10 downto 0) [0,1,2,3,4,6,5,7,8,9,10]
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
	signal rP2: unsigned(11-1 downto 0);
	signal rP3: unsigned(11-1 downto 0);
	signal rCnt: unsigned(3-1 downto 0);

begin
	rb: entity reorderBuffer
		generic map(N=>11, dataBits=>dataBits, repPeriod=>6, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP3);
	rP1 <= rP0(0)&rP0(1)&rP0(2)&rP0(3)&rP0(4)&rP0(6)&rP0(5)&rP0(7)&rP0(8)&rP0(9)&rP0(10) when rCnt(0)='1' else rP0;
	rP2 <= rP1(10)&rP1(9)&rP1(8)&rP1(7)&rP1(5)&rP1(4)&rP1(6)&rP1(3)&rP1(2)&rP1(1)&rP1(0) when rCnt(1)='1' else rP1;
	rP3 <= rP2(10)&rP2(9)&rP2(8)&rP2(7)&rP2(4)&rP2(6)&rP2(5)&rP2(3)&rP2(2)&rP2(1)&rP2(0) when rCnt(2)='1' else rP2;

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


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.reorderBuffer;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 4096
-- fft bit order: (11 downto 0) [1,0,2,3,4,5,7,6,8,9,10,11]
entity fft1024_wide_oreorderer4 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(12-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_oreorderer4 is
	signal rP0: unsigned(12-1 downto 0);
	signal rP1: unsigned(12-1 downto 0);
	signal rP2: unsigned(12-1 downto 0);
	signal rCnt: unsigned(2-1 downto 0);

begin
	rb: entity reorderBuffer
		generic map(N=>12, dataBits=>dataBits, repPeriod=>4, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP2);
	rP1 <= rP0(1)&rP0(0)&rP0(2)&rP0(3)&rP0(4)&rP0(5)&rP0(7)&rP0(6)&rP0(8)&rP0(9)&rP0(10)&rP0(11) when rCnt(0)='1' else rP0;
	rP2 <= rP1(10)&rP1(11)&rP1(9)&rP1(8)&rP1(6)&rP1(7)&rP1(4)&rP1(5)&rP1(3)&rP1(2)&rP1(0)&rP1(1) when rCnt(1)='1' else rP1;

end ar;

