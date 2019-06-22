--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.transposer_addrGen;
use work.transposer;
use work.testutil.all;

--  Defines a design entity, without any ports.
entity test_transposer is
end test_transposer;

architecture behaviour of test_transposer is
	signal clk: std_logic := '0';
	
	-- addrGen test
	signal phase,addr: unsigned(2 downto 0) := "000";
	--alias addrGen_delay1 is <<constant addrGen.delay: integer >>; 
	
	-- transposer test
	signal din,dout: complex;
	
	-- transposer test 2
	signal din2,dout2: complex;
	signal phase2: unsigned(4 downto 0) := "00000";
begin
	addrGen: entity transposer_addrGen generic map(1,2)
		port map(clk, '1', phase, addr);
	
	transp: entity transposer generic map(1,2,10)
		port map(clk, din, phase, dout);
	
	-- input: 4 rows of 8 values
	-- output: 8 rows of 4 values
	transp2: entity transposer generic map(2,3,16)
		port map(clk, din2, phase2, dout2);
	
	process
		variable l : line;
		variable ind,row,col: integer;
	begin
		-- test the address generator
		for I in 0 to 47 loop
			phase <= to_unsigned(I mod 8,3);
			
			if I >= 8 then
				write(output, integer'image(to_integer(addr)) & " ");
				if (I mod 8) = 7 then
					write(output, "" & LF);
				end if;
			end if;
			
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		
		write(output, "==========" & LF);
		
		-- test transposer
		for I in 0 to 47 loop
			phase <= to_unsigned(I mod 8,3);
			
			-- data is 10,11,12,13,...17,20,21,22,...
			din <= to_complex((I mod 8) + (I/8 + 1)*10, 0);
			
			if I >= 8 then
				write(output, integer'image(to_integer(dout.re)) & " ");
				if (I mod 8) = 7 then
					write(output, "" & LF);
				end if;
			end if;
			
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		
		
		-- test transposer 2
		for I in 0 to 32-1 loop
			phase2 <= to_unsigned(I,5);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		for I in 0 to 32*8-1 loop
			ind := I mod 32;
			row := ind/8;
			col := ind mod 8;
			phase2 <= to_unsigned(ind,5);
			din2 <= to_complex(row*10 + col + (I/32 + 1)*100, 0);
			
			if I >= 32 then
				write(output, integer'image(to_integer(dout2.re)) & " ");
				if (I mod 32) = 31 then
					write(output, "" & LF);
				end if;
			end if;
			
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		
		wait;
	end process;
end behaviour;
