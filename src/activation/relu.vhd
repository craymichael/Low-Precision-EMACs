----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/02/2018 06:23:14 PM
-- Design Name: 
-- Module Name: relu - Behavioral
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

entity relu is
    Generic ( N : NATURAL := 1);
    Port ( value  : in  STD_LOGIC_VECTOR (N-1 downto 0);
           clk    : in  STD_LOGIC;
           reset_n    : in  STD_LOGIC;
           en     : in  STD_LOGIC;
           clr     : in  STD_LOGIC;
           output : out STD_LOGIC_VECTOR (N-1 downto 0));
end relu;

architecture Behavioral of relu is

    component DFF is 
        Generic ( N : NATURAL := N);
        Port ( clk     : in  STD_LOGIC;  
               reset_n : in  STD_LOGIC; -- active high, async
               en      : in  STD_LOGIC; -- active high, sync
               clr     : in  STD_LOGIC; -- active high, sync
               d       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clr_d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
               q       : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component DFF;
    
    signal output_int : STD_LOGIC_VECTOR (output'RANGE);

begin

    -- Value if not negative, otherwise 0 (MAX(value, 0))
    output_int <= (others => '0') when value(value'HIGH) = '1' else value;
    
    dff0 : DFF
        Generic map ( N => N)
        Port map ( clk     => clk,
                   reset_n => reset_n,
                   en      => en,
                   clr     => clr, -- '0' tie low
                   clr_d   => (others => '0'),
                   d       => output_int,
                   q       => output);

end Behavioral;
