library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexRam;
use work.complexRamLUT;
use work.sr_complex;

-- more general version of transposer;
-- reorders data arbitrarily based on a bit permutation.
--
-- phase should be 0,1,2,3,4,5,6,... up to 2**N-1.
--
-- dataPathDelay determines the time offset between input and output.
-- if it is guaranteed that at least 2 clock cycles pass between
-- inputting a value to address i and reading it back,
-- dataPathDelay can be set to 0 for a "zero delay" reorderer.
-- otherwise, dataPathDelay is optimally 2.
--
-- repPeriod should be set to the repetition period of the
-- permutation sequence. For example if perm(perm(perm("012345"))) = "012345"
-- then repPeriod is 3.
entity reorderBuffer is
	generic(N: integer;
			dataBits: integer;
			repPeriod: integer;
			bitPermDelay: integer := 0;
			dataPathDelay: integer := 0);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(N-1 downto 0);
		dout: out complex;
		
		-- external bit permutor
		bitPermIn: out unsigned(N-1 downto 0);
		bitPermCount: out unsigned(ceilLog2(repPeriod)-1 downto 0);
		bitPermOut: in unsigned(N-1 downto 0)
		);
end entity;
architecture ar of reorderBuffer is
	signal din2,dout0: complex;
	signal iaddr, iaddr2, oaddr: unsigned(N-1 downto 0);
	constant extraRegister: boolean := (N) >= TRANSPOSER_OREG_THRESHOLD;
	constant addrDelays: integer := 3+bitPermDelay;
	constant totalDelays: integer := iif(extraRegister, 3, 2) + addrDelays;
	constant useLUTRam: boolean := (N < TRANSPOSER_BRAM_THRESHOLD);
	
	constant stateCount: integer := repPeriod;
	constant stateBits: integer := ceilLog2(stateCount);
	
	signal state,stateNext: unsigned(stateBits-1 downto 0) := (others=>'0');
	signal ph1,ph2,ph3: unsigned(N-1 downto 0);
begin
	-- read side
	ph1 <= phase+totalDelays-dataPathDelay when rising_edge(clk);
	-- 1 cycle
	
	ph2 <= ph1 when rising_edge(clk);
	stateNext <= (others=>'0') when state>=stateCount-1 else state+1;
	state <= stateNext when ph1=0 and rising_edge(clk);
	-- 2 cycles
	
	bitPermIn <= ph2;
	bitPermCount <= state;
	oaddr <= bitPermOut when rising_edge(clk);
	-- addrDelays =
	-- 3+bitPermDelay cycles
	
	
g3: if useLUTRam generate
		ram: entity complexRamLUT generic map(dataBits, N)
			port map(clk, clk, oaddr, dout0, '1', iaddr2, din2);
	end generate;
g4: if not useLUTRam generate
		ram: entity complexRam generic map(dataBits, N)
			port map(clk, clk, oaddr, dout0, '1', iaddr2, din2);
	end generate;


	-- addrDelays+2 cycles
g1: if extraRegister generate
		dout <= dout0 when rising_edge(clk);
		-- addrDelays+3 cycles
	end generate;
g2: if not extraRegister generate
		dout <= dout0;
		-- addrDelays+2 cycles
	end generate;
	
	
	-- write side
	-- oaddr is addrDelays cycles behind din but has been adjusted forward by totalDelays-dataPathDelay cycles,
	-- so we need to delay by totalDelays-dataPathDelay-addrDelays cycles
	sr1: entity sr_unsigned generic map(N, totalDelays-dataPathDelay-addrDelays)
		port map(clk, oaddr, iaddr);
	din2 <= din when rising_edge(clk);
	iaddr2 <= iaddr when rising_edge(clk);
end ar;
