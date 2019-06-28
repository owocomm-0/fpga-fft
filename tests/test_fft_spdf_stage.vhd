--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft_spdf_stage;

--  Defines a design entity, without any ports.
entity test_fft_spdf_stage is
end entity;

architecture behaviour of test_fft_spdf_stage is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(3 downto 0);
	signal dout: complex;
begin
	fft: entity fft_spdf_stage
		generic map(4, 16)
		port map(clk,din,phase,dout);
	
	process
		variable l: line;
		variable I: integer;
		
		type arr_t is array(0 to 31) of integer;
		variable arr: arr_t;
	begin
		for I in 0 to 15 loop
			arr(I*2) := I;
			arr(I*2+1) := -I;
		end loop;
		
		phase <= (others=>'0');
		for I in 0 to 15 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to 60 loop
			if I >= 16 then
				din <= to_complex(0,0);
			else
				din <= to_complex(arr(I*2),arr(I*2+1));
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		
		wait;
	end process;
end behaviour;
