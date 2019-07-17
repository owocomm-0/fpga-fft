library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexRam;
use work.complexRamLUT;
use work.twiddleGenerator;
use work.transposer_addrGen;
use work.sr_complex;
use work.transposer4;

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
	signal din2, dout0, dout1: complex;
	signal iaddr, iaddr2, oaddr: unsigned(N1+N2-1 downto 0);
	constant extraRegister: boolean := (N1+N2) >= TRANSPOSER_OREG_THRESHOLD;
	constant extraRegister2: boolean := (N1+N2) >= TRANSPOSER_OREG2_THRESHOLD;
	constant useLUTRam: boolean := ((N1+N2) < TRANSPOSER_BRAM_THRESHOLD);
	constant myDelays: integer := iif(extraRegister, 3, 2) + iif(extraRegister2, 1, 0);
	constant useTransposer4: boolean := (N1=1 and N2=1);
begin
gA:
	if useTransposer4 generate
		transp: entity transposer4 generic map(dataBits=>dataBits)
			port map(clk=>clk, din=>din, phase=>phase, dout=>dout, reorderEnable=>reorderEnable);
	end generate;
gB:
	if not useTransposer4 generate
		-- read side
		addrGen: entity transposer_addrGen generic map(N1, N2, myDelays)
			port map(clk, reorderEnable, phase, oaddr);
		-- -myDelays cycles

	g3: if useLUTRam generate
			ram: entity complexRamLUT generic map(dataBits, N1+N2)
				port map(clk, clk, oaddr, dout0, '1', iaddr2, din2);
		end generate;
	g4: if not useLUTRam generate
			ram: entity complexRam generic map(dataBits, N1+N2)
				port map(clk, clk, oaddr, dout0, '1', iaddr2, din2);
		end generate;
		
		-- -myDelays+2 cycles
	g1: if extraRegister generate
			dout1 <= dout0 when rising_edge(clk);
			-- -myDelays+3 cycles
		end generate;
	g2: if not extraRegister generate
			dout1 <= dout0;
			-- -myDelays+2 cycles
		end generate;

	g5: if extraRegister2 generate
			dout <= dout1 when rising_edge(clk);
		end generate;
	g6: if not extraRegister2 generate
			dout <= dout1;
		end generate;

		-- write side
		sr1: entity sr_unsigned generic map(N1+N2, myDelays)
			port map(clk, oaddr, iaddr);
		din2 <= din when rising_edge(clk);
		iaddr2 <= iaddr when rising_edge(clk);
	end generate;
	
end ar;
