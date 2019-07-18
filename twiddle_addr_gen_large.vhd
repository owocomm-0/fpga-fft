
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- for a large FFT, given the phase counter, compute X*Y without a multiplier;
-- assumes the traversal order is:
--|  0  2  4  6 |
--|  1  3  5  7 |
--|  8 10 12 14 |
--|  9 11 13 15 |
-- (subOrder = 2, rowsOrder = 1)

entity twiddleAddrGenLarge is
	generic(twDelay,subOrder,rowsOrder: integer);
	port(clk: in std_logic;
		phase: in unsigned(subOrder*2-1 downto 0);
		twMultEnable: in std_logic;
		twAddr: out unsigned(subOrder*2-1 downto 0));
end entity;
architecture ar of twiddleAddrGenLarge is
	constant myDelay: integer := 3;
	signal ph: unsigned(subOrder*2-1 downto 0);
	signal twX, twY, twX1, twY1: unsigned(subOrder-1 downto 0);
	signal twFineY, twFineY1: unsigned(rowsOrder-1 downto 0);
	signal twIA, twIANext, twIB, twIBNext: unsigned(subOrder*2-1 downto 0);
	signal twAddr0: unsigned(subOrder*2-1 downto 0);
begin
	ph <= phase + (twDelay + myDelay + 1) when rising_edge(clk);

	-- twX is the column number
	-- twY is the row number rounded down to a multiple of burstWidth
	-- twFineY is the row number mod burstWidth
	twX <= ph(subOrder+rowsOrder-1 downto rowsOrder);
	twY <= ph(ph'left downto subOrder+rowsOrder) & (rowsOrder-1 downto 0=>'0');
	twFineY <= ph(rowsOrder-1 downto 0);

	twIANext <= (others=>'0') when twX=0 else twIA+twY;
	twIA <= twIANext when twFineY=0 and rising_edge(clk);

	twFineY1 <= twFineY when rising_edge(clk);
	twX1 <= twX when rising_edge(clk);
	twY1 <= twY when rising_edge(clk);
	-- twIA is twX1*twY1

	twIBNext <= twIA when twFineY1=0 else twIB+twX1;
	twIB <= twIBNext when rising_edge(clk);
	twAddr0 <= twIB when twMultEnable='1' else
				to_unsigned(0, twAddr'length);
	twAddr <= twAddr0 when rising_edge(clk);

end ar;
