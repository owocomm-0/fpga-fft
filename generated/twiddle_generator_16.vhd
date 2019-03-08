
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity twiddleGenerator16 is
	port(clk: in std_logic;
			twAddr: in unsigned(4-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of twiddleGenerator16 is
	constant romDepthOrder: integer := 4;
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
"00000000000000100000000000" , "00011000100000011101100100" , "00101101010000010110101000" , "00111011001000001100010000" , "01000000000000000000000000" , "00111011001001110011110000" , "00101101010001101001011000" , "00011000100001100010011100" , "00000000000001100000000000" , "11100111100001100010011100"
, "11010010110001101001011000" , "11000100111001110011110000" , "11000000000000000000000000" , "11000100111000001100010000" , "11010010110000010110101000" , "11100111100000011101100100"
);
end a;

