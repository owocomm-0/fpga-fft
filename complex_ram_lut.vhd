library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- read delay is 2 cycles
-- same as complexRam, but with attributes to suggest LUTRAM implementation

-- FIXME: vivado has a bug where if these conditions are true:
-- * a conditional generate block instantiates an entity
-- * the entity's name has upper case characters
-- * the conditional block is inactive (condition false)
-- ...then the module hierarchy will include an "unresolved reference"
-- preventing modules from being used in block design.
-- Using all lowercase in the entity declaration fixes it.
entity complexramlut is
	generic(dataBits: integer := 8;
				-- real depth is 2^depth_order
				depthOrder: integer := 9);
	port(rdclk,wrclk: in std_logic;
			-- read side; synchronous to rdclk
			rdaddr: in unsigned(depthOrder-1 downto 0);
			rddata: out complex;
			
			--write side; synchronous to wrclk
			wren: in std_logic;
			wraddr: in unsigned(depthOrder-1 downto 0);
			wrdata: in complex
			);
end entity;
architecture a of complexRamLUT is
	constant width: integer := dataBits*2;
	constant depth: integer := 2**depthOrder;
	
	--ram
	type ram1t is array(depth-1 downto 0) of
		std_logic_vector(width-1 downto 0);
	signal ram1: ram1t; -- := (others=>(others=>'0'));
	
	signal rdaddr1: unsigned(depthOrder-1 downto 0);
	signal wrdata1: std_logic_vector(width-1 downto 0);
	
	signal tmpdata: std_logic_vector(width-1 downto 0);
	signal tmpdata1,tmpdata2: signed(dataBits-1 downto 0) := (others=>'0');
	
	attribute ram_style: string;
	attribute ram_style of ram1: signal is "distributed";
	attribute keep: string;
	attribute keep of tmpdata1: signal is "true";
	attribute keep of tmpdata2: signal is "true";
begin
	--inferred ram
	rdaddr1 <= rdaddr when rising_edge(rdclk);
	
	-- TODO: we are assuming this infers a register on the address side (rather than output side);
	-- this is true on xilinx but we should verify it on other vendor tools as well.
	tmpdata <= ram1(to_integer(rdaddr1));
	
	tmpdata1 <= signed(tmpdata(dataBits-1 downto 0)) when rising_edge(rdclk);
	tmpdata2 <= signed(tmpdata(width-1 downto dataBits)) when rising_edge(rdclk);
	
	rddata <= to_complex(tmpdata1,tmpdata2);
	
	
	wrdata1 <= std_logic_vector(complex_im(wrdata, dataBits))
			& std_logic_vector(complex_re(wrdata, dataBits));
	
	process(wrclk)
	begin
		 if(rising_edge(wrclk)) then
			  if(wren='1') then
					ram1(to_integer(wraddr)) <= wrdata1;
			  end if;
		 end if;
	end process;
end a;
