----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:55:13 06/19/2018 
-- Design Name: 
-- Module Name:    floating_point_multiplier - EFPMArch 
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
use ieee.numeric_std.all;

entity floating_point_multiplier is
    GENERIC( we      : INTEGER := 8; 
             wf      : INTEGER := 32;
             USE_DSP : STRING  := "yes"); 
    PORT ( Sign1 : in  std_logic;
           Exponent1 : in  std_logic_vector(we-1 downto 0);
           Mantissa1 : in  std_logic_vector(wf-1 downto 0);
           Sign2 : in  std_logic;
           Exponent2 : in  std_logic_vector(we-1 downto 0);
           Mantissa2 : in  std_logic_vector(wf-1 downto 0);
           MultSign : out std_logic;
           MultExponent : out std_logic_vector(we downto 0);
           MultMantissa : out std_logic_vector(2*wf+1 downto 0));

    attribute USE_DSP48 : STRING;
    attribute USE_DSP48 of MultMantissa: signal is USE_DSP;

end floating_point_multiplier;

architecture EFPMArch of floating_point_multiplier is

    signal Mantissa1_sig  : STD_LOGIC_VECTOR (WF downto 0);
    signal Mantissa2_sig  : STD_LOGIC_VECTOR (WF downto 0);
    signal Ex1is0, Ex2is0 : STD_LOGIC_VECTOR ( 0 downto 0);

begin

    subnormal_detection_proc : process (Exponent1, Exponent2) is begin
        if unsigned(Exponent1) = 0 then
            Ex1is0 <= "1";
        else
            Ex1is0 <= "0";
        end if;
        if unsigned(Exponent2) = 0 then
            Ex2is0 <= "1";
        else
            Ex2is0 <= "0";
        end if;
    end process;
    
    Mantissa1_sig <= (not Ex1is0) & Mantissa1;
    Mantissa2_sig <= (not Ex2is0) & Mantissa2;
        
    MultSign <= Sign1 XOR Sign2;
    MultExponent <= std_logic_vector(resize(unsigned(Exponent1), we+1) +
                                     resize(unsigned(Exponent2), we+1) +
                                     unsigned(Ex1is0) + unsigned(Ex2is0) + 1);
    MultMantissa <= std_logic_vector(unsigned(Mantissa1_sig) * unsigned(Mantissa2_sig));

end EFPMArch;
