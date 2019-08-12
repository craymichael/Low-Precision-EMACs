----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/29/2018 06:32:36 PM
-- Design Name: 
-- Module Name: posit_accum - Behavioral
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

entity posit_accum_es_0 is
    Generic ( N  : NATURAL := 8;
              K  : NATURAL := 4);
    Port ( frac_s           : in  STD_LOGIC_VECTOR (   2*(N-2) downto 0);  --signed in
           scale_factor     : in  STD_LOGIC_VECTOR (1+clog2(N) downto 0);
           bias             : in  STD_LOGIC_VECTOR (       N-1 downto 0);
           clk              : in  STD_LOGIC;
           reset_n          : in  STD_LOGIC;
           clr              : in  STD_LOGIC;
           en               : in  STD_LOGIC;
           sign             : out STD_LOGIC;
           frac_sum         : out STD_LOGIC_VECTOR ( 2*(N-2)-1 downto 0);  --unsigned out
           scale_factor_sum : out STD_LOGIC_VECTOR (1+clog2(N) downto 0));
end posit_accum_es_0;

architecture Behavioral of posit_accum_es_0 is

    component DFF is 
        Generic ( N : NATURAL := N);
        Port ( clk : in  STD_LOGIC;  
               reset_n : in  STD_LOGIC; -- active high, async
               en  : in  STD_LOGIC; -- active high, sync
               clr : in  STD_LOGIC; -- active high, sync
               clr_d : in  STD_LOGIC_VECTOR (N-1 downto 0);
               d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q   : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component DFF;
    
    component posit_data_extract_es_0 is
    Generic ( N  : NATURAL := N);
    Port ( in_a    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
           in_b    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
           sign_a  : out STD_LOGIC;
           nzero_a : out STD_LOGIC;
           reg_a   : out STD_LOGIC_VECTOR (clog2(N) downto 0);
           frac_a  : out STD_LOGIC_VECTOR (     N-3 downto 0));
    end component;
    
    -- psuedo-bias to offset shift value in accumulation
    constant BIASSF : natural := (4*n-8) / 2;
    -- extra accum bits for K additions
    constant EXTRA  : natural := clog2(K);
    -- width of the quire
    constant QSIZE  : natural := (4*n-8) + 2 + EXTRA;
    -- number of fraction bits
    constant NFRAC  : natural := frac_s'LENGTH - 2;

    -- biased scale factor
    signal sf_biased    : STD_LOGIC_VECTOR (             scale_factor'RANGE);
    -- quire
    signal quire_val,
           quire_sum    : STD_LOGIC_VECTOR (               QSIZE-1 downto 0);
    -- intermediate pre-shifted value (extra bits for fraction part of frac_s)
    signal fs_int, bfs_int, bfs_shifted,
           fs_shifted   : STD_LOGIC_VECTOR (         QSIZE+NFRAC-1 downto 0);
    -- 2s comp of quire
    signal sign_int,
           sum_ovf      : STD_LOGIC;
    signal sum_mag      : STD_LOGIC_VECTOR (               QSIZE-2 downto 0);
    signal sum_mag_p    : STD_LOGIC_VECTOR (sum_mag'LENGTH+NFRAC-1 downto 0);
    signal frac_sum_int : STD_LOGIC_VECTOR (frac_sum'RANGE);
    signal scale_factor_sum_int : STD_LOGIC_VECTOR (scale_factor_sum'RANGE);

    signal bias_s     : STD_LOGIC;
    signal bias_sf    : STD_LOGIC_VECTOR (clog2(N) downto 0);
    signal bias_frac  : STD_LOGIC_VECTOR (     N-3 downto 0);
    signal bias_fracs : STD_LOGIC_VECTOR (     N-2 downto 0);
    signal bsf_biased : STD_LOGIC_VECTOR (    bias_sf'RANGE);

begin

    -- Compute biased scale factor
    sf_biased  <= STD_LOGIC_VECTOR (signed(scale_factor) + BIASSF);
    -- Extend frac_s input
    fs_int     <= STD_LOGIC_VECTOR (resize(signed(frac_s), fs_int'LENGTH));
    -- Shift into place (fixed point)
    fs_shifted <= STD_LOGIC_VECTOR (shift_left(signed(fs_int),
                                               to_integer(unsigned(sf_biased))));
    -- Compute sum (truncate fs_shifted, these bits will NEVER be set)
    quire_sum  <= STD_LOGIC_VECTOR (signed(fs_shifted(fs_shifted'HIGH downto NFRAC)) +
                                    signed(quire_val));

     -- Handle bias clear value for DFF
    bias_data_extract:
    posit_data_extract_es_0
        Generic map ( N  => N)
        Port map ( in_a    => bias,
                   in_b    => (others => '0'),
                   sign_a  => bias_s,
                   nzero_a => OPEN,
                   reg_a   => bias_sf,
                   frac_a  => bias_frac);

    bias_fracs <= STD_LOGIC_VECTOR (-signed('0' & bias_frac)) when bias_s = '1' else ('0' & bias_frac);
    
    -- Compute biased scale factor
    bsf_biased  <= STD_LOGIC_VECTOR (signed(bias_sf) + BIASSF);
    -- Extend frac_s input
    bfs_int     <= STD_LOGIC_VECTOR (resize(signed(bias_fracs & (N-3 downto 0 => '0')), bfs_int'LENGTH));
    -- Shift into place (fixed point)
    bfs_shifted <= STD_LOGIC_VECTOR (shift_left(signed(bfs_int),
                                                to_integer(unsigned(bsf_biased))));

    -- Accumulator DFF
    accumulate:
    DFF
        Generic map (N => quire_val'LENGTH)
        Port map ( clk => clk,
                   reset_n => reset_n,
                   en  => en,
                   clr => clr,
                   clr_d => bfs_shifted(bfs_shifted'HIGH downto NFRAC),
                   d   => quire_sum,
                   q   => quire_val);

    -- Fixed point to frac + scale factor
    sign_int   <= quire_val(quire_val'HIGH);
    sign       <= sign_int;
    -- 2s comp.
    sum_mag    <= STD_LOGIC_VECTOR (-signed(quire_val(sum_mag'RANGE))) when sign_int = '1' else quire_val(sum_mag'RANGE);
    sum_mag_p  <= sum_mag & (NFRAC-1 downto 0 => '0');
    
    scale_factor_extract:
    process(sum_mag, sum_mag_p)
    begin
        for i in sum_mag'HIGH-EXTRA downto 0 loop
            if sum_mag(i) = '1' then -- non-zero
                -- unbias the scale factor
                scale_factor_sum_int <= STD_LOGIC_VECTOR (to_unsigned(i, scale_factor_sum_int'LENGTH) - BIASSF);
                frac_sum_int         <= sum_mag_p(i+NFRAC downto i);
                exit;
            elsif i = 0 then  -- zero
                scale_factor_sum_int <= (others => '1');
                frac_sum_int         <= (others => '0');
                exit;
            else -- d/c
                scale_factor_sum_int <= (others => 'X');
                frac_sum_int         <= (others => 'X');
            end if;
        end loop;
    end process;

    sum_ovf          <= or_reduce(sum_mag(sum_mag'HIGH downto sum_mag'HIGH-EXTRA+1));

    scale_factor_sum <= '0' & (scale_factor_sum'HIGH-1 downto 0 => '1') when sum_ovf = '1' else
                        scale_factor_sum_int;
    frac_sum         <= '1' & (frac_sum'HIGH-1 downto 0 => '0') when sum_ovf = '1' else
                        frac_sum_int;

end Behavioral;
