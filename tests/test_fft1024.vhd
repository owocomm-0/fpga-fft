--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft1024_wide;


--  Defines a design entity, without any ports.
entity test_fft1024 is
end test_fft1024;

architecture behaviour of test_fft1024 is
	constant O: integer := 10;
	constant N: integer := 1024;
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(O-1 downto 0);
	signal dout: complex;
	signal debug1: integer;
	constant delay: integer := 1227;
begin
	fft: entity fft1024_wide generic map(dataBits=>32, twBits=>24, inverse=>false)
		port map(clk,din,phase,dout);
	process
		variable l : line;
		variable i1,i2,o1,o2,row,col: integer := 0;
		
		variable ii, oi: unsigned(O-1 downto 0);
		variable inputPerm: unsigned(O-1 downto 0);
		variable outputPerm: unsigned(O-1 downto 0);
		variable dout1: complex;
		
		-- 2 full frames
		type arr_t is array(0 to N*4-1) of integer;
		variable arr: arr_t;
	begin
		--arr := (0=>256, others=>0);
		--arr := (others=>1);
		for I in 0 to N*2-1 loop
			arr(I*2) := (I*I) rem 1969;
			arr(I*2+1) := (I*(I+13)) rem 1969;
		end loop;
		phase <= (others=>'0');
		for I in 0 to N-1 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to N+delay-1 loop
			i2 := I/N;
			i1 := I rem N;
			o2 := (I-delay)/N;
			o1 := (I-delay) rem N;
			
			phase <= to_unsigned(i1, O);
			
			ii := to_unsigned(i1, O);
			oi := to_unsigned(o1, O);
			
-- data input bit order: (7 downto 0) [1,0,7,6,5,4,3,2]
-- data output bit order: (7 downto 0) [1,0,3,2,5,4,7,6]
			--inputPerm := ii(1)&ii(0)&ii(7)&ii(6)&ii(5)&ii(4)&ii(3)&ii(2);
			--outputPerm := oi(1)&oi(0)&oi(3)&oi(2)&oi(5)&oi(4)&oi(7)&oi(6);
			

-- data input bit order: (9 downto 0) [1,0,3,2,5,4,9,8,7,6]
-- data output bit order: (9 downto 0) [0,1,2,3,4,5,6,7,8,9]
			inputPerm := ii(1)&ii(0)&ii(3)&ii(2)&ii(5)&ii(4)&ii(9)&ii(8)&ii(7)&ii(6);
			outputPerm := oi(0)&oi(1)&oi(2)&oi(3)&oi(4)&oi(5)&oi(6)&oi(7)&oi(8)&oi(9);
			
			
			i1 := to_integer(inputPerm) + i2*N;
			
			if I >= N*2 then
				din <= to_complex(0,0);
			else
				din <= to_complex(arr(i1*2),arr(i1*2+1));
			end if;
			
			
			if I >= delay then
				dout1 := shift_right(dout + to_complex(2, 2), 2);
				write(output, integer'image(to_integer(outputPerm) + o2*N) & ": ");
				write(output, complex_str(dout1) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			--phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
