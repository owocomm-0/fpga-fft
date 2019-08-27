library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- delay is 1 cycle; input is unregistered
entity fft4_serial8_bf is
	generic(dataBits: integer;
			roundPos: integer := 0);
	port(clk: in std_logic;
		dinA, dinB: in complex;
		subtractRe, subtractIm: in std_logic;
		roundRandRe, roundRandIm: in std_logic;
		dout: out complex
		);
end entity;

architecture a of fft4_serial8_bf is
	signal operandB: complex;
	signal tmp: complex;
	signal roundAddRe, roundAddIm: signed(roundPos downto 0);
begin

	-- A - B = A + !B + 1
	operandB.re <= dinB.re when subtractRe='0' else (not dinB.re);
	operandB.im <= dinB.im when subtractIm='0' else (not dinB.im);


g0: if roundPos=0 generate
		tmp.re <= dinA.re + dinB.re when subtractRe='0' else dinA.re - dinB.re;
		tmp.im <= dinA.im + dinB.im when subtractIm='0' else dinA.im - dinB.im;
	end generate;
g1: if roundPos=1 generate
		tmp.re <= dinA.re + operandB.re + signed'('0' & subtractRe) + signed'('0' & roundRandRe);
		tmp.im <= dinA.im + operandB.im + signed'('0' & subtractIm) + signed'('0' & roundRandIm);
	end generate;
g2: if roundPos=2 generate
		roundAddRe <= "0" & roundRandRe & (not roundRandRe);
		roundAddIm <= "0" & roundRandIm & (not roundRandIm);
		tmp.re <= dinA.re + dinB.re + roundAddRe when subtractRe='0' else
					dinA.re - dinB.re + roundAddRe;
		tmp.im <= dinA.im + dinB.im + roundAddIm when subtractIm='0' else
					dinA.im - dinB.im + roundAddIm;
	end generate;
	dout <= keepNBits(tmp, dataBits) when rising_edge(clk);
end a;
