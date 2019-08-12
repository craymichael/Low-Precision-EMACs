----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Char
-- 
-- Create Date:    16:45:17 06/07/2018 
-- Design Name: 
-- Module Name:    MAC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Fixed-Point MAC
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

entity fixed_point_mac is
    Generic ( N       : INTEGER := 8;      -- # of bits
              K       : INTEGER := 4;      -- # of multiplications
              Q       : INTEGER := 4;      -- precision of fractional bits
              USE_DSP : STRING  := "yes"); -- whether to synth mult on DSP48
    Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
           activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
           bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
           clk        : in  STD_LOGIC;
           reset_n    : in  STD_LOGIC; -- reset DFFs
           clr        : in  STD_LOGIC; -- clear accum DFF
           en         : in  STD_LOGIC;
           output     : out STD_LOGIC_VECTOR (N-1 downto 0));
end fixed_point_mac;

architecture Behavioral of fixed_point_mac is

    -- Product width
    constant MUL_W : NATURAL := 2*N;
    -- Accumulator width
    constant ACC_W : NATURAL := MUL_W + clog2(K);

    component DFF is 
        Generic ( N : NATURAL := ACC_W);
        Port ( clk     : in  STD_LOGIC;  
               reset_n : in  STD_LOGIC; -- active high, async
               en      : in  STD_LOGIC; -- active high, sync
               clr     : in  STD_LOGIC; -- active high, sync
               d       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clr_d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q       : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component DFF;

    signal product, sum_inter           : STD_LOGIC_VECTOR (  MUL_W-1 downto 0);
    signal sum, accum, inter, bias_wide : STD_LOGIC_VECTOR (  ACC_W-1 downto 0);
    signal sum_shifted                  : STD_LOGIC_VECTOR (ACC_W-Q-1 downto 0);
    
    attribute USE_DSP48 : STRING;
    attribute USE_DSP48 of product: signal is USE_DSP;

begin

    -- converts the weight and activation into signed numbers so that they can be multiplied together, then converts the product into an std_logic_vector
    product <= STD_LOGIC_VECTOR (signed(weight) * signed(activation));
    
    -- Pipeline DFF
    DFF0: DFF
        Generic map ( N => MUL_W)
        Port map ( q       => sum_inter,
                   clk     => clk,
                   reset_n => reset_n,
                   clr     => '0', -- tie low
                   en      => en,
                   d       => product,
                   clr_d   => (others => '0'));
    
    -- resizes the sum so that the carry out bit is not ignored
    inter     <= STD_LOGIC_VECTOR (resize(signed(sum), inter'LENGTH));
    -- resize bias and shift right to align exponent
    bias_wide <= STD_LOGIC_VECTOR (shift_left(resize(signed(bias), bias_wide'LENGTH), Q));
    
    -- Accum DFF
    DFF1: DFF
        Generic map ( N => inter'LENGTH)
        Port map ( d       => inter,
                   clr_d   => bias_wide,
                   clk     => clk,
                   reset_n => reset_n,
                   clr     => clr,
                   en      => en,
                   q       => accum);

    -- adds the new sum value to the accumulated sum value and converts the result to an std_logic_vector
    sum <= STD_LOGIC_VECTOR (resize(signed(sum_inter), sum'LENGTH) +
                             signed(accum));
    -- shift the sum
    sum_shifted <= accum(accum'HIGH downto Q);
    
    
    -- resizes the result of the MAC to be N bits long and shifting so that the result's fractional precision matches the inputs fractional precision
    -- clip at max/min values
    clip:
    process(sum_shifted)
    begin
        if ( sum_shifted(sum_shifted'high) = '0' and
             or_reduce( sum_shifted(sum_shifted'high-1 downto N) ) = '1') then
            -- positive overflow
            output <= '0' & (output'high-1 downto 0 => '1');
        elsif ( sum_shifted(sum_shifted'high) = '1' and
                and_reduce( sum_shifted(sum_shifted'high-1 downto N-1) ) = '0') then
            -- negative overflow
            output <= '1' & (output'high-1 downto 0 => '0');
        else
            output <= STD_LOGIC_VECTOR (resize(signed(sum_shifted), output'LENGTH));
        end if;
    end process;

end Behavioral;
