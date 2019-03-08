--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft4_serial;

--  Defines a design entity, without any ports.
entity test_fft4_serial is
end test_fft4_serial;

architecture behaviour of test_fft4_serial is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(1 downto 0);
	signal dout: complex;
begin
	fft: entity fft4_serial port map(clk,din,phase,dout);
	process
		variable l : line;
	begin
		-- group 1: fft(2, 2, 4, 4)
		din <= to_complex(2,0);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(2,0);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(4,0);
		phase <= "10";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(4,0);
		phase <= "11";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		
		-- group 2: fft(1+2j, 2+5j, -4+8j, 34-2j)
		din <= to_complex(1,2);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(2,5);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(-4,8);
		phase <= "10";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		din <= to_complex(34,-2);
		phase <= "11";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		
		
		-- flush with all zeros
		din <= to_complex(0,0);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
		phase <= "10";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
		phase <= "11";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
		phase <= "00";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
		phase <= "01";
		wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
		write(output, complex_str(dout) & LF);
		
		din <= to_complex(0,0);
        phase <= "10";
        wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
        write(output, complex_str(dout) & LF);
        
        din <= to_complex(0,0);
        phase <= "11";
        wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
        write(output, complex_str(dout) & LF);
		
		
		wait;
	end process;
end behaviour;
