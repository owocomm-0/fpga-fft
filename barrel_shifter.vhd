
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity shiftMux is
	generic(bits: integer;
			ctrlBits: integer;
			ctrlScale: integer := 1);
	port(clk: in std_logic;
		din: in unsigned(bits-1 downto 0);
		shLeft: in unsigned(ctrlbits-1 downto 0);
		dout: out unsigned(bits-1 downto 0));
end entity;
architecture ar of shiftMux is
	constant N: integer := 2**ctrlBits;
	type outcomes_t is array(0 to N-1) of unsigned(bits-1 downto 0);
	signal outcomes: outcomes_t;
begin
g1:
	for I in 0 to N-1 generate
		outcomes(I) <= rotate_left(din, I*ctrlScale);
	end generate;
	dout <= outcomes(to_integer(shLeft)) when rising_edge(clk);
end ar;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.shiftMux;

-- delay is stages cycles
-- input is unregistered
-- each stage can perform a 4:1 mux
entity barrelShifter is
	generic(bits: integer;
			stages: integer := 2);
	port(clk: in std_logic;
		din: in unsigned(bits-1 downto 0);
		shLeft: in unsigned(stages*2-1 downto 0);
		dout: out unsigned(bits-1 downto 0)
		);
end entity;
architecture ar of barrelShifter is
	constant phaseBits: integer := stages*2;
	type arr_t is array(integer range<>) of unsigned(bits-1 downto 0);
	type arr2_t is array(integer range<>) of unsigned(phaseBits-1 downto 0);
	
	signal partialRotates: arr_t(0 to stages);
	signal phases: arr2_t(0 to stages);
begin
	partialRotates(0) <= din; -- when rising_edge(clk);
	phases(0) <= shLeft when rising_edge(clk);
g1:
	for I in 0 to stages-1 generate
		mux: entity shiftMux generic map(bits, 2, 4**I)
			port map(clk, partialRotates(I), phases(I)((I+1)*2-1 downto I*2), partialRotates(I+1));
		
		--partialRotates(I+1) <= rotate_left(partialRotates(I),
		--	to_integer(phases(I)((I+1)*2-1 downto I*2) & (I*2-1 downto 0=>'0'))) when rising_edge(clk);
		phases(I+1) <= phases(I) when rising_edge(clk);
	end generate;
	dout <= partialRotates(stages);
end ar;

