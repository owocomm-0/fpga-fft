library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.complexRam;
use work.complexRamLUT;
use work.sr_complex;

entity complexRamDelay is
	generic(dataBits, delay: integer);
	port(clk: in std_logic;
		din: in complex;
		dout: out complex);
end entity;
architecture a of complexRamDelay is
	-- we can not use ram if delay is too small, so sr_complex is used
	constant useSR: boolean := (delay <= 32);
	
	-- how many cycles from raddr to rdata
	constant ramReadDelay: integer := 2;
	
	-- additional delay we introduced
	constant extraDelay: integer := ramReadDelay;
	
	-- the number of words actually stored in ram
	constant fuck: integer := delay - extraDelay;
	
	-- depth of the ram
	constant depthOrder: integer := ceilLog2(fuck);
	constant depth: integer := 2**depthOrder;
	
	constant useLUTRam: boolean := (depthOrder < TRANSPOSER_BRAM_THRESHOLD);
	
	signal raddr, waddr: unsigned(depthOrder-1 downto 0);
	signal counter: unsigned(depthOrder-1 downto 0) := (others=>'0');
	signal rdata, wdata: complex;
begin

g1: if useSR generate
		sr: entity sr_complex generic map(len=>delay)
			port map(clk=>clk, din=>din, dout=>dout);
	end generate;

g2: if not useSR generate
	g3: if useLUTRam generate
			ram: entity complexRamLUT
				generic map(dataBits=>dataBits, depthOrder=>depthOrder)
				port map(rdclk=>clk, wrclk=>clk,
						rdaddr=>raddr, rddata=>rdata,
						wren=>'1', wraddr=>waddr, wrdata=>wdata);
		end generate;
	g4: if not useLUTRam generate
			ram: entity complexRam
				generic map(dataBits=>dataBits, depthOrder=>depthOrder)
				port map(rdclk=>clk, wrclk=>clk,
						rdaddr=>raddr, rddata=>rdata,
						wren=>'1', wraddr=>waddr, wrdata=>wdata);
		end generate;
		
		counter <= counter+1 when rising_edge(clk);
		raddr <= counter when rising_edge(clk);
		waddr <= raddr+fuck+1 when rising_edge(clk);
		
		wdata <= din; -- when rising_edge(clk);
		dout <= rdata; -- when rising_edge(clk);
	end generate;
end a;
