
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.clockGating;
use work.axiBlockProcessorAdapter2;
use work.fft1024_wide_large4;

entity fft1024_wide_large4axi is
	generic(dataBits: integer := 32;
			twBits: integer := 24;
			tuserWidth: integer := 7;
			twMultFlagNum: integer := AXIFFT_FLAG_TWIDDLE_MULTIPLY;
			ibTransposeFlagNum: integer := AXIFFT_FLAG_INPUT_BURST_TRANSPOSE;
			obTransposeFlagNum: integer := AXIFFT_FLAG_OUTPUT_BURST_TRANSPOSE);

	port(aclk, aclk_unbuffered, reset: in std_logic;
		din_tvalid: in std_logic;
		din_tready: out std_logic;
		din_tdata: in std_logic_vector(dataBits*2-1 downto 0);
		din_tuser: in std_logic_vector(tuserWidth-1 downto 0);

		dout_tvalid: out std_logic;
		dout_tready: in std_logic;
		dout_tdata: out std_logic_vector(dataBits*2-1 downto 0);
		dout_tuser: out std_logic_vector(tuserWidth-1 downto 0)
	);
end entity;
architecture ar of fft1024_wide_large4axi is
	attribute X_INTERFACE_INFO : string;
	attribute X_INTERFACE_PARAMETER : string;
	attribute X_INTERFACE_INFO of aclk : signal is "xilinx.com:signal:clock:1.0 signal_clock CLK";
	attribute X_INTERFACE_INFO of aclk_unbuffered : signal is "xilinx.com:signal:clock:1.0 signal_clock CLK";
	attribute X_INTERFACE_PARAMETER of aclk: signal is "ASSOCIATED_BUSIF din:dout:inFlags:outFlags";

	attribute X_INTERFACE_INFO of din_tvalid: signal is "xilinx.com:interface:axis_rtl:1.0 din tvalid";
	attribute X_INTERFACE_INFO of din_tready: signal is "xilinx.com:interface:axis_rtl:1.0 din tready";
	attribute X_INTERFACE_INFO of din_tdata: signal is "xilinx.com:interface:axis_rtl:1.0 din tdata";
	attribute X_INTERFACE_INFO of din_tuser: signal is "xilinx.com:interface:axis_rtl:1.0 din tuser";
	attribute X_INTERFACE_INFO of dout_tvalid: signal is "xilinx.com:interface:axis_rtl:1.0 dout tvalid";
	attribute X_INTERFACE_INFO of dout_tready: signal is "xilinx.com:interface:axis_rtl:1.0 dout tready";
	attribute X_INTERFACE_INFO of dout_tdata: signal is "xilinx.com:interface:axis_rtl:1.0 dout tdata";
	attribute X_INTERFACE_INFO of dout_tuser: signal is "xilinx.com:interface:axis_rtl:1.0 dout tuser";

	constant largeOrder: integer := 20;
	signal fftClk_gated: std_logic;
	signal bp_ce, bp_ostrobe: std_logic;
	signal inFlags1, inFlags2: std_logic_vector(tuserWidth-1 downto 0);
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

	inFlags1 <= din_tuser when din_tvalid='1' and rising_edge(aclk);
	inFlags2 <= inFlags1 when gated_inphase=(2**(gated_inphase'length) - 20) and rising_edge(fftClk_gated);
	dout_tuser <= inFlags2 when rising_edge(fftClk_gated);

	fft: entity fft1024_wide_large4
		generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>fftClk_gated, din=>gated_din,
				twMultEnable=>inFlags2(twMultFlagNum),
				inTranspose=>inFlags2(ibTransposeFlagNum),
				outTranspose=>inFlags2(obTransposeFlagNum),
				phase=>gated_inphase,
				dout=>gated_dout);

	bp_outdata <= std_logic_vector(resize(gated_dout.im, dataBits)) &
					std_logic_vector(resize(gated_dout.re, dataBits));
end ar;
