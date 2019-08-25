
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft1024_wide;
use work.fft1024_wide_ireorderer4;
use work.fft1024_wide_oreorderer4;
use work.sr_unsigned;
use work.transposer;
use work.twiddleAddrGenLarge;
use work.twiddleGenerator;
use work.twiddleRom2048;
use work.twiddleGeneratorPartial512;
use work.dsp48e1_complexMultiply;

-- delay is 9461
-- twMultEnable enables the twiddle pre-multiply.
-- inTranspose and outTranspose enable the input/output burst transposers.
entity fft1024_wide_large4 is
	generic(dataBits: integer := 24; twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(20-1 downto 0);
		twMultEnable, inTranspose, outTranspose: in std_logic;
		dout: out complex);
end entity;
architecture ar of fft1024_wide_large4 is
	signal din1: complex;
	signal ph: unsigned(20-1 downto 0);
	signal ibreorder_dout, twMult_dout, ireorder_dout, core_dout, oreorder_dout, obreorder_dout, twOut: complex;
	signal ibreorder_phase, tw_phase, ireorder_phase, core_phase, oreorder_phase, obreorder_phase: unsigned(20-1 downto 0);
	signal twX, twY, twX1, twY1: unsigned(10-1 downto 0);
	signal twFineY, twFineY1: unsigned(2-1 downto 0);
	signal twIA, twIANext, twIB, twIBNext: unsigned(20-1 downto 0);
	signal twAddr, twAddr0: unsigned(20-1 downto 0);

	signal twAddrUpper: unsigned(11-1 downto 0);
	signal twAddrLower, twAddrLower0: unsigned(9-1 downto 0);
	signal twDataLower, twDataUpper: complex;

	signal romAddrUpper: unsigned(11-4 downto 0);
	signal romDataUpper: std_logic_vector(twBits*2-3 downto 0);

	signal twMultEnable_latch, inTranspose_latch, outTranspose_latch: boolean;
	signal twMultEnable1,inTranspose1,outTranspose1: std_logic;

	constant twDelay: integer := 16;
	constant cumDelay_ibreorder: integer := 0;
	constant cumDelay_tw: integer := cumDelay_ibreorder + 16;
	constant cumDelay_ireorder: integer := cumDelay_tw + 9;
	constant cumDelay_core: integer := cumDelay_ireorder + 4096;
	constant cumDelay_oreorder: integer := cumDelay_core + 1227;
	constant cumDelay_obreorder: integer := cumDelay_oreorder + 4096;
begin
	twMultEnable1 <= twMultEnable when rising_edge(clk);
	din1 <= din when rising_edge(clk);
	inTranspose1 <= inTranspose when rising_edge(clk);
	outTranspose1 <= outTranspose when rising_edge(clk);
	ph <= phase when rising_edge(clk);

	ibreorder_phase <= phase when rising_edge(clk);
	tw_phase <= ph - cumDelay_tw + 1 when rising_edge(clk);
	ireorder_phase <= ph - cumDelay_ireorder + 1 when rising_edge(clk);
	core_phase <= ph - cumDelay_core + 1 when rising_edge(clk);
	oreorder_phase <= ph - cumDelay_oreorder + 1 when rising_edge(clk);
	obreorder_phase <= ph - cumDelay_obreorder + 1 when rising_edge(clk);


	ibreorder: entity transposer
		generic map(N1=>2, N2=>2, dataBits=>dataBits)
		port map(clk=>clk,
				phase=>ibreorder_phase(4-1 downto 0),
				din=>din1,
				reorderEnable=>inTranspose1,
				dout=>ibreorder_dout);


	twAddrGen: entity twiddleAddrGenLarge
		generic map(twDelay=>twDelay-16,
					subOrder=>10,
					rowsOrder=>2)
		port map(clk=>clk,
				phase=>ibreorder_phase,
				twMultEnable=>twMultEnable1,
				twAddr=>twAddr);

	twAddrUpper <= twAddr(twAddr'left downto twAddrLower'length);
	twAddrLower0 <= twAddr(twAddrLower'range);

	-- delay twAddrLower because the upper twiddle generator has more delay
	del_twAddrLower: entity sr_unsigned
		generic map(len=>5, bits=>twAddrLower'length)
		port map(clk=>clk, din=>twAddrLower0, dout=>twAddrLower);

	twUpper: entity twiddleGenerator
		generic map(twiddleBits=>twBits, depthOrder=>twAddrUpper'length)
		port map(clk=>clk, rdAddr=>twAddrUpper, rdData=>twDataUpper,
				romAddr=>romAddrUpper, romData=>romDataUpper);
	romUpper: entity twiddleRom2048
		generic map(twBits=>twBits)
		port map(clk=>clk, romAddr=>romAddrUpper, romData=>romDataUpper);

	twLower: entity twiddleGeneratorPartial512
		generic map(twBits=>twBits)
		port map(clk=>clk, twAddr=>twAddrLower, twData=>twDataLower);

	twGenMult: entity dsp48e1_complexMultiply
		generic map(in1Bits=>twBits+1, in2Bits=>twBits+1,
					outBits=>twBits+1, round=>true)
		port map(clk=>clk, in1=>twDataUpper, in2=>twDataLower, out1=>twOut);


	twMult: entity dsp48e1_complexMultiply
		generic map(in1Bits=>twBits+1, in2Bits=>dataBits, outBits=>dataBits)
		port map(clk=>clk, in1=>twOut, in2=>ibreorder_dout, out1=>twMult_dout);

	ireorder: entity fft1024_wide_ireorderer4
		generic map(dataBits=>dataBits)
		port map(clk=>clk,
				phase=>ireorder_phase(12-1 downto 0),
				din=>twMult_dout,
				dout=>ireorder_dout);

	core: entity fft1024_wide
		generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk,
				phase=>core_phase(10-1 downto 0),
				din=>ireorder_dout, dout=>core_dout);

	oreorder: entity fft1024_wide_oreorderer4
		generic map(dataBits=>dataBits)
		port map(clk=>clk,
				phase=>oreorder_phase(12-1 downto 0),
				din=>core_dout, dout=>oreorder_dout);

	obreorder: entity transposer
		generic map(N1=>2, N2=>2, dataBits=>dataBits)
		port map(clk=>clk,
				phase=>obreorder_phase(4-1 downto 0),
				din=>oreorder_dout,
				reorderEnable=>outTranspose1,
				dout=>obreorder_dout);
	dout <= obreorder_dout;
end ar;
