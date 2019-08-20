library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package fft_types is
	attribute delay: integer;
	
	-- GLOBAL PARAMETERS
	
	-- maximum supported bit width of the signed integers in a complex value
	constant COMPLEXWIDTH: integer := 48;
	
	-- use an additional output register when the address width of the
	-- ram inside a transposer or reorderBuffer is at least this value
	constant TRANSPOSER_OREG_THRESHOLD: integer := 7;

	-- use two additional output registers when the address width of the
	-- ram inside a transposer or reorderBuffer is at least this value
	constant TRANSPOSER_OREG2_THRESHOLD: integer := 10;

	-- use BRAM instead of LUTRAM when the address width of the
	-- ram inside a transposer or reorderBuffer is at least this value
	constant TRANSPOSER_BRAM_THRESHOLD: integer := 7;


	-- the following constants apply to AXI large FFT and may be overridden by
	-- generic parameters passed to the instance.

	-- which bit of din_tuser controls twiddle pre-multiply enable
	constant AXIFFT_FLAG_TWIDDLE_MULTIPLY: integer := 2;

	-- which bit of din_tuser controls input burst transpose (reorders words within a burst)
	constant AXIFFT_FLAG_INPUT_BURST_TRANSPOSE: integer := 3;

	-- which bit of din_tuser controls output burst transpose (reorders words within a burst)
	constant AXIFFT_FLAG_OUTPUT_BURST_TRANSPOSE: integer := 4;

	attribute relDelay: integer;
	
	type complex is record
		re: signed(COMPLEXWIDTH-1 downto 0);
		im: signed(COMPLEXWIDTH-1 downto 0);
    end record;
    function "+" (Left, Right: complex) return complex;
    function "-" (Left, Right: complex) return complex;
    function "-" (Right: complex) return complex;
    function "*" (Left: complex; Right: integer) return complex;
    function "/" (Left: complex; Right: integer) return complex;
    function to_complex (re,im: integer) return complex;
    function to_complex (re,im: signed) return complex;
    function complex_re(val: complex; bits: integer) return signed;
    function complex_im(val: complex; bits: integer) return signed;
    function complex_pack(val: complex; bits: integer) return std_logic_vector;
    function complex_unpack(val: std_logic_vector) return complex;
   
    function saturate (val: complex; bits: integer) return complex;
    function keepNBits (val: complex; bits: integer) return complex;
    function shift_left(val: complex; N: integer) return complex;
    function shift_right(val: complex; N: integer) return complex;
    function complex_swap(val: complex) return complex;
    function rotate_quarter(val: complex) return complex;
    function rotate_mquarter(val: complex) return complex;
    function round_convergent(val: complex; enable: std_logic; position: integer) return complex;
    
    
	type complexArray is array(integer range<>) of complex;
	
	function reverse_bits(val: unsigned) return unsigned;
	function reverse_bits(val, bits: integer) return integer;
	
	-- returns ceil(log2(val))
	function ceilLog2(val: integer) return integer;
	
	
	function complex_str(val: complex) return String;
	
	function iif(Cond: BOOLEAN; If_True, If_False: integer) return integer;
	
	type scalingModes is (SCALE_DIV_N, SCALE_DIV_SQRT_N, SCALE_NONE);
	
	function scalingShift(scale: scalingModes; order: integer) return integer;
	
	function fft_spdf_halfstage_delay(N: integer; butterfly2: boolean) return integer;
	function fft_spdf_stage_delay(N: integer) return integer;
end package;

package body fft_types is
	function "+" (Left, Right: complex) return complex is
		variable res: complex;
	begin
		res.re := Left.re + Right.re;
		res.im := Left.im + Right.im;
		return res;
	end function;
	
	function "-" (Left, Right: complex) return complex is
		variable res: complex;
	begin
		res.re := Left.re - Right.re;
		res.im := Left.im - Right.im;
		return res;
	end function;
	
	function "-" (Right: complex) return complex is
		variable res: complex;
	begin
		res.re := -Right.re;
		res.im := -Right.im;
		return res;
	end function;
	
	function "*" (Left: complex; Right: integer) return complex is
		variable res: complex;
	begin
		res.re := Left.re * Right;
		res.im := Left.im * Right;
		return res;
	end function;
	
    function "/" (Left: complex; Right: integer) return complex is
		variable res: complex;
	begin
		res.re := Left.re / Right;
		res.im := Left.im / Right;
		return res;
	end function;
    
	function to_complex (re,im: integer) return complex is
		variable res: complex;
	begin
		res.re := to_signed(re, COMPLEXWIDTH);
		res.im := to_signed(im, COMPLEXWIDTH);
		return res;
	end function;
	
	function to_complex (re,im: signed) return complex is
		variable res: complex;
	begin
		res.re := resize(re, COMPLEXWIDTH);
		res.im := resize(im, COMPLEXWIDTH);
		return res;
	end function;
	
	function complex_re(val: complex; bits: integer) return signed is
	begin
		return val.re(bits-1 downto 0); --to_signed(val.re, bits);
	end function;
    function complex_im(val: complex; bits: integer) return signed is
	begin
		return val.im(bits-1 downto 0); --to_signed(val.im, bits);
	end function;
	function complex_pack(val: complex; bits: integer) return std_logic_vector is
	begin
		return std_logic_vector(val.im(bits-1 downto 0))
				& std_logic_vector(val.re(bits-1 downto 0));
	end function;
	function complex_unpack(val: std_logic_vector) return complex is
		variable dataBits: integer := val'length / 2;
	begin
		return to_complex(signed(val(dataBits-1 downto 0)),
							signed(val(val'left downto dataBits)));
	end function;

	function saturate(val: complex; bits: integer) return complex is
		variable res: complex;
		--variable max1: integer := (2**(bits-1))-1;
		--variable min1: integer := 1-(2**(bits-1));
		
		variable max1: signed(COMPLEXWIDTH-1 downto 0) := to_signed((2**(bits-1))-1, COMPLEXWIDTH);
		variable min1: signed(COMPLEXWIDTH-1 downto 0) := to_signed((2**(bits-1))-1, COMPLEXWIDTH);
	begin
		res := val;
		if(res.re > max1) then
			res.re := max1;
		end if;
		if(res.re < min1) then
			res.re := min1;
		end if;
		if(res.im > max1) then
			res.im := max1;
		end if;
		if(res.im < min1) then
			res.im := min1;
		end if;
		return res;
	end function;
	
	function keepNBits(val: complex; bits: integer) return complex is
		variable re1, im1: signed(COMPLEXWIDTH-1 downto 0);
		variable res: complex;
	begin
		re1 := val.re; --to_signed(val.re, 32);
		im1 := val.im; --to_signed(val.im, 32);
		res.re := resize(re1(bits-1 downto 0), COMPLEXWIDTH);
		res.im := resize(im1(bits-1 downto 0), COMPLEXWIDTH);
		return res;
	end function;
	
	function shift_left(val: complex; N: integer) return complex is
		variable res: complex;
	begin
		res.re := shift_left(val.re, N);
		res.im := shift_left(val.im, N);
		return res;
	end function;
	
    function shift_right(val: complex; N: integer) return complex is
		variable res: complex;
	begin
		res.re := shift_right(val.re, N);
		res.im := shift_right(val.im, N);
		return res;
	end function;
	
	function complex_swap(val: complex) return complex is
		variable res: complex;
	begin
		res.im := val.re;
		res.re := val.im;
		return res;
	end function;
	
	function rotate_quarter(val: complex) return complex is
		variable res: complex;
	begin
		res.im := val.re;
		res.re := -val.im;
		return res;
	end function;
	
	function rotate_mquarter(val: complex) return complex is
		variable res: complex;
	begin
		res.im := -val.re;
		res.re := val.im;
		return res;
	end function;
	
	
	function round_convergent(val: complex; enable: std_logic; position: integer) return complex is
		variable res: complex;
		variable c1, c2: signed(position+1 downto 0);
	begin
		if position = -1 then
			return val;
		end if;
		c1 := "0" & enable & (position-1 downto 0=>'0');
		c2 := "00" & (position-1 downto 0=>enable);
		if val.re(position+1) = '1' then
			res.re := val.re + c1;
		else
			res.re := val.re + c2;
		end if;
		if val.im(position+1) = '1' then
			res.im := val.im + c1;
		else
			res.im := val.im + c2;
		end if;
		return res;
	end function;
	
	
	function reverse_bits(val: unsigned) return unsigned is
		variable res: unsigned(val'RANGE);
	begin
		for i in val'RANGE loop
			res(i) := val(val'left + val'right - i);
		end loop;
		return res;
	end function;
	
	function reverse_bits(val, bits: integer) return integer is
	begin
		return to_integer(reverse_bits(to_unsigned(val, bits)));
	end function;
	
	function ceilLog2(val: integer) return integer is
		variable tmp: integer;
	begin
		for I in 0 to 32 loop
			tmp := 2**I;
			if tmp >= val then
				return I;
			end if;
		end loop;
		return 32;
	end function;
	
	
	function complex_str(val: complex) return String is
	begin
		return integer'image(to_integer(val.re))
				& " "
				& integer'image(to_integer(val.im));
	end function;
	
	function iif(Cond: BOOLEAN; If_True, If_False: integer) return integer is
	begin
		if (Cond = TRUE) then
			return(If_True);
		else
			return(If_False);
		end if;
	end function iif;
	
	
	function scalingShift(scale: scalingModes; order: integer) return integer is
	begin
		if scale=SCALE_DIV_N then
			return order;
		elsif scale=SCALE_DIV_SQRT_N then
			return order/2;
		else
			return 0;
		end if;
	end function;
	
	
	function fft_spdf_halfstage_delay(N: integer; butterfly2: boolean) return integer is
	begin
		return iif(butterfly2, 2**(N-2), 2**(N-1)) + 2 + 1;
	end function;
	
	function fft_spdf_stage_delay(N: integer) return integer is
	begin
		return fft_spdf_halfstage_delay(N, true) + fft_spdf_halfstage_delay(N, false);
	end function;
end package body;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.fft_types.all;
-- shift register of len stages
entity sr_complex is
	generic(len: integer := 8);
	Port (clk : in  STD_LOGIC;
			din : in  complex;
			dout : out  complex);
end;
architecture a of sr_complex is
	type arr_t is array(len downto 0) of complex;
	signal arr: arr_t;
begin
g:	for I in 0 to len-1 generate
		arr(I) <= arr(I+1) when rising_edge(clk);
	end generate;
	arr(len) <= din;
	dout <= arr(0);
end a;


