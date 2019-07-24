library ieee;
library work;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

-- gating is delayed by 1 cycle compared to when ce is asserted
entity clockgating is
	port(clkInUnbuffered: in std_logic;
		ce: in std_logic := '1';
		clkOutGated: out std_logic);
end entity;
architecture ar of clockGating is
	attribute X_INTERFACE_INFO : string;
	attribute X_INTERFACE_PARAMETER : string;
	attribute X_INTERFACE_INFO of clkInUnbuffered : signal is "xilinx.com:signal:clock:1.0 clkInUnbuffered CLK";
	attribute X_INTERFACE_INFO of clkOutGated : signal is "xilinx.com:signal:clock:1.0 clkOutGated CLK";
	attribute X_INTERFACE_PARAMETER of clkInUnbuffered: signal is "CLK_DOMAIN clkInUnbuffered";
	attribute X_INTERFACE_PARAMETER of clkOutGated: signal is "CLK_DOMAIN clkInUnbuffered, FREQ_HZ 12345";
begin
	buf_gated: BUFGCE port map(I=>clkInUnbuffered, O=>clkOutGated, CE=>ce);
end ar;
