library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
--use work.barrelShifter;

-- phase should be 0,1,2,3,4,5,6,... up to (2**N1)*(2**N2)-1
entity transposer_addrgen is
	generic(N1,N2: integer; -- N1 is the major size and N2 the minor size (input perspective)
			-- when phaseAdvance is 0, addr always corresponds to phase in the same clock cycle
			-- when phaseAdvance > 0, addr corresponds to phase+phaseAdvance
			phaseAdvance: integer := 0);
	port(clk: in std_logic;
		reorderEnable: in std_logic;
		phase: in unsigned(N1+N2-1 downto 0);
		addr: out unsigned(N1+N2-1 downto 0)
		);
end entity;
architecture ar of transposer_addrGen is
	signal ph1,ph2,ph3: unsigned(N1+N2-1 downto 0);
	
	constant use_stagedBarrelShifter: boolean := false;
	constant stateCount: integer := N1+N2;
	constant stateBits: integer := ceilLog2(stateCount);
	--constant shifterMuxStages: integer := integer(ceil(real(stateBits)/real(2)));
	--constant shifterMuxBits: integer := shifterMuxStages*2;
	--constant delay: integer := iif(use_stagedBarrelShifter, shifterMuxStages+2, 3);
	constant extraRegister: boolean := ((N1+N2) >= 12);
	constant delay: integer := 3 + iif(extraRegister, 1, 0);
	--attribute delay of ar:architecture is shifterMuxStages+1;
	
	signal state,stateNext: unsigned(stateBits-1 downto 0) := (others=>'0');
begin
	ph1 <= phase+phaseAdvance+delay when rising_edge(clk);
	-- 1 cycle
	
	ph2 <= ph1 when rising_edge(clk);
	stateNext <= state+N2-stateCount when state>=(stateCount-N2) else state+N2;
	state <= stateNext when ph1=0 and reorderEnable='1' and rising_edge(clk);
	-- 2 cycles
	
--g1:
--	if use_stagedBarrelShifter generate
--		bs: entity barrelShifter generic map(N1+N2, shifterMuxStages)
--				port map(clk, ph2, resize(state, shifterMuxBits), ph3);
--	end generate;
	-- 2+shifterMuxStages cycles
g2:
	if not use_stagedBarrelShifter generate
		ph3 <= rotate_left(ph2, to_integer(state)) when rising_edge(clk);
	end generate;
	-- 3 cycles
	
g3: if extraRegister generate
		addr <= ph3 when rising_edge(clk);
	end generate;
g4: if not extraRegister generate
		addr <= ph3;
	end generate;
end ar;
