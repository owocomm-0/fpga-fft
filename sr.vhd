
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- shift register of len stages
entity sr is
	generic(bits: integer := 8;
			len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  STD_LOGIC_VECTOR (bits-1 downto 0);
			dout : out  STD_LOGIC_VECTOR (bits-1 downto 0);
			ce: in std_logic := '1');
end sr;

architecture a of sr is
	type arr_t is array(len downto 0) of std_logic_vector(bits-1 downto 0);
	signal arr: arr_t;
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when ce='1' and rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- shift register of len stages
entity sr_unsigned is
	generic(bits: integer := 8;
			len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  unsigned (bits-1 downto 0);
			dout : out  unsigned (bits-1 downto 0);
			ce: in std_logic := '1');
end;

architecture a of sr_unsigned is
	type arr_t is array(len downto 0) of unsigned(bits-1 downto 0);
	signal arr: arr_t;
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when ce='1' and rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- shift register of len stages
entity sr_signed is
	generic(bits: integer := 8;
			len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  signed (bits-1 downto 0);
			dout : out  signed (bits-1 downto 0);
			ce: in std_logic := '1');
end;

architecture a of sr_signed is
	type arr_t is array(len downto 0) of signed(bits-1 downto 0);
	signal arr: arr_t;
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when ce='1' and rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- shift register of len stages
entity sr_bit is
	generic(len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  std_logic;
			dout : out std_logic;
			ce: in std_logic := '1');
end;

architecture a of sr_bit is
	signal arr: std_logic_vector(len downto 0);
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when ce='1' and rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;
