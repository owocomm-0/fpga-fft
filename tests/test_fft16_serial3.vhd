--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft16_serial3;

--  Defines a design entity, without any ports.
entity test_fft16_serial3 is
end test_fft16_serial3;

architecture behaviour of test_fft16_serial3 is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(3 downto 0);
	signal dout: complex;
	signal debug1: integer;
begin
	fft: entity fft16_serial3 port map(
			clk,din,phase,dout,open);
	process
		variable l : line;
		variable i1,i2,row,col: integer := 0;
		type arr_t is array(0 to 63) of integer;
		variable arr: arr_t;
	begin
		for I in 0 to 31 loop
			arr(I*2) := I*6;
			arr(I*2+1) := I*7;
		end loop;
		phase <= "0000";
		
		write(output, "FUCK2" & LF);
		for I in 0 to 63 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		write(output, "FUCK" & LF);
		
		for I in 0 to 63 loop
			i1 := I rem 16;
			i2 := I rem 32;
			
			i1 := (i1 rem 4)*4 + i1/4;
			
			din <= to_complex(arr(i1*2),arr(i1*2+1));
			if I >= 40 then
				write(output, complex_str(dout) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
