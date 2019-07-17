library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.twiddleGenerator;
use work.twiddleGeneratorLarge;
use work.twiddleRom1024;
use work.twiddleGenerator1024;
use work.twiddleGeneratorPartial1024;

-- delay is subDelay+multDelay cycles
entity twiddleGenerator1M is
	generic(twiddleBits: integer := 8);
	port(clk: in std_logic;
			rdAddr: in unsigned(20-1 downto 0);
			rdData: out complex
			);
end entity;
architecture a of twiddleGenerator1M is
	constant depthOrder: integer := 20;
	constant subDepthOrder: integer := depthOrder/2;
	signal sub1Addr, sub2Addr: unsigned(depthOrder/2-1 downto 0);
	signal sub1Data, sub2Data: complex;
	signal sub1RomAddr: unsigned(subDepthOrder-4 downto 0);
	signal sub1RomData: std_logic_vector(twiddleBits*2-3 downto 0);
begin
	--tw1: entity twiddleGenerator generic map(twiddleBits, subDepthOrder)
	--	port map(clk, sub1Addr, sub1Data, sub1RomAddr, sub1RomData);
	--rom: entity twiddleRom1024 port map(clk, sub1RomAddr,sub1RomData);
	tw1: entity twiddleGenerator1024 port map(clk, sub1Addr, sub1Data);
	tw2: entity twiddleGeneratorPartial1024 port map(clk, sub2Addr, sub2Data);
	twg: entity twiddleGeneratorLarge
		generic map(twiddleBits=>twiddleBits, depthOrder=>depthOrder)
		port map(clk=>clk, rdAddr=>rdAddr, rdData=>rdData,
				sub1Addr=>sub1Addr, sub2Addr=>sub2Addr,
				sub1Data=>sub1Data, sub2Data=>sub2Data);
end a;
