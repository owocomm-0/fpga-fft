
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity twiddleRom128 is
	port(clk: in std_logic;
			romAddr: in unsigned(4-1 downto 0);
			romData: out std_logic_vector(22-1 downto 0)
			);
end entity;
architecture a of twiddleRom128 is
	constant romDepthOrder: integer := 4;
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := 22;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others=>'0');
begin
	addr1 <= romAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	romData <= data1;
	rom <= (
"0000110010011111111110" , "0001100100111111110110" , "0010010110111111101010" , "0011001000011111011001" , "0011111001011111000011" , "0100101001111110101000" , "0101011001011110001000" , "0110001000011101100100" , "0110110110011100111011" , "0111100010111100001110"
, "1000001110111011011101" , "1000111001011010100111" , "1001100010011001101101" , "1010001001111000101111" , "1010101111110111101101" , "1011010100010110101000"
);
end a;

