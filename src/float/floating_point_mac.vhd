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
use IEEE.NUMERIC_STD.ALL;

entity floating_point_mac is
    Generic ( K  : NATURAL := 4;   -- # of multiplications
              WE : NATURAL := 7;   -- # of exponent bits
              WF : NATURAL := 14; -- # of mantissa bits
              USE_DSP : STRING  := "yes");
    Port ( weight     : in  STD_LOGIC_VECTOR (WE+WF downto 0);
           activation : in  STD_LOGIC_VECTOR (WE+WF downto 0);
           bias       : in  STD_LOGIC_VECTOR (WE+WF downto 0);
           clk        : in  STD_LOGIC;
           reset_n    : in  STD_LOGIC; -- reset DFFs
           clr        : in  STD_LOGIC; -- clear accum DFF
           en         : in  STD_LOGIC; 
           output     : out STD_LOGIC_VECTOR (WE+WF downto 0));
end floating_point_mac;

architecture Behavioral of floating_point_mac is

    component DFF is 
        Generic ( N : NATURAL := 2*(WE+WF+1)+K-1);
        Port ( clk     : in  STD_LOGIC;  
               reset_n : in  STD_LOGIC; -- active high, async
               en      : in  STD_LOGIC; -- active high, sync
               clr     : in  STD_LOGIC; -- active high, sync
               clr_d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               d       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q       : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component DFF;
    
    component floating_point_multiplier is
        Generic ( WE : NATURAL := WE;
                  WF : NATURAL := WF;
                  USE_DSP : STRING  := USE_DSP);
        Port ( Sign1        : in  STD_LOGIC;
               Exponent1    : in  STD_LOGIC_VECTOR (  WE-1 downto 0);
               Mantissa1    : in  STD_LOGIC_VECTOR (  WF-1 downto 0);
               Sign2        : in  STD_LOGIC;
               Exponent2    : in  STD_LOGIC_VECTOR (  WE-1 downto 0);
               Mantissa2    : in  STD_LOGIC_VECTOR (  WF-1 downto 0);
               MultSign     : out STD_LOGIC;
               MultExponent : out STD_LOGIC_VECTOR (    WE downto 0);
               MultMantissa : out STD_LOGIC_VECTOR (2*WF+1 downto 0));
    end component;
    
    component floating_point_accumulator is
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
    end component;
    
    signal product, sum_inter : STD_LOGIC_VECTOR (WE+2*WF+3 downto 0);

begin

    -- compute exact product
    mult: floating_point_multiplier
        Generic map ( WE      => WE,
                      WF      => WF,
                      USE_DSP => USE_DSP)
        Port map ( Sign1        => Weight(Weight'high),
                   Exponent1    => Weight(Weight'high-1 downto Weight'high-WE),
                   Mantissa1    => Weight(WF-1 downto 0),
                   Sign2        => Activation(Activation'high),
                   Exponent2    => Activation(Activation'high-1 downto Activation'high-WE),
                   Mantissa2    => Activation(WF-1 downto 0),
                   MultSign     => product(product'high),
                   MultExponent => product(product'high-1 downto product'high-WE-1),
                   MultMantissa => product(2*WF+1 downto 0));

    -- Pipeline DFF
    DFF0 : DFF
        Generic map ( N => product'LENGTH)
        Port map ( q       => sum_inter,
                   clk     => clk,
                   reset_n => reset_n,
                   clr     => '0', -- tie low
                   clr_d   => (others => '0'),
                   en      => en,
                   d       => product);

    -- Accumulate products
    accumulate:
    floating_point_accumulator
       Generic map ( WE => WE, --# of exponent bits
                     WF => WF, --# of fraction bits
                     K  => K)  --# of multiplications
       Port map ( Sign          => sum_inter(sum_inter'high),
                  Exponent      => sum_inter(sum_inter'high-1 downto sum_inter'high-WE-1),
                  Mantissa      => sum_inter(2*WF+1 downto 0),
                  Sign_B        => bias(bias'high),
                  Exponent_B    => bias(bias'high-1 downto bias'high-WE),
                  Mantissa_B    => bias(WF-1 downto 0),
                  clk           => clk,
                  reset_n       => reset_n,
                  clr           => clr,
                  en            => en,
                  AccumSign     => Output(Output'high),
                  AccumExponent => Output(Output'high-1 downto Output'high-WE),
                  AccumMantissa => Output(WF-1 downto 0));
    
end Behavioral;
