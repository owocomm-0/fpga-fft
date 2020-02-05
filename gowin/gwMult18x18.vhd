library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- max width is 18x18
-- delay is 4 cycles
-- WARNING: UNTESTED
entity gwMult18x18 is
	generic(in1Bits, in2Bits, outBits: integer := 8;
			round: boolean := true);
	port(clk: in std_logic;
			in1,in2: in complex;
			out1: out complex
			);
end entity;
architecture a of gwMult18x18 is
	signal a,b,c,d: signed(17 downto 0);
	signal roundIn: signed(53 downto 0) := (53-outBits-1=>'1', others=>'0');
	signal outRe, outIm: signed(53 downto 0);
	constant shiftRight: integer := (in1Bits+in2Bits-outBits-2);

	component MULTADDALU18X18
        generic (
            A0REG: in bit := '0';
            B0REG: in bit := '0';
            A1REG: in bit := '0';
            B1REG: in bit := '0';
            CREG: in bit := '0';
            OUT_REG: in bit := '0';
            PIPE0_REG: in bit := '0';
            PIPE1_REG: in bit := '0';
            ASIGN0_REG: in bit := '0';
            BSIGN0_REG: in bit := '0';
            ASIGN1_REG: in bit := '0';
            BSIGN1_REG: in bit := '0';
            ACCLOAD_REG0: in bit := '0';
            ACCLOAD_REG1: in bit := '0';
            SOA_REG: in bit := '0';
            B_ADD_SUB: in bit := '0';
            C_ADD_SUB: in bit := '0';
            MULTADDALU18X18_MODE: in integer := 0;
            MULT_RESET_MODE: in string := "SYNC"
        );
        port (
            DOUT: out signed(53 downto 0);
            CASO: out signed(54 downto 0);
            SOA: out signed(17 downto 0);
            SOB: out signed(17 downto 0);
            C: in signed(53 downto 0);
            A0: in signed(17 downto 0);
            B0: in signed(17 downto 0);
            A1: in signed(17 downto 0);
            B1: in signed(17 downto 0);
            ASIGN: in std_logic_vector(1 downto 0);
            BSIGN: in std_logic_vector(1 downto 0);
            CASI: in signed(54 downto 0);
            ACCLOAD: in std_logic;
            SIA: in std_logic_vector(17 downto 0);
            SIB: in std_logic_vector(17 downto 0);
            CE: in std_logic;
            CLK: in std_logic;
            RESET: in std_logic;
            ASEL: in std_logic_vector(1 downto 0);
            BSEL: in std_logic_vector(1 downto 0)
        );
    end component;
begin
	a <= resize(complex_re(in1, in1Bits), 18);
	b <= resize(complex_im(in1, in1Bits), 18);
	c <= resize(complex_re(in2, in2Bits), 18);
	d <= resize(complex_im(in2, in2Bits), 18);

	-- ac - bd
	acbdDSP: MULTADDALU18X18
		generic map(
			A0REG => '1',
			B0REG => '1',
			A1REG => '1',
			B1REG => '1',
			CREG => '1',
			PIPE0_REG => '1',
			PIPE1_REG => '1',
			OUT_REG => '1',
			ASIGN0_REG => '0',
			ASIGN1_REG => '0',
			ACCLOAD_REG0 => '0',
			ACCLOAD_REG1 => '0',
			BSIGN0_REG => '0',
			BSIGN1_REG => '0',
			SOA_REG => '0',
			B_ADD_SUB => '1',
			C_ADD_SUB => '0',
			MULTADDALU18X18_MODE => 0,
			MULT_RESET_MODE => "SYNC")
		port map(
			DOUT => outRe,
			CASO => open,
			SOA => open,
			SOB => open,
			C => roundIn,
			A0 => a,
			B0 => c,
			A1 => b,
			B1 => d,
			ASIGN => "11",
			BSIGN => "11",
			CASI => (others=>'0'),
			ACCLOAD => '0',
			SIA => (others=>'0'),
			SIB => (others=>'0'),
			CE => '1',
			CLK => clk,
			RESET => '0',
			ASEL => "00",
			BSEL => "00");

	-- ad + bc
	adbcDSP: MULTADDALU18X18
		generic map(
			A0REG => '1',
			B0REG => '1',
			A1REG => '1',
			B1REG => '1',
			CREG => '1',
			PIPE0_REG => '1',
			PIPE1_REG => '1',
			OUT_REG => '1',
			ASIGN0_REG => '0',
			ASIGN1_REG => '0',
			ACCLOAD_REG0 => '0',
			ACCLOAD_REG1 => '0',
			BSIGN0_REG => '0',
			BSIGN1_REG => '0',
			SOA_REG => '0',
			B_ADD_SUB => '0',
			C_ADD_SUB => '0',
			MULTADDALU18X18_MODE => 0,
			MULT_RESET_MODE => "SYNC")
		port map(
			DOUT => outIm,
			CASO => open,
			SOA => open,
			SOB => open,
			C => roundIn,
			A0 => a,
			B0 => d,
			A1 => b,
			B1 => c,
			ASIGN => "11",
			BSIGN => "11",
			CASI => (others=>'0'),
			ACCLOAD => '0',
			SIA => (others=>'0'),
			SIB => (others=>'0'),
			CE => '1',
			CLK => clk,
			RESET => '0',
			ASEL => "00",
			BSEL => "00");
	out1 <= to_complex(outRe(outRe'left downto shiftRight),
					outIm(outIm'left downto shiftRight));
end a;
