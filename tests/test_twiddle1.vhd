--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.twiddleGenerator;
use work.twiddleRom16;
use work.testutil.all;

--  Defines a design entity, without any ports.
entity test_twiddle1 is
end test_twiddle1;

architecture behaviour of test_twiddle1 is
	signal clk: std_logic := '0';
	signal phase: unsigned(3 downto 0) := "0000";
	signal dout: complex;
	
	signal romAddr: unsigned(0 downto 0);
	signal romData: std_logic_vector(21 downto 0);
begin
	tw: entity twiddleGenerator generic map(12, 4)
		port map(clk,phase,dout, romAddr,romData);
	rom: entity twiddleRom16 port map(clk, romAddr,romData);
	process
		variable l : line;
	begin
		for I in 0 to 15+5 loop
			if I >= 16 then
				phase <= "0000";
			else
				phase <= to_unsigned(I,4);
			end if;
			
			if I >= 5 then
				write(output, integer'image(dout.re) & " " & integer'image(dout.im) & LF);
			end if;
			
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		wait;
	end process;
end behaviour;
