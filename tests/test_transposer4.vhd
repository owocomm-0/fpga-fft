--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.transposer4;

--  Defines a design entity, without any ports.
entity test_transposer4 is
end test_transposer4;

architecture behaviour of test_transposer4 is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(1 downto 0);
	signal dout: complex;
begin
	tr: entity transposer4 generic map(dataBits=>24)
		port map(clk,din,phase,dout);
	process
		variable l : line;
	begin
		phase <= (others=>'0');
		for I in 0 to 7 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		-- group 1: fft(0,1,2,3)
		din <= to_complex(0,0);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(2,0);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(1,0);
		phase <= "10";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(3,0);
		phase <= "11";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		
		-- group 2: fft(1+2j, 2+5j, -4+8j, 34-2j)
		din <= to_complex(1,2);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(-4,8);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(2,5);
		phase <= "10";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(34,-2);
		phase <= "11";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		
		-- flush with all zeros
		for I in 0 to 50 loop
			din <= to_complex(0,0);
			phase <= phase+1;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		end loop;
		
		wait;
	end process;
end behaviour;
