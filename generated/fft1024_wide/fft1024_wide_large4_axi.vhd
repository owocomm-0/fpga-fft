
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.clockGating;
use work.axiBlockProcessorAdapter2;
use work.fft1024_wide_large4;

entity fft1024_wide_large4_axi is
	generic(dataBits: integer := 32; twBits: integer := 24);
	port(aclk, aclk_unbuffered, reset: in std_logic;
		din_tvalid: in std_logic;
		din_tready: out std_logic;
		din_tdata: in std_logic_vector(dataBits*2-1 downto 0);

		dout_tvalid: out std_logic;
		dout_tready: in std_logic;
		dout_tdata: out std_logic_vector(dataBits*2-1 downto 0);

		inFlags, outFlags: in std_logic_vector(3 downto 0));
end entity;
architecture ar of fft1024_wide_large4_axi is
	constant largeOrder: integer := 20;
	signal fftClk_gated: std_logic;
	signal bp_ce, bp_ostrobe: std_logic;
	signal inFlags1: std_logic_vector(3 downto 0);
	signal bp_ce1, bp_ce2: std_logic;
	signal bp_indata, bp_outdata, bp_indata1, bp_indata2: std_logic_vector(dataBits*2-1 downto 0);
	signal bp_inphase, bp_inphase1, bp_inphase2, gated_inphase: unsigned(largeOrder-1 downto 0);
	signal gated_din, gated_dout: complex;
begin
	adapter: entity axiBlockProcessorAdapter2
		generic map(frameSizeOrder=>largeOrder, wordWidth=>dataBits*2, processorDelay=>9461)
		port map (
			aclk => aclk,
			bp_ce => bp_ce,
			bp_indata => bp_indata,
			bp_inphase => bp_inphase,
			bp_ostrobe => bp_ostrobe,
			bp_outdata => bp_outdata,
			doFlush => '1',
			inp_tdata => din_tdata,
			inp_tready => din_tready,
			inp_tvalid => din_tvalid,
			outp_tdata => dout_tdata,
			outp_tready => dout_tready,
			outp_tvalid => dout_tvalid,
			reset => reset);

	bp_ce1 <= bp_ce when rising_edge(aclk);
	bp_ce2 <= bp_ce1 when rising_edge(aclk);
	bp_indata1 <= bp_indata when rising_edge(aclk);
	bp_indata2 <= bp_indata1 when rising_edge(aclk);
	bp_inphase1 <= unsigned(bp_inphase) when rising_edge(aclk);
	bp_inphase2 <= unsigned(bp_inphase1) when rising_edge(aclk);
	bp_ostrobe <= bp_ce2;

	cg: entity clockGating
		port map(clkInUnbuffered=>aclk_unbuffered,
				ce=>bp_ce2,
				clkOutGated=>fftClk_gated);

	-- start of gated clock domain
	gated_din <= to_complex(signed(bp_indata2(dataBits-1 downto 0)), signed(bp_indata2(dataBits*2-1 downto dataBits)));
	gated_inphase <= bp_inphase2;

	inFlags1 <= inFlags when gated_inphase=(2**(gated_inphase'length) - 20) and rising_edge(fftClk_gated);

	fft: entity fft1024_wide_large4
		generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>fftClk_gated, din=>gated_din,
				twMultEnable=>inFlags1(2),
				inTranspose=>'0', outTranspose=>'1',
				phase=>gated_inphase,
				dout=>gated_dout);

	bp_outdata <= std_logic_vector(resize(gated_dout.im, dataBits)) &
					std_logic_vector(resize(gated_dout.re, dataBits));
end ar;
