----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:55:13 06/19/2018 
-- Design Name: 
-- Module Name:    ExactFloatingPointMultiplier - EFPMArch 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.COMMON.ALL;

entity floating_point_accumulator is
    Generic ( WE : NATURAL := 7;  --# of exponent bits
              WF : NATURAL := 14; --# of fraction bits
              K  : NATURAL := 4); --# of multiplications
    Port ( Sign          : in  STD_LOGIC;
           Exponent      : in  STD_LOGIC_VECTOR (    WE downto 0);
           Mantissa      : in  STD_LOGIC_VECTOR (2*WF+1 downto 0);
           Sign_B        : in  STD_LOGIC;
           Exponent_B    : in  STD_LOGIC_VECTOR (  WE-1 downto 0);
           Mantissa_B    : in  STD_LOGIC_VECTOR (  WF-1 downto 0);  
		   clk           : in  STD_LOGIC;
		   reset_n       : in  STD_LOGIC;
		   clr           : in  STD_LOGIC;
		   en            : in  STD_LOGIC;
           AccumSign     : out STD_LOGIC;
           AccumExponent : out STD_LOGIC_VECTOR (  WE-1 downto 0);
           AccumMantissa : out STD_LOGIC_VECTOR (  WF-1 downto 0));
end floating_point_accumulator;
 
architecture Behavioral of floating_point_accumulator is
    
    constant BIAS  : INTEGER := 2**(WE-1) - 1;
    constant MAX   : INTEGER := BIAS;
    constant MIN   : INTEGER := 1 - BIAS - WF;
    constant WA    : INTEGER := 2*(-MIN + MAX) + clog2(K);
    constant ACC_H : NATURAL := 2*WF + 3 * 2**(WE-1) - 4;
    constant ACC_L : NATURAL := 2*WF +     2**(WE-1) - 4;

    signal bias_nzero         : STD_LOGIC_VECTOR (     0 downto 0);
    signal bias_exp           : STD_LOGIC_VECTOR (    we downto 0);
    signal comp_sig           : STD_LOGIC_VECTOR (2*wf+2 downto 0);
    signal bias_int1          : STD_LOGIC_VECTOR (    wf downto 0);
    signal bias_int2          : STD_LOGIC_VECTOR (  wf+1 downto 0);
    signal norm_inter         : STD_LOGIC_VECTOR (  wa-1 downto 0);
    signal shifted_val, sum,
           accum, bias_wide   : STD_LOGIC_VECTOR (    wa downto 0);
    signal exp_max, lsb,
           guard, sticky,
           mant_ovf           : STD_LOGIC;
    signal round_check,
           round_ovf          : STD_LOGIC_VECTOR (         0 downto 0);
    signal AccumExponentInt   : STD_LOGIC_VECTOR (AccumExponent'RANGE);
    signal AccumMantissaInt   : STD_LOGIC_VECTOR (AccumMantissa'RANGE);
    signal AccumMantissaPad   : STD_LOGIC_VECTOR (AccumMantissa'HIGH+1 downto 0);

    component DFF is
        Generic ( N : NATURAL := WA+1);
        Port ( clk : in  STD_LOGIC;
               reset_n : in  STD_LOGIC; -- active high, async
               en      : in  STD_LOGIC; -- active high, sync
               clr     : in  STD_LOGIC; -- active high, sync
               clr_d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               d       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q       : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component DFF;

begin

    -- apply 2s comp if applicable
    comp_sig    <= STD_LOGIC_VECTOR (signed('1' & (not Mantissa)) + 1) when Sign = '1' else '0' & Mantissa;
    -- Convert to fixed point (WA+1 bits)
    -- Note the "- 3" due to minimum exponent being 3
    shifted_val <= STD_LOGIC_VECTOR (shift_left(resize(signed(comp_sig), shifted_val'LENGTH),
                                                to_integer(unsigned(Exponent) - 3)));

    -- apply 2s comp if applicable (w/ subnormal)
    bias_nzero(0) <= or_reduce(Exponent_B);
    -- this line is equivalent of multiplying by 1 and adjusting for subnormal
    bias_exp      <= STD_LOGIC_VECTOR (resize(unsigned(Exponent_B) + BIAS + unsigned(not bias_nzero) + 1, bias_exp'LENGTH));
    bias_int1     <= bias_nzero & Mantissa_B;
    bias_int2     <= STD_LOGIC_VECTOR (signed('1' & (not bias_int1)) + 1)
                       when Sign_B = '1' else '0' & bias_int1;
    -- Convert to fixed point (WA+1 bits)
    -- Note the "- 3" due to minimum exponent being 3
    bias_wide     <= STD_LOGIC_VECTOR (shift_left(resize(signed(bias_int2 & (wf-1 downto 0 => '0')), bias_wide'LENGTH),
                                                  to_integer(unsigned(Exponent_B) - 3)));

    -- Compute sum
    sum <= STD_LOGIC_VECTOR (resize(signed(accum) + signed(shifted_val), accum'length));

    DFF0 : DFF
        Generic map ( N => WA+1)
        Port map ( q       => accum,
                   clk     => clk,
                   reset_n => reset_n,
                   clr     => clr,
                   en      => en,
                   d       => sum,
                   clr_d   => bias_wide);
    
    -- 2s comp if accum sum is negative
    norm_inter <= STD_LOGIC_VECTOR (signed(not accum(accum'HIGH-1 downto 0)) + 1) when accum(accum'HIGH) = '1' else accum(accum'HIGH-1 downto 0);
    AccumSign  <= accum(accum'HIGH);

    -- Check for overflow
    mant_ovf <= '1' when (unsigned(norm_inter(norm_inter'HIGH downto (ACC_H+1))) /= 0) else '0';

    normalize:
    process(norm_inter) -- normalize exponent (including clipping at min/max)
    begin
        for i in ACC_H downto (ACC_L+1) loop 
            if i = (ACC_L+1) then  -- the subnormal case (getting here indicates leading bit is not a 1)
                AccumMantissaInt <= norm_inter(i-1 downto i-WF);
                guard            <= norm_inter(i-WF-1);
                sticky           <= or_reduce(norm_inter(i-WF-2 downto 0));
                AccumExponentInt <= (others => '0');
                exit;
            elsif norm_inter(i) = '1' then
                -- Keep bits after hidden bit ('1') of mantissa
                AccumMantissaInt <= norm_inter(i-1 downto i-WF);
                guard            <= norm_inter(i-WF-1);
                sticky           <= or_reduce(norm_inter(i-WF-2 downto 0));
                AccumExponentInt <= STD_LOGIC_VECTOR (to_unsigned(i - (ACC_L+1), WE));
                exit;
            else
                -- Handle all cases
                AccumMantissaInt <= (others => 'X');
                guard            <= 'X';
                sticky           <= 'X';
                AccumExponentInt <= (others => 'X');
            end if;
        end loop;
    end process;

    -- Exp is max
    exp_max          <= and_reduce(AccumExponentInt(AccumExponentInt'high downto 1));
    lsb              <= AccumMantissaInt(AccumMantissaInt'LOW);
    -- Rounding
    round_check(0)   <= (guard AND (lsb OR sticky)) when exp_max = '0' else '0';
    -- Final exp and mantissa
    AccumMantissaPad <= STD_LOGIC_VECTOR (resize(unsigned(AccumMantissaInt), AccumMantissaPad'LENGTH) +
                                          unsigned(round_check));
    round_ovf(0)     <= AccumMantissaPad(AccumMantissaPad'HIGH);

    AccumMantissa    <= STD_LOGIC_VECTOR (
                            resize(shift_right(unsigned(AccumMantissaPad),
                                               to_integer(unsigned(round_ovf))),
                                   AccumMantissa'LENGTH))
                        when mant_ovf = '0' else (others => '1');
    AccumExponent    <= STD_LOGIC_VECTOR (unsigned(AccumExponentInt) + unsigned(round_ovf))
                        when mant_ovf = '0' else (AccumExponent'high downto 1 => '1') & '0';

end Behavioral;
