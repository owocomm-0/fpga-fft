--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.reorderBuffer;

--  Defines a design entity, without any ports.
entity test_reorderBuffer is
end test_reorderBuffer;

architecture behaviour of test_reorderBuffer is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(3 downto 0);
	signal dout: complex;
	
	signal bitPermIn: unsigned(3 downto 0);
	signal bitPermCount: unsigned(1 downto 0);
	signal bitPermOut: unsigned(3 downto 0);
begin
	rb: entity reorderBuffer generic map(4, 24, 0)
		port map(clk, din, phase, dout,
				bitPermIn, bitPermCount, bitPermOut);
	
	bitPermOut <= rotate_left(bitPermIn, to_integer(bitPermCount));
	
	process
		variable l : line;
		variable i1,i2,row,col: integer := 0;
	begin
		phase <= (others=>'0');
		for I in 0 to 15 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to 16*5-1 loop
			i1 := I/16;
			i2 := I rem 16;
			din <= to_complex((i1+1)*100 + i2, 0);
			
			if I >= 16 then
				write(output, integer'image(to_integer(dout.re)) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
