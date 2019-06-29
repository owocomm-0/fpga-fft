library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.sr_unsigned;

-- read delay is 5+romDelay cycles

-- if reducedBits is false, output will fit in a twiddleBits+1 bit signed
-- 2's complement integer. if reducedBits is true, output will fit in
-- a twiddleBits bit signed 2's complement integer.
entity twiddleGenerator is
	generic(twiddleBits: integer := 8;
				-- real depth is 2^depth_order
				depthOrder: integer := 9;
				romDelay: integer := 2;
				reducedBits: boolean := false;
				inverse: boolean := true);
	port(clk: in std_logic;
			-- read side; synchronous to rdclk
			rdAddr: in unsigned(depthOrder-1 downto 0);
			rdData: out complex;
			
			-- external rom delay should be 2 cycles
			romAddr: out unsigned(depthOrder-4 downto 0);
			romData: in std_logic_vector(twiddleBits*2-3 downto 0)
			);
end entity;
architecture a of twiddleGenerator is
	constant width: integer := twiddleBits*2;
	
	constant romDepthOrder: integer := depthOrder-3;
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := (twiddleBits-1)*2;
	
	constant one: integer := iif(reducedBits, (2**(twiddleBits-1))-1, (2**(twiddleBits-1)));
	
	signal romData1: std_logic_vector(twiddleBits*2-3 downto 0);
	signal romAddr0,romAddrNext: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal phase,phase1,phase2,phase3: unsigned(depthOrder-1 downto 0) := (others=>'0');
	signal ph3,ph4: unsigned(2 downto 0) := (others=>'0');
	signal isZero,isZeroNext: std_logic;
	
	signal re,im,re0,im0, re_P, re_M, im_P, im_M: integer;
	signal outData, outData0: complex;
	
	attribute keep: string;
	attribute keep of outData: signal is "true";
begin
	romAddrNext <= rdAddr(depthOrder-4 downto 0)-1 when rdAddr(depthOrder-3)='0'
				else (not rdAddr(depthOrder-4 downto 0));
	romAddr0 <= romAddrNext when rising_edge(clk);
	phase <= rdAddr when rising_edge(clk);
	romAddr <= romAddr0;
	-- 1 cycles
	
	-- external rom latency is romDelay cycles
	--phase2 <= phase-(romDelay-1) when rising_edge(clk);
	sr: entity sr_unsigned generic map(depthOrder, romDelay)
		port map(clk, phase, phase1);
	phase2 <= phase1 when rising_edge(clk);
	isZeroNext <= '1' when phase1(depthOrder-3 downto 0)=0 else '0';
	isZero <= isZeroNext when rising_edge(clk);
	romData1 <= romData when rising_edge(clk);
	-- 2+romDelay cycles; isZero is aligned with phase2 and romData1
	
	re0 <= one when isZero='1' else
		to_integer(unsigned(romData1(twiddleBits-2 downto 0)));
	im0 <= 0 when isZero='1' else
		to_integer(unsigned(romData1(romData1'left downto twiddleBits-1)));
	re <= re0 when rising_edge(clk);
	im <= im0 when rising_edge(clk);
	phase3 <= phase2 when rising_edge(clk);
	ph3 <= phase3(phase3'left downto phase3'left-2);
	-- 3+romDelay cycles
	
	re_P <= re when rising_edge(clk);
	re_M <= -re when rising_edge(clk);
	im_P <= im when rising_edge(clk);
	im_M <= -im when rising_edge(clk);
	ph4 <= ph3 when rising_edge(clk);
	-- 4+romDelay cycles

g1: if not inverse generate
		outData0 <= to_complex(re_P,im_M)	when ph4=0 else
					to_complex(im_P,re_M)	when ph4=1 else
					to_complex(im_M,re_M)	when ph4=2 else
					to_complex(re_M,im_M)	when ph4=3 else
					to_complex(re_M,im_P)	when ph4=4 else
					to_complex(im_M,re_P)	when ph4=5 else
					to_complex(im_P,re_P)	when ph4=6 else
					to_complex(re_P,im_P); --when ph4=7;
	end generate;
g2: if inverse generate
		outData0 <= to_complex(re_P,im_P)	when ph4=0 else
					to_complex(im_P,re_P)	when ph4=1 else
					to_complex(im_M,re_P)	when ph4=2 else
					to_complex(re_M,im_P)	when ph4=3 else
					to_complex(re_M,im_M)	when ph4=4 else
					to_complex(im_M,re_M)	when ph4=5 else
					to_complex(im_P,re_M)	when ph4=6 else
					to_complex(re_P,im_M); --when ph4=7;
	end generate;

	outData <= outData0 when rising_edge(clk);
	rdData <= outData;
	-- 5+romDelay cycles
end a;
