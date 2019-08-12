----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/15/2018 05:02:12 PM
-- Design Name: 
-- Module Name: posit_mult_encoded - Behavioral
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

library WORK;
use WORK.COMMON.ALL;

entity posit_mult_encoded_es_n0 is
    Generic ( N       : NATURAL := 8;
              ES      : NATURAL := 0;
              USE_DSP : STRING  := "yes");
    Port ( reg_a        : in  STD_LOGIC_VECTOR (     clog2(N) downto 0);
           reg_b        : in  STD_LOGIC_VECTOR (     clog2(N) downto 0);
           exp_a        : in  STD_LOGIC_VECTOR (         ES-1 downto 0);
           exp_b        : in  STD_LOGIC_VECTOR (         ES-1 downto 0);
           frac_a       : in  STD_LOGIC_VECTOR (       N-3-ES downto 0);
           frac_b       : in  STD_LOGIC_VECTOR (       N-3-ES downto 0);
           frac_prod    : out STD_LOGIC_VECTOR ( 2*(N-2-ES)-1 downto 0);
           scale_factor : out STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0));
end posit_mult_encoded_es_n0;

architecture Behavioral of posit_mult_encoded_es_n0 is

    signal scale_factor_a, scale_factor_b : STD_LOGIC_VECTOR (scale_factor'HIGH-1 downto 0);
    signal scale_factor_sum               : STD_LOGIC_VECTOR (          scale_factor'RANGE);
    signal frac_prod_unnorm               : STD_LOGIC_VECTOR (     frac_prod'HIGH downto 0);
    signal frac_prod_int                  : STD_LOGIC_VECTOR (   frac_prod'HIGH+1 downto 0);
    signal frac_prod_msb                  : STD_LOGIC_VECTOR (                  0 downto 0);

    attribute USE_DSP48 : STRING;
    attribute USE_DSP48 of frac_prod_unnorm : signal is USE_DSP;

begin

    -- Compute scale factor
    scale_factor_a    <= reg_a & exp_a;
    scale_factor_b    <= reg_b & exp_b;
    scale_factor_sum  <= STD_LOGIC_VECTOR (
                             resize(signed(scale_factor_a), scale_factor_a'LENGTH+1)  +
                             resize(signed(scale_factor_b), scale_factor_b'LENGTH+1)
                         );

    -- Multiplication
    frac_prod_unnorm  <= STD_LOGIC_VECTOR (unsigned(frac_a) * unsigned(frac_b));
    frac_prod_msb(0)  <= frac_prod_unnorm(frac_prod_unnorm'HIGH);
    
    -- Normalize fraction
    frac_prod_int     <= STD_LOGIC_VECTOR (
                             shift_right( unsigned(frac_prod_unnorm & '0'),
                                          to_integer( unsigned(frac_prod_msb) ))
                         );
    frac_prod         <= frac_prod_int(frac_prod'RANGE);  --truncate leading '0'
    scale_factor      <= STD_LOGIC_VECTOR (signed(scale_factor_sum) +
                                           resize(signed('0' & frac_prod_msb), scale_factor'LENGTH));

end Behavioral;
