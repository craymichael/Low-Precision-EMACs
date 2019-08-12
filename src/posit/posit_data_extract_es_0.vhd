----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/15/2018 11:28:07 AM
-- Design Name: 
-- Module Name: posit_data_extract - Behavioral
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
entity posit_data_extract_es_0 is
    Generic ( N  : NATURAL := 8);
    Port ( in_a    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
           in_b    : in  STD_LOGIC_VECTOR (     N-1 downto 0);
           sign_a  : out STD_LOGIC;
           nzero_a : out STD_LOGIC;
           reg_a   : out STD_LOGIC_VECTOR (clog2(N) downto 0);
           frac_a  : out STD_LOGIC_VECTOR (     N-3 downto 0));
end posit_data_extract_es_0;

architecture Behavioral of posit_data_extract_es_0 is

    signal twos_a, inv_a : STD_LOGIC_VECTOR (         N-2 downto 0);
    signal tmp           : STD_LOGIC_VECTOR (         N-4 downto 0);
    signal zc            : STD_LOGIC_VECTOR (reg_a'HIGH-1 downto 0);
    signal s_a, s_b      : STD_LOGIC_VECTOR (           0 downto 0);
    signal frac_a_tmp    : STD_LOGIC_VECTOR (         frac_a'RANGE);
    signal nzero_a_int   : STD_LOGIC;

begin

    nzero_a_int <= or_reduce(in_a);
    nzero_a     <= nzero_a_int;

    -- Extract signed bit
    s_a(0) <= in_a(in_a'HIGH);
    sign_a <= s_a(0);
    s_b(0) <= in_b(in_b'HIGH);
    -- Twos complement
    twos_a <= STD_LOGIC_VECTOR(
                  UNSIGNED( ((twos_a'HIGH downto 0 => s_a(0)) XOR in_a(twos_a'HIGH downto 0)) ) +
                  UNSIGNED(s_a)
              );
    -- Invert input
    inv_a  <= (inv_a'HIGH downto 0 => twos_a(twos_a'HIGH)) XOR twos_a;
    
    -- Leading zero count
    zero_count:
    process(inv_a)
    begin
        for i in inv_a'HIGH downto 0 loop
            if inv_a(i) = '1' then
                zc <= STD_LOGIC_VECTOR (to_unsigned(inv_a'HIGH - i, zc'LENGTH));
                exit;
            elsif i = 0 then
                zc <= STD_LOGIC_VECTOR (to_unsigned(inv_a'LENGTH, zc'LENGTH));
                exit;
            else
                zc <= (others => 'X');
            end if;
        end loop;
    end process;

    -- Hold normalized fraction bits
    tmp    <= STD_LOGIC_VECTOR(
                  shift_left( UNSIGNED( twos_a(tmp'HIGH downto 0)),
                              to_integer(unsigned(zc)) - 1)
              );
    -- Finish fraction extraction
    frac_a <= nzero_a_int & tmp(frac_a'HIGH-1 downto 0);
    -- Extract regime
    reg_a  <= STD_LOGIC_VECTOR (unsigned('0' & zc)-1) when twos_a(twos_a'HIGH) = '1' else
              STD_LOGIC_VECTOR ( -signed('0' & zc));

end Behavioral;
