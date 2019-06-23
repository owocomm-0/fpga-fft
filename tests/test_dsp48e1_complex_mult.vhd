--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.dsp48e1_complexMultiply;

--  Defines a design entity, without any ports.
entity test_dsp48e1_complexMult is
end test_dsp48e1_complexMult;

architecture behaviour of test_dsp48e1_complexMult is
	signal clk: std_logic := '0';
	signal a,b,res: complex;
begin
	tr: entity dsp48e1_complexMultiply
			generic map(25, 32, 32)
			port map(clk,a,b,res);
	process
		variable l : line;
	begin
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		a <= to_complex(3, 3);
		b <= to_complex(-1, -1);
		
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		a <= to_complex(0, 0);
		b <= to_complex(0, 0);
		
		for I in 0 to 20 loop
			wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		end loop;
		
		wait;
	end process;
end behaviour;
