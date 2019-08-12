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

entity posit_mac is
    Generic ( N       : NATURAL := 8;   -- # of bits
              K       : NATURAL := 4;   -- # of multiplications
              ES      : NATURAL := 0;   -- number of exponent bits
              USE_DSP : STRING  := "yes");
    Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
           activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
           bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
           clk        : in  STD_LOGIC;
           reset_n    : in  STD_LOGIC; -- reset DFFs
           clr        : in  STD_LOGIC; -- clear accum DFF
           en         : in  STD_LOGIC; 
           output     : out STD_LOGIC_VECTOR (N-1 downto 0));
end posit_mac;

architecture Behavioral of posit_mac is

    component posit_mac_es_n0 is
        Generic ( N       : NATURAL := 8;   -- # of bits
                  K       : NATURAL := 4;   -- # of multiplications
                  ES      : NATURAL := 1;  -- number of exponent bits
                  USE_DSP : STRING  := USE_DSP);
        Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
               activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
               bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;

    component posit_mac_es_0 is
        Generic ( N       : NATURAL := 8;   -- # of bits
                  K       : NATURAL := 4;   -- # of multiplications
                  USE_DSP : STRING  := USE_DSP);
        Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
               activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
               bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;

begin

    ES_0:
    IF ES = 0 GENERATE
        posit_mac_0:
        posit_mac_es_0
            Generic map ( N => N,
                          K => K,
                          USE_DSP => USE_DSP)
            Port map ( weight     => weight,
                       activation => activation,
                       bias       => bias,
                       clk        => clk,
                       reset_n    => reset_n,
                       clr        => clr,
                       en         => en, 
                       output     => output);
   END GENERATE ES_0;
   
   ES_N0:
   IF ES /= 0 GENERATE
       posit_mac_0:
       posit_mac_es_n0
           Generic map ( N  => N,
                         ES => ES,
                         K  => K,
                         USE_DSP => USE_DSP)
           Port map ( weight     => weight,
                      activation => activation,
                      bias       => bias,
                      clk        => clk,
                      reset_n    => reset_n,
                      clr        => clr,
                      en         => en, 
                      output     => output);
  END GENERATE ES_N0;

end Behavioral;
