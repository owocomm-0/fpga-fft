
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity twiddleGenerator32 is
	port(clk: in std_logic;
			twAddr: in unsigned(5-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of twiddleGenerator32 is
	constant romDepthOrder: integer := 5;
	constant romDepth: integer := 2**romDepthOrder;
	constant twiddleBits: integer := 13;
	constant romWidth: integer := twiddleBits*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others=>'0');
begin
	addr1 <= twAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	twData <= to_complex(signed(data1(twiddleBits-1 downto 0)), signed(data1(data1'left downto twiddleBits)));
	rom <= (
"00000000000000100000000000" , "00001100100000011111011001" , "00011000100000011101100100" , "00100011100100011010100111" , "00101101010000010110101000" , "00110101001110010001110010" , "00111011001000001100010000" , "00111110110010000110010000" , "01000000000000000000000000" , "00111110110011111001110000"
, "00111011001001110011110000" , "00110101001111101110001110" , "00101101010001101001011000" , "00100011100101100101011001" , "00011000100001100010011100" , "00001100100001100000100111" , "00000000000001100000000000" , "11110011100001100000100111" , "11100111100001100010011100" , "11011100011101100101011001"
, "11010010110001101001011000" , "11001010110011101110001110" , "11000100111001110011110000" , "11000001001111111001110000" , "11000000000000000000000000" , "11000001001110000110010000" , "11000100111000001100010000" , "11001010110010010001110010" , "11010010110000010110101000" , "11011100011100011010100111"
, "11100111100000011101100100" , "11110011100000011111011001"
);
end a;

