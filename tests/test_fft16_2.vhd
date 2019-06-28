--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft16_2;


--  Defines a design entity, without any ports.
entity test_fft16_2 is
end entity;

architecture behaviour of test_fft16_2 is
	constant order: integer := 4;
	constant N: integer := 16;
	constant delay: integer := 37;

	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(order-1 downto 0);
	signal dout: complex;
	signal debug1: integer;
begin
	fft: entity fft16_2 generic map(dataBits=>32, twBits=>24)
		port map(clk,din,phase,dout);

	process
		variable l : line;
		variable i1,i2,o1,o2,row,col: integer := 0;
		
		variable ii, oi: unsigned(order-1 downto 0);
		variable inputPerm: unsigned(order-1 downto 0);
		variable outputPerm: unsigned(order-1 downto 0);
		
		-- 2 full frames
		type arr_t is array(0 to N*4-1) of integer;
		variable arr: arr_t;
	begin
		--arr := (8=>256, others=>0);
		--arr := (others=>1);
		for I in 0 to N*2-1 loop
			arr(I*2) := (I*I*123) rem 1969;
			arr(I*2+1) := (I*(I+199))*123 rem 1969;
		end loop;
		
		phase <= (others=>'0');
		for I in 0 to N-1 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to N*2-1+delay loop
			i2 := I/N;
			i1 := I rem N;
			o2 := (I-delay)/N;
			o1 := (I-delay) rem N;
			
			--phase <= to_unsigned(i1, order);
			
			ii := to_unsigned(i1, order);
			oi := to_unsigned(o1, order);

			inputPerm := ii;
			outputPerm := oi(0)&oi(1)&oi(2)&oi(3);
			
			
			i1 := to_integer(inputPerm) + i2*N;
			
			if I >= N*2 then
				din <= to_complex(0,0);
			else
				din <= to_complex(arr(i1*2),arr(i1*2+1));
			end if;
			
			
			if I >= delay then
				write(output, integer'image(to_integer(outputPerm) + o2*N) & ": ");
				write(output, complex_str(dout) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
