
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.twiddleAddrGen;
use work.transposer;
use work.twiddleGenerator;
use work.twiddleRom64;
use work.dsp48e1_complexMultiply;
use work.fft1024_wide_sub16;
use work.fft4_serial7;

-- data input bit order: (5 downto 0) [1,0,3,2,5,4]
-- data output bit order: (5 downto 0) [0,1,2,3,4,5]
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 131
entity fft1024_wide_sub64 is
	generic(dataBits: integer := 24;
			twBits: integer := 12;
			inverse: boolean := true);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(6-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_wide_sub64 is
	signal sub1din, sub1dout, sub2din, sub2dout: complex;
	signal sub1phase: unsigned(4-1 downto 0);
	signal sub2phase: unsigned(2-1 downto 0);
	constant N: integer := 64;
	constant dataBitsIntern: integer := dataBits + 0;
	constant dataBitsOut: integer := dataBits + 0;
	constant twiddleBits: integer := twBits;
	constant twiddleDelay: integer := 7;
	constant order: integer := 6;
	constant delay: integer := 131;
	constant sub1dataBits: integer := dataBits;
	constant sub2dataBits: integer := dataBitsIntern;


	--=======================================

	signal ph1, ph2, ph3: unsigned(order-1 downto 0);
	signal rbIn, transpOut: complex;
	signal bitPermIn,bitPermOut: unsigned(4-1 downto 0);

	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;

	signal romAddr: unsigned(order-4 downto 0);
	signal romData: std_logic_vector(twiddleBits*2-3 downto 0);

begin
	sub1din <= din;
	sub1phase <= phase(4-1 downto 0);

	ph1 <= phase-47+1 when rising_edge(clk);

	transp: entity transposer
		generic map(N1=>2, N2=>4, dataBits=>dataBitsIntern)
		port map(clk=>clk, din=>sub1dout, phase=>ph1, dout=>transpOut);

	ph2 <= ph1;

	twAG: entity twiddleAddrGen
		generic map(
			subOrder1=>4,
			subOrder2=>2,
			twiddleDelay=>twiddleDelay,
			customSubOrder=>true)
		port map(
			clk=>clk,
			phase=>ph2,
			twAddr=>twAddr,
			bitPermIn=>bitPermIn,
			bitPermOut=>bitPermOut);

	twMult: entity dsp48e1_complexMultiply
		generic map(in1Bits=>twiddleBits+1,
					in2Bits=>dataBitsIntern,
					outBits=>dataBitsIntern)
		port map(clk=>clk, in1=>twData, in2=>transpOut, out1=>sub2din);

	ph3 <= ph2-9+1 when rising_edge(clk);
	sub2phase <= ph3(2-1 downto 0);
	dout <= sub2dout;
	bitPermOut <= bitPermIn(0)&bitPermIn(1)&bitPermIn(2)&bitPermIn(3);

	tw: entity twiddleGenerator
		generic map(twiddleBits, order, inverse=>inverse)
		port map(clk, twAddr, twData, romAddr, romData);

	rom: entity twiddleRom64 generic map(twBits=>twiddleBits)
		port map(clk, romAddr,romData);
	sub1: entity fft1024_wide_sub16 generic map(dataBits=>sub1dataBits, twBits=>twBits, inverse=>inverse)
		port map(clk=>clk, din=>sub1din, phase=>sub1phase, dout=>sub1dout);
	sub2inst: entity fft4_serial7
		generic map(dataBits=>sub2dataBits, scale=>SCALE_DIV_SQRT_N, inverse=>inverse)
		port map(clk=>clk, din=>sub2din, phase=>sub2phase, dout=>sub2dout);

end ar;
