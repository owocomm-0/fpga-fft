library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- If customSubOrder is true, the columns (slow changing part of the phase)
-- are reordered by a user defined permutation. bitPermOut and bitPermIn
-- should be connected to this permutation function (purely combinational).
-- If bitReverse4 is true, subOrder2 must be 4 and the rows are reordered as 0,2,1,3.
-- total delay is equal to -twiddleDelay.
entity twiddleAddrGen is
	generic(subOrder1,subOrder2: integer := 4;
			twiddleDelay: integer := 7;
			customSubOrder: boolean := false;
			bitReverse4: boolean := false
			);

	port(clk: in std_logic;
		phase: in unsigned(subOrder1+subOrder2-1 downto 0);
		twAddr: out unsigned(subOrder1+subOrder2-1 downto 0);
		
		bitPermIn: out unsigned(subOrder1-1 downto 0) := (others=>'X');
		bitPermOut: in unsigned(subOrder1-1 downto 0) := (others=>'0')
		);
end entity;

architecture ar of twiddleAddrGen is
	constant order: integer := subOrder1+subOrder2;
	constant N: integer := 2**order;
	constant subN1: integer := 2**subOrder1;
	constant subN2: integer := 2**subOrder2;
	
	constant extraPhaseReg: boolean := false; --(order >= 12);

	signal ph_1, ph0: unsigned(order-1 downto 0) := (others=>'0');
	
	signal ph_twiddle: unsigned(order-1 downto 0) := (others=>'0');
	signal twMajorAddr: unsigned(subOrder1-1 downto 0) := (others=>'0');
	signal twData1: complex;
	signal twAddr0, twAddr0Next: unsigned(order-1 downto 0) := (others=>'0');
begin
g1: if extraPhaseReg generate
		ph_1 <= phase+2 when rising_edge(clk);
		ph0 <= ph_1 when rising_edge(clk);
	end generate;
g2: if not extraPhaseReg generate
		ph0 <= phase;
	end generate;
	
	ph_twiddle <= ph0+twiddleDelay+2 when rising_edge(clk);
	
	bitPermIn <= ph_twiddle(ph_twiddle'left downto subOrder2);
	twMajorAddr <= bitPermOut when customSubOrder=true else
		ph_twiddle(ph_twiddle'left downto subOrder2);

g3: if not bitReverse4 generate
		twAddr0Next <= (others=>'0') when ph_twiddle(subOrder2-1 downto 0)=0 else
					twAddr0 + twMajorAddr;
	end generate;
g4: if bitReverse4 generate
		twAddr0Next <= (others=>'0') when ph_twiddle(subOrder2-1 downto 0)=0 else
					twAddr0 + (twMajorAddr & "0") when ph_twiddle(0)='1' else
					twAddr0 - twMajorAddr;
	end generate;
	twAddr0 <= twAddr0Next when rising_edge(clk); -- aligned with ph0+twiddleDelay
	twAddr <= twAddr0;
end ar;
