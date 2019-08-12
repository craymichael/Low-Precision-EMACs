----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/29/2018 03:00:08 PM
-- Design Name: 
-- Module Name: posit_mac - Behavioral
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

entity posit_mac_es_n0 is
    Generic ( N       : NATURAL := 8;   -- # of bits
              K       : NATURAL := 4;   -- # of multiplications
              ES      : NATURAL := 1;   -- number of exponent bits
              USE_DSP : STRING  := "yes");
    Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
           activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
           bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
           clk        : in  STD_LOGIC;
           reset_n    : in  STD_LOGIC; -- reset DFFs
           clr        : in  STD_LOGIC; -- clear accum DFF
           en         : in  STD_LOGIC; 
           output     : out STD_LOGIC_VECTOR (N-1 downto 0));
end posit_mac_es_n0;

architecture Behavioral of posit_mac_es_n0 is

    -- Component definitions
    component posit_data_extract_es_n0 is
        Generic ( N  : NATURAL := N;
                  ES : NATURAL := ES);
        Port ( in_a    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
               in_b    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
               sign_a  : out STD_LOGIC;
               nzero_a : out STD_LOGIC;
               reg_a   : out STD_LOGIC_VECTOR (clog2(N) downto 0);
               exp_a   : out STD_LOGIC_VECTOR (    ES-1 downto 0);
               frac_a  : out STD_LOGIC_VECTOR (  N-3-ES downto 0));
    end component;
    
    component posit_mult_encoded_es_n0 is
        Generic ( N       : NATURAL := N;
                  ES      : NATURAL := ES;
                  USE_DSP : STRING  := USE_DSP);
        Port ( reg_a        : in  STD_LOGIC_VECTOR (     clog2(N) downto 0);
               reg_b        : in  STD_LOGIC_VECTOR (     clog2(N) downto 0);
               exp_a        : in  STD_LOGIC_VECTOR (         ES-1 downto 0);
               exp_b        : in  STD_LOGIC_VECTOR (         ES-1 downto 0);
               frac_a       : in  STD_LOGIC_VECTOR (       N-3-ES downto 0);
               frac_b       : in  STD_LOGIC_VECTOR (       N-3-ES downto 0);
               frac_prod    : out STD_LOGIC_VECTOR ( 2*(N-2-ES)-1 downto 0);
               scale_factor : out STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0));
    end component;
    
    component posit_encode_round_es_n0 is
        Generic ( N  : NATURAL := N;
                  ES : NATURAL := ES);
        Port ( frac         : in  STD_LOGIC_VECTOR ( 2*(N-2-ES)-1 downto 0);
               scale_factor : in  STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0);
               sign         : in  STD_LOGIC;
               nzero        : in  STD_LOGIC;
               result       : out STD_LOGIC_VECTOR (          N-1 downto 0));
    end component;
    
    component DFF is
        Generic ( N : NATURAL := N);
        Port ( clk : in  STD_LOGIC;  
               reset_n : in  STD_LOGIC; -- active high, async
               en  : in  STD_LOGIC; -- active high, sync
               clr : in  STD_LOGIC; -- active high, sync
               clr_d : in  STD_LOGIC_VECTOR (N-1 downto 0);
               d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q   : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;
    
    component posit_accum_es_n0 is
        Generic ( N  : NATURAL := N;
                  ES : NATURAL := ES;
                  K  : NATURAL := K);
        Port ( frac_s           : in  STD_LOGIC_VECTOR (   2*(N-2-ES) downto 0);  --signed in
               scale_factor     : in  STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0);
               bias             : in  STD_LOGIC_VECTOR (          N-1 downto 0);
               clk              : in  STD_LOGIC;
               reset_n          : in  STD_LOGIC;
               clr              : in  STD_LOGIC;
               en               : in  STD_LOGIC;
               sign             : out STD_LOGIC;
               frac_sum         : out STD_LOGIC_VECTOR ( 2*(N-2-ES)-1 downto 0);  --unsigned out
               scale_factor_sum : out STD_LOGIC_VECTOR (1+ES+clog2(N) downto 0));
   end component;

    -- Signal definitions
    -- Data extraction
    signal nzero                 : STD_LOGIC;
    signal sign_a, sign_b        : STD_LOGIC;
    signal sign_accum, sign_mult : STD_LOGIC;
    signal reg_a, reg_b          : STD_LOGIC_VECTOR (clog2(N) downto 0);
    signal exp_a, exp_b          : STD_LOGIC_VECTOR (    ES-1 downto 0);
    signal frac_a, frac_b        : STD_LOGIC_VECTOR (  N-3-ES downto 0);
    -- Multiplication
    signal frac_prod, frac_accum           : STD_LOGIC_VECTOR (    2*(N-2-ES)-1 downto 0);
    signal frac_prods_int, frac_prods      : STD_LOGIC_VECTOR (frac_prod'HIGH+1 downto 0);
    signal scale_factor, scale_factor_int,
           scale_factor_accum              : STD_LOGIC_VECTOR (   1+ES+clog2(N) downto 0);
    signal stage_0_dff_in, stage_0_dff_out : STD_LOGIC_VECTOR (scale_factor'LENGTH +
                                                               frac_prods'LENGTH-1 downto 0);

begin

    -- Compute sign of answer
    sign_mult  <= sign_a XOR sign_b;

    -- Data extraction for both inputs
    extract_a:
    posit_data_extract_es_n0
        Generic map ( N  => N,
                      ES => ES)
        Port map ( in_a    => weight,
                   in_b    => activation,
                   sign_a  => sign_a,
                   nzero_a => OPEN,
                   reg_a   => reg_a,
                   exp_a   => exp_a,
                   frac_a  => frac_a);
    extract_b:
    posit_data_extract_es_n0
        Generic map ( N  => N,
                      ES => ES)
        Port map ( in_a    => activation,
                   in_b    => weight,
                   sign_a  => sign_b,
                   nzero_a => OPEN,
                   reg_a   => reg_b,
                   exp_a   => exp_b,
                   frac_a  => frac_b);

    -- Multiplication
    mult:
    posit_mult_encoded_es_n0
        Generic map ( N       => N,
                      ES      => ES,
                      USE_DSP => USE_DSP)
        Port map ( reg_a        => reg_a,
                   reg_b        => reg_b,
                   exp_a        => exp_a,
                   exp_b        => exp_b,
                   frac_a       => frac_a,
                   frac_b       => frac_b,
                   frac_prod    => frac_prod,
                   scale_factor => scale_factor_int);

    -- Twos comp
    frac_prods_int <= STD_LOGIC_VECTOR (-signed('0' & frac_prod)) when sign_mult = '1' else ('0' & frac_prod);

    -- Pipeline DFF
    stage_0_dff_in <= frac_prods_int & scale_factor_int;
    
    pipeline:
    DFF
        Generic map ( N => stage_0_dff_in'LENGTH)
        Port map ( clk => clk,
                   reset_n => reset_n,
                   clr => '0',  -- tie low
                   en  => en,
                   clr_d => (others => '0'),
                   d   => stage_0_dff_in,
                   q   => stage_0_dff_out);
    
    frac_prods   <= stage_0_dff_out(stage_0_dff_out'HIGH downto stage_0_dff_out'HIGH-frac_prods'HIGH);
    scale_factor <= stage_0_dff_out(scale_factor'RANGE);

    accum:
    posit_accum_es_n0
        Generic map ( N  => N,
                      ES => ES,
                      K  => K)
        Port map ( frac_s           => frac_prods,
                   scale_factor     => scale_factor,
                   bias             => bias,
                   clk              => clk,
                   reset_n          => reset_n,
                   clr              => clr,
                   en               => en,
                   sign             => sign_accum,
                   frac_sum         => frac_accum,
                   scale_factor_sum => scale_factor_accum);

    nzero <= or_reduce(frac_accum);

    -- Round and encode
    round:
    posit_encode_round_es_n0
        Generic map ( N  => N,
                      ES => ES)
        Port map ( frac         => frac_accum,
                   scale_factor => scale_factor_accum,
                   sign         => sign_accum,
                   nzero        => nzero,
                   result       => output);

end Behavioral;
