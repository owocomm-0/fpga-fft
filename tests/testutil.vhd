library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use std.textio.all;

package testutil is
	function prtstd( v : std_logic_vector ) return string;
end package;

package body testutil is
	function prtstd( v : std_logic_vector ) return string is
		variable s : string( 3 downto 1 );
		variable r : string( (v'left+1) downto (v'right+1) );
		begin
		for i in v'left downto v'right loop
		--report std_logic'image(v(i));
		  s := std_logic'image(v(i));
		--string must start/stop at 1
		--          '1' we need only the second character
		  r(i+1) := s(2);
		end loop;
		return r;
	end prtstd;
end package body;
