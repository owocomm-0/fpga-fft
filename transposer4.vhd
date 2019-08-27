library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- 2x2 transposer

-- timing diagram:
--   clk ||   -   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |
--    ph ||   0   |   1   |   2   |   3   |   0   |   1   |   2   |   3   |
--   din ||  a0   |  a1   |  a2   |  a3   |  b0   |  b1   |  b2   |  b3   |
--currRE ||                       |         reorder enable        |
-- dout0 ||                       |  a0   |  a2   |  a1   |  a3   |  b0   |
--  dout ||                               |  a0   |  a2   |  a1   |  a3   |
entity transposer4 is
	generic(dataBits: integer);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex;
		-- set to 0 if the currently writing frame should not be reordered;
		-- this is sampled near the end of the frame, at phase = 2
		reorderEnable: in std_logic := '1'
		);
end entity;

architecture ar of transposer4 is
	signal srIn: complexArray(0 to 3);
	signal currRE: std_logic := '0';
	signal srAddr: integer := 0;
	signal dout0: complex;
begin
	-- use addressable shift registers (SRL16)
	srIn <= din & srIn(0 to srIn'right-1) when rising_edge(clk);
	
	currRE <= reorderEnable when phase=2 and rising_edge(clk);
	
	srAddr <= 2 when currRE='0' else
				2 when phase=3 else
				1 when phase=0 else
				3 when phase=1 else
				2;
	
	dout0 <= srIn(srAddr);
	dout <= dout0 when rising_edge(clk);
end ar;
