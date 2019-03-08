
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity twiddleRom256 is
	port(clk: in std_logic;
			romAddr: in unsigned(5-1 downto 0);
			romData: out std_logic_vector(22-1 downto 0)
			);
end entity;
architecture a of twiddleRom256 is
	constant romDepthOrder: integer := 5;
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
"0000011001011111111111" , "0000110010011111111110" , "0001001011111111111010" , "0001100100111111110110" , "0001111101111111110001" , "0010010110111111101010" , "0010101111011111100010" , "0011001000011111011001" , "0011100000111111001110" , "0011111001011111000011"
, "0100010001011110110110" , "0100101001111110101000" , "0101000001011110011001" , "0101011001011110001000" , "0101110000111101110111" , "0110001000011101100100" , "0110011111011101010000" , "0110110110011100111011" , "0111001100111100100101" , "0111100010111100001110"
, "0111111000111011110110" , "1000001110111011011101" , "1000100100011011000010" , "1000111001011010100111" , "1001001101111010001010" , "1001100010011001101101" , "1001110110011001001111" , "1010001001111000101111" , "1010011101011000001111" , "1010101111110111101101"
, "1011000010010111001011" , "1011010100010110101000"
);
end a;

