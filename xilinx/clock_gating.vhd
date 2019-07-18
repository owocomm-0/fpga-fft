library ieee;
library work;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

-- gating is delayed by 1 cycle compared to when ce is asserted
entity clockGating is
	port(clkInUnbuffered, ce: in std_logic;
		clkOutGated: out std_logic);
end entity;
architecture ar of clockGating is
begin
	buf_gated: BUFGCE port map(I=>clkInUnbuffered, O=>clkOutGated, CE=>ce);
end ar;
