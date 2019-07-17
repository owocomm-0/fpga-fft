library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;
use work.complexMultiply;
use work.complexMultiplyLarge;

-- delay is subDelay+multDelay cycles
entity twiddleGeneratorLarge is
	generic(twiddleBits: integer := 8;
				-- real depth is 2^depth_order
				-- depthOrder must be divisible by 2
				depthOrder: integer := 20);
	port(clk: in std_logic;
			-- read side; synchronous to rdclk
			rdAddr: in unsigned(depthOrder-1 downto 0);
			rdData: out complex;
			
			sub1Addr, sub2Addr: out unsigned(depthOrder/2-1 downto 0);
			sub1Data, sub2Data: in complex
			);
end entity;
architecture a of twiddleGeneratorLarge is
	constant subDepthOrder: integer := depthOrder/2;
begin
	sub1Addr <= rdAddr(depthOrder-1 downto depthOrder/2);
	sub2Addr <= rdAddr(depthOrder/2-1 downto 0);
	mult: entity complexMultiplyLarge
		generic map(in1Bits=>twiddleBits+1, in2Bits=>twiddleBits+1,
					outBits=>twiddleBits+1, round=>true)
		port map(clk=>clk, in1=>sub1Data, in2=>sub2Data, out1=>rdData);
end a;
