library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexRam;
use work.twiddleGenerator;
use work.complexMultiply;
use work.transposer_addrGen;
use work.sr_complex;

-- phase should be 0,1,2,3,4,5,6,... up to (2**N1)*(2**N2)-1
-- transpose from 2**N1 groups of 2**N2 words to 2**N2 groups of 2**N1 words.
-- din:  aa,ab,ac,ad,ba,bb,bc,bd,ca,cb,cc,cd,...
-- dout: aa,ba,ca,ab,bb,cb,ac,bc,cc,ad,bd,cd,...
entity transposer is
	generic(N1,N2: integer; -- N1 is the major size and N2 the minor size (input perspective)
			dataBits: integer);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(N1+N2-1 downto 0);
		dout: out complex;
		-- set to 0 if the currently writing frame should not be reordered;
		-- this is sampled near the end of the frame, at phase ~= N1*N2 - totalDelays
		reorderEnable: in std_logic := '1'
		);
end entity;
architecture ar of transposer is
	signal din2,dout0: complex;
	signal iaddr, iaddr2, oaddr: unsigned(N1+N2-1 downto 0);
	constant extraRegister: boolean := (N1+N2) > 4;
	constant myDelays: integer := iif(extraRegister, 3, 2);
begin
	-- read side
	addrGen: entity transposer_addrGen generic map(N1, N2, myDelays)
		port map(clk, reorderEnable, phase, oaddr);
	-- -myDelays cycles
	
	ram: entity complexRam generic map(dataBits, N1+N2)
		port map(clk, clk, oaddr, dout0, '1', iaddr2, din2);
	-- -myDelays+2 cycles
g1: if extraRegister generate
		dout <= dout0 when rising_edge(clk);
		-- -myDelays+3 cycles
	end generate;
g2: if not extraRegister generate
		dout <= dout0;
		-- -myDelays+2 cycles
	end generate;
	
	
	-- write side
	sr1: entity sr_unsigned generic map(N1+N2, myDelays)
		port map(clk, oaddr, iaddr);
	din2 <= din when rising_edge(clk);
	iaddr2 <= iaddr when rising_edge(clk);
end ar;
