--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.dsp48e1_largeMultAdd;

--  Defines a design entity, without any ports.
entity test_dsp48e1_mult is
end test_dsp48e1_mult;

architecture behaviour of test_dsp48e1_mult is
	signal clk: std_logic := '0';
	signal a: signed(24 downto 0);
	signal b: signed(35 downto 0);
	signal c,p: signed(65 downto 0);
begin
	tr: entity dsp48e1_largeMultAdd
			port map(clk,a,b,c,p);
	process
		variable l : line;
	begin
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		a <= to_signed(5, a'length);
		b <= to_signed(10000008, b'length);
		c <= to_signed(0, c'length);
		
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		a <= to_signed(0, a'length);
		b <= to_signed(0, b'length);
		c <= to_signed(0, c'length);
		
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		c <= resize(X"462C56DF9A800", c'length); -- 1234500000000000
		
		wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		
		c <= to_signed(0, c'length);
		
		for I in 0 to 20 loop
			wait for 1 ns; clk <= '0'; wait for 1 ns; clk <= '1';
		end loop;
		
		wait;
	end process;
end behaviour;
