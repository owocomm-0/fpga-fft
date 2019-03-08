--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use work.fft4;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4;

--  Defines a design entity, without any ports.
entity test_fft4 is
end test_fft4;

architecture behaviour of test_fft4 is
	signal clk: std_logic := '0';
	signal din: complexArray(3 downto 0);
	signal dout: complexArray(3 downto 0);
begin
	fft: entity fft4 port map(clk,din,dout);
	process
		variable l : line;
	begin
		din(0) <= to_complex(123,0);
		din(1) <= to_complex(123,0);
		din(2) <= to_complex(123,0);
		din(3) <= to_complex(123,0);
		
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din(0) <= to_complex(0,123);
		din(1) <= to_complex(0,0);
		din(2) <= to_complex(0,123);
		din(3) <= to_complex(0,0);
		
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		for I in 0 to 3 loop
			write(output, integer'image(dout(I).re) & " " & integer'image(dout(I).im) & LF);
		end loop;
		write(output, "" & LF);
		
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		for I in 0 to 3 loop
			write(output, integer'image(dout(I).re) & " " & integer'image(dout(I).im) & LF);
		end loop;
		
		wait;
	end process;
end behaviour;
