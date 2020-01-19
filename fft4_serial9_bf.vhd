library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 1 cycle; input is unregistered
entity fft4_serial9_bf1 is
	generic(dataBits: integer);
	port(clk: in std_logic;
		A, B0, B1: in complex;
		selRe, selIm: in std_logic;
		dout: out complex
		);
end entity;

architecture a of fft4_serial9_bf1 is
	-- lower bits of result1 are duplicated
	--constant dupBits: integer := 4;

	signal operandA, operandB: complex;
	signal resultRe, resultIm: signed(COMPLEXWIDTH downto 0);
	signal result, result1: complex;
	signal result1Dup: complex;
	signal FB: complex;

	attribute EQUIVALENT_REGISTER_REMOVAL: string;
	attribute EQUIVALENT_REGISTER_REMOVAL of result1: signal is "false";
	attribute EQUIVALENT_REGISTER_REMOVAL of result1Dup: signal is "false";
begin
	--FB.re <= result1.re(result1.re'left downto dupBits) & result1Dup.re(dupBits-1 downto 0);
	--FB.im <= result1.im(result1.im'left downto dupBits) & result1Dup.im(dupBits-1 downto 0);
	FB <= result1;

	operandA.re <= A.re when selRe='0' else FB.re;
	operandA.im <= A.im when selIm='0' else FB.im;

	-- A - B = A + !B + 1
	operandB.re <= B0.re when selRe='0' else
					not shift_left(B1.re, 1);
	operandB.im <= B0.im when selIm='0' else
					not shift_left(B1.im, 1);

	resultRe <= (operandA.re & selRe) + (operandB.re & selRe);
	resultIm <= (operandA.im & selIm) + (operandB.im & selIm);
	result <= to_complex(resultRe(resultRe'left downto 1), resultIm(resultIm'left downto 1));

	result1 <= keepNBits(result, dataBits) when rising_edge(clk);
	result1Dup <= keepNBits(result, dataBits) when rising_edge(clk);

	dout <= result1;
end a;


library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 1 cycle; input is unregistered
entity fft4_serial9_bf2 is
	generic(dataBits: integer);
	port(clk: in std_logic;
		A, B0, B1: in complex;
		selBNext: in std_logic;
		subtractReNext, subtractImNext: in std_logic;
		dout: out complex
		);
end entity;

architecture a of fft4_serial9_bf2 is
	-- lower bits will be controlled with a dedicated sel and subtract register
	constant lowerBits: integer := 8;
	signal selBReLower, selBReUpper, selBImLower, selBImUpper: std_logic;
	signal subtractReLower, subtractReUpper, subtractImLower, subtractImUpper: std_logic;

	attribute keep: string;
	attribute keep of selBReLower: signal is "true";
	attribute keep of selBReUpper: signal is "true";
	attribute keep of selBImLower: signal is "true";
	attribute keep of selBImUpper: signal is "true";
	attribute keep of subtractReLower: signal is "true";
	attribute keep of subtractReUpper: signal is "true";
	attribute keep of subtractImLower: signal is "true";
	attribute keep of subtractImUpper: signal is "true";

	signal operandB: complex;
	signal tmpRe, tmpIm: signed(COMPLEXWIDTH downto 0);
	signal tmp: complex;
begin
	selBReLower <= selBNext when rising_edge(clk);
	selBReUpper <= selBNext when rising_edge(clk);
	selBImLower <= selBNext when rising_edge(clk);
	selBImUpper <= selBNext when rising_edge(clk);

	subtractReLower <= subtractReNext when rising_edge(clk);
	subtractReUpper <= subtractReNext when rising_edge(clk);
	subtractImLower <= subtractImNext when rising_edge(clk);
	subtractImUpper <= subtractImNext when rising_edge(clk);

	-- A - B = A + !B + 1
	operandB.re(lowerBits-1 downto 0) <=
		B0.re(lowerBits-1 downto 0) when subtractReLower='0' and selBReLower='0' else
		B1.re(lowerBits-1 downto 0) when subtractReLower='0' else
		not B0.re(lowerBits-1 downto 0) when selBReLower='0' else
		not B1.re(lowerBits-1 downto 0);

	operandB.re(COMPLEXWIDTH-1 downto lowerBits) <=
		B0.re(COMPLEXWIDTH-1 downto lowerBits) when subtractReUpper='0' and selBReUpper='0' else
		B1.re(COMPLEXWIDTH-1 downto lowerBits) when subtractReUpper='0' else
		not B0.re(COMPLEXWIDTH-1 downto lowerBits) when selBReUpper='0' else
		not B1.re(COMPLEXWIDTH-1 downto lowerBits);

	operandB.im(lowerBits-1 downto 0) <=
		B0.im(lowerBits-1 downto 0) when subtractImLower='0' and selBImLower='0' else
		B1.im(lowerBits-1 downto 0) when subtractImLower='0' else
		not B0.im(lowerBits-1 downto 0) when selBImLower='0' else
		not B1.im(lowerBits-1 downto 0);

	operandB.im(COMPLEXWIDTH-1 downto lowerBits) <=
		B0.im(COMPLEXWIDTH-1 downto lowerBits) when subtractImUpper='0' and selBImUpper='0' else
		B1.im(COMPLEXWIDTH-1 downto lowerBits) when subtractImUpper='0' else
		not B0.im(COMPLEXWIDTH-1 downto lowerBits) when selBImUpper='0' else
		not B1.im(COMPLEXWIDTH-1 downto lowerBits);

	tmpRe <= (A.re & subtractReLower) + (operandB.re & subtractReLower);
	tmpIm <= (A.im & subtractImLower) + (operandB.im & subtractImLower);
	tmp <= to_complex(tmpRe(tmpRe'left downto 1), tmpIm(tmpIm'left downto 1));

	dout <= keepNBits(tmp, dataBits) when rising_edge(clk);
end a;
