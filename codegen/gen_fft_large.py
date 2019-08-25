

from gen_fft_utils import *
from gen_fft_modules import *

class FFTLarge:
	def __init__(self, sub1, burstWidth, multiplier=None):
		if multiplier == None:
			multiplier = sub1.multiplier

		self.sub1 = sub1
		self.N = sub1.N**2
		self.multiplier = multiplier
		self.burstWidth = burstWidth

		breorderDelay = burstWidth**2
		reorderDelay = sub1.N * burstWidth
		twMultDelay = multiplier.delay()

		self._delay = 1 + 2*breorderDelay + 2*reorderDelay + twMultDelay + sub1.delay()
	
	def delay(self):
		return self._delay

	def genEntity(self, entityName, sub1Name):
		fftName = sub1Name
		burstWidth = self.burstWidth
		colBits = myLog2(self.sub1.N)
		rowBits = myLog2(burstWidth)
		breorderBits = rowBits*2
		reorderBits = colBits + rowBits
		totalBits = colBits*2
		burstLength = burstWidth**2
		multiplierEntity = self.multiplier.entity

		# twiddle generator is divided into two parts
		twUpperBits = colBits+1
		twLowerBits = colBits-1
		twUpperSize = 2**twUpperBits
		twLowerSize = 2**twLowerBits

		breorderDelay = burstLength
		reorderDelay = self.sub1.N * burstWidth
		twMultDelay = self.multiplier.delay()
		fftDelay = self.sub1.delay()
		delay = self.delay()

		# assume twUpperDelay >= twLowerDelay
		twUpperDelay = twiddleGeneratorDelay(twUpperSize) + twiddleRomDelay(twUpperSize)
		twLowerDelay = twiddleRomDelay(twLowerSize)
		assert twUpperDelay >= twLowerDelay
		twiddleDelay = twUpperDelay + self.multiplier.delay()
		twiddleDelayDiff = twUpperDelay - twLowerDelay

		code = '''
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.{fftName:s};
use work.{fftName:s}_ireorderer{burstWidth:d};
use work.{fftName:s}_oreorderer{burstWidth:d};
use work.sr_unsigned;
use work.transposer;
use work.twiddleAddrGenLarge;
use work.twiddleGenerator;
use work.twiddleRom{twUpperSize:d};
use work.twiddleGeneratorPartial{twLowerSize:d};
use work.{multiplierEntity:s};

-- delay is {delay:d}
-- twMultEnable enables the twiddle pre-multiply.
-- inTranspose and outTranspose enable the input/output burst transposers.
entity {entityName:s} is
	generic(dataBits: integer := 24; twBits: integer := 12);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned({totalBits:d}-1 downto 0);
		twMultEnable, inTranspose, outTranspose: in std_logic;
		dout: out complex);
end entity;
architecture ar of {entityName:s} is
	signal din1: complex;
	signal ph: unsigned({totalBits:d}-1 downto 0);
	signal ibreorder_dout, twMult_dout, ireorder_dout, core_dout, oreorder_dout, obreorder_dout, twOut: complex;
	signal ibreorder_phase, tw_phase, ireorder_phase, core_phase, oreorder_phase, obreorder_phase: unsigned({totalBits:d}-1 downto 0);
	signal twX, twY, twX1, twY1: unsigned({colBits:d}-1 downto 0);
	signal twFineY, twFineY1: unsigned({rowBits:d}-1 downto 0);
	signal twIA, twIANext, twIB, twIBNext: unsigned({totalBits:d}-1 downto 0);
	signal twAddr, twAddr0: unsigned({totalBits:d}-1 downto 0);

	signal twAddrUpper: unsigned({twUpperBits:d}-1 downto 0);
	signal twAddrLower, twAddrLower0: unsigned({twLowerBits:d}-1 downto 0);
	signal twDataLower, twDataUpper: complex;

	signal romAddrUpper: unsigned({twUpperBits:d}-4 downto 0);
	signal romDataUpper: std_logic_vector(twBits*2-3 downto 0);

	signal twMultEnable_latch, inTranspose_latch, outTranspose_latch: boolean;
	signal twMultEnable1,inTranspose1,outTranspose1: std_logic;

	constant twDelay: integer := {twiddleDelay:d};
	constant cumDelay_ibreorder: integer := 0;
	constant cumDelay_tw: integer := cumDelay_ibreorder + {breorderDelay:d};
	constant cumDelay_ireorder: integer := cumDelay_tw + {twMultDelay:d};
	constant cumDelay_core: integer := cumDelay_ireorder + {reorderDelay:d};
	constant cumDelay_oreorder: integer := cumDelay_core + {fftDelay:d};
	constant cumDelay_obreorder: integer := cumDelay_oreorder + {reorderDelay:d};
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
		generic map(N1=>{rowBits:d}, N2=>{rowBits:d}, dataBits=>dataBits)
		port map(clk=>clk,
				phase=>ibreorder_phase({breorderBits:d}-1 downto 0),
				din=>din1,
				reorderEnable=>inTranspose1,
				dout=>ibreorder_dout);


	twAddrGen: entity twiddleAddrGenLarge
		generic map(twDelay=>twDelay-{breorderDelay:d},
					subOrder=>{colBits:d},
					rowsOrder=>{rowBits:d})
		port map(clk=>clk,
				phase=>ibreorder_phase,
				twMultEnable=>twMultEnable1,
				twAddr=>twAddr);

	twAddrUpper <= twAddr(twAddr'left downto twAddrLower'length);
	twAddrLower0 <= twAddr(twAddrLower'range);

	-- delay twAddrLower because the upper twiddle generator has more delay
	del_twAddrLower: entity sr_unsigned
		generic map(len=>{twiddleDelayDiff:d}, bits=>twAddrLower'length)
		port map(clk=>clk, din=>twAddrLower0, dout=>twAddrLower);

	twUpper: entity twiddleGenerator
		generic map(twiddleBits=>twBits, depthOrder=>twAddrUpper'length)
		port map(clk=>clk, rdAddr=>twAddrUpper, rdData=>twDataUpper,
				romAddr=>romAddrUpper, romData=>romDataUpper);
	romUpper: entity twiddleRom{twUpperSize:d}
		generic map(twBits=>twBits)
		port map(clk=>clk, romAddr=>romAddrUpper, romData=>romDataUpper);

	twLower: entity twiddleGeneratorPartial{twLowerSize:d}
		generic map(twBits=>twBits)
		port map(clk=>clk, twAddr=>twAddrLower, twData=>twDataLower);

	twGenMult: entity {multiplierEntity:s}
		generic map(in1Bits=>twBits+1, in2Bits=>twBits+1,
					outBits=>twBits+1, round=>true)
		port map(clk=>clk, in1=>twDataUpper, in2=>twDataLower, out1=>twOut);


	twMult: entity {multiplierEntity:s}
		generic map(in1Bits=>twBits+1, in2Bits=>dataBits, outBits=>dataBits)
		port map(clk=>clk, in1=>twOut, in2=>ibreorder_dout, out1=>twMult_dout);

	ireorder: entity {fftName:s}_ireorderer{burstWidth:d}
		generic map(dataBits=>dataBits)
		port map(clk=>clk,
				phase=>ireorder_phase({reorderBits:d}-1 downto 0),
				din=>twMult_dout,
				dout=>ireorder_dout);

	core: entity {fftName:s}
		generic map(dataBits=>dataBits, twBits=>twBits)
		port map(clk=>clk,
				phase=>core_phase({colBits:d}-1 downto 0),
				din=>ireorder_dout, dout=>core_dout);

	oreorder: entity {fftName:s}_oreorderer{burstWidth:d}
		generic map(dataBits=>dataBits)
		port map(clk=>clk,
				phase=>oreorder_phase({reorderBits:d}-1 downto 0),
				din=>core_dout, dout=>oreorder_dout);

	obreorder: entity transposer
		generic map(N1=>{rowBits:d}, N2=>{rowBits:d}, dataBits=>dataBits)
		port map(clk=>clk,
				phase=>obreorder_phase({breorderBits:d}-1 downto 0),
				din=>oreorder_dout,
				reorderEnable=>outTranspose1,
				dout=>obreorder_dout);
	dout <= obreorder_dout;
end ar;
'''.format(**locals())

		return code
