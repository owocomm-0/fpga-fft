--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft256;


--  Defines a design entity, without any ports.
entity test_fft256_serial is
end test_fft256_serial;

architecture behaviour of test_fft256_serial is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(7 downto 0);
	signal dout: complex;
	signal debug1: integer;
	constant delay: integer := 379;
begin
	
	fft: entity fft256 generic map(dataBits=>32, twBits=>24)
		port map(clk,din,phase,dout);
	process
		variable l : line;
		variable i1,i2,o1,o2,row,col: integer := 0;
		
		variable ii, oi: unsigned(7 downto 0);
		variable inputPerm: unsigned(7 downto 0);
		variable outputPerm: unsigned(7 downto 0);
		
		-- 2 full frames
		type arr_t is array(0 to 1023) of integer;
		variable arr: arr_t;
	begin
		--arr := (0=>256, others=>0);
		--arr := (others=>1);
		for I in 0 to 511 loop
			arr(I*2) := (I*I) rem 1024;
			arr(I*2+1) := (I*(I+13)) rem 1024;
		end loop;
		phase <= (others=>'0');
		for I in 0 to 255 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to 511+delay loop
			i2 := I/256;
			i1 := I rem 256;
			o2 := (I-delay)/256;
			o1 := (I-delay) rem 256;
			--row := i1 rem 16;
			--col := i1/16;
			
			-- input row order is transposed
			--row := (row rem 4)*4 + row/4;
			--i1 := i2*256 + row*16 + col;
			
			phase <= to_unsigned(i1, 8);
			
			ii := to_unsigned(i1, 8);
			oi := to_unsigned(o1, 8);
			
-- data input bit order: (7 downto 0) [1,0,7,6,5,4,3,2]
-- data output bit order: (7 downto 0) [1,0,3,2,5,4,7,6]
			--inputPerm := ii(1)&ii(0)&ii(7)&ii(6)&ii(5)&ii(4)&ii(3)&ii(2);
			--outputPerm := oi(1)&oi(0)&oi(3)&oi(2)&oi(5)&oi(4)&oi(7)&oi(6);
			

-- data input bit order: (7 downto 0) [1,0,3,2,7,6,5,4]
-- data output bit order: (7 downto 0) [1,0,3,2,5,4,7,6]
			inputPerm := ii(1)&ii(0)&ii(3)&ii(2)&ii(7)&ii(6)&ii(5)&ii(4);
			outputPerm := oi(1)&oi(0)&oi(3)&oi(2)&oi(5)&oi(4)&oi(7)&oi(6);
			
			
			i1 := to_integer(inputPerm) + i2*256;
			
			if I >= 512 then
				din <= to_complex(0,0);
			else
				din <= to_complex(arr(i1*2),arr(i1*2+1));
			end if;
			
			
			if I >= delay then
				write(output, integer'image(to_integer(outputPerm) + o2*256) & ": ");
				write(output, complex_str(dout) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			--phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
