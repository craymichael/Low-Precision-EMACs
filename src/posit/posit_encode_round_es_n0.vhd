----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/15/2018 05:53:29 PM
-- Design Name: 
-- Module Name: posit_encode_round - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

library WORK;
use WORK.COMMON.ALL;

--NOTE: Posit multiplication ONLY
entity posit_encode_round_es_n0 is
    Generic ( N  : NATURAL := 8;
              ES : NATURAL := 0);
    Port ( frac         : in  STD_LOGIC_VECTOR ( 2*(N-2-ES)-1 downto 0);
           scale_factor : in  STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0);
           sign         : in  STD_LOGIC;
           nzero        : in  STD_LOGIC;
           result       : out STD_LOGIC_VECTOR (          N-1 downto 0));
end posit_encode_round_es_n0;

architecture Behavioral of posit_encode_round_es_n0 is

    constant MAXREG : NATURAL := N-2;

    signal s_sf, ovf_regime, ovf_regime_f : STD_LOGIC;
    signal guard, lsb                : STD_LOGIC;
    signal round_check               : STD_LOGIC_VECTOR (0 downto 0);
    signal exp, exp_f                : STD_LOGIC_VECTOR (      ES-1 downto 0);
    signal regime                    : STD_LOGIC_VECTOR (  clog2(N) downto 0);
    signal regime_f                  : STD_LOGIC_VECTOR (clog2(N)-1 downto 0);
    signal tmp1, tmp2, tmp           : STD_LOGIC_VECTOR ((exp_f'LENGTH +
                                                          frac'LENGTH +
                                                          MAXREG) downto 0);
    signal shift_exp_neg, shift_exp_pos : STD_LOGIC_VECTOR (regime_f'RANGE);
    signal result_int                   : STD_LOGIC_VECTOR (result'RANGE);

begin

    -- Decode regime and exponent
    s_sf <= scale_factor(scale_factor'HIGH);
    exp  <= scale_factor(exp'HIGH downto 0);
    
    process(scale_factor, s_sf)
    begin
        if s_sf = '1' then
            regime <= STD_LOGIC_VECTOR (-signed(scale_factor(scale_factor'HIGH-1 downto ES)));
        else
            regime <= scale_factor(scale_factor'HIGH-1 downto ES);
        end if;
    end process;

    ovf_regime <= regime(regime'HIGH);
    regime_f <= ((regime_f'HIGH downto 1 => '1') & '0') when ovf_regime = '1' else regime(regime'HIGH-1 downto 0);
    exp_f    <= (exp_f'HIGH downto 0 => '0') when ((nzero = '0') or (ovf_regime = '1') or (and_reduce(regime_f) = '1')) else exp;
    
    -- Packing stage 1 and rounding
    tmp1 <= nzero & '0' & exp_f & frac(frac'HIGH-1 downto 0) & (MAXREG-1 downto 0 => '0');
    tmp2 <= '0' & nzero & exp_f & frac(frac'HIGH-1 downto 0) & (MAXREG-1 downto 0 => '0');

    ovf_regime_f <= and_reduce(regime_f);  -- TODO this doesn't work for N not a power of 2?
    process(regime_f, ovf_regime_f)
    begin
        if ovf_regime_f = '1' then
            shift_exp_neg <= STD_LOGIC_VECTOR (unsigned(regime_f) - 2);
            shift_exp_pos <= STD_LOGIC_VECTOR (unsigned(regime_f) - 1);
        else
            shift_exp_neg <= STD_LOGIC_VECTOR (unsigned(regime_f) - 1);
            shift_exp_pos <= regime_f;
        end if;
    end process;
    
    tmp <= STD_LOGIC_VECTOR (shift_right(unsigned(tmp2),
                                         to_integer(unsigned(shift_exp_neg))))
           when s_sf = '1' else
           STD_LOGIC_VECTOR (shift_right(signed(tmp1),
                                         to_integer(unsigned(shift_exp_pos))));

    -- Packing stage 2 and convergent rounding
    lsb   <= tmp(tmp'HIGH - (N-2));
    guard <= tmp(tmp'HIGH - (N-1));

    round_check(0) <= guard AND (lsb OR or_reduce(tmp(tmp'HIGH - N downto 0)))
                      when ((ovf_regime OR ovf_regime_f) = '0') else '0';

    result_int <= STD_LOGIC_VECTOR (unsigned('0' & tmp(tmp'HIGH downto tmp'HIGH-result_int'HIGH+1)) +
                                    unsigned(round_check));
    
    result <= STD_LOGIC_VECTOR (-signed(result_int)) when sign = '1' else
                                result_int;

end Behavioral;
