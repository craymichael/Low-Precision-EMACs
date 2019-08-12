LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity DFF is 
    Generic ( N : NATURAL := 1);
    Port ( clk     : in  STD_LOGIC;  
           reset_n : in  STD_LOGIC; -- active low, async
           en      : in  STD_LOGIC; -- active high, sync
           clr     : in  STD_LOGIC; -- active high, sync
           d       : in  STD_LOGIC_VECTOR (N-1 downto 0);
           clr_d   : in  STD_LOGIC_VECTOR (N-1 downto 0);
           q       : out STD_LOGIC_VECTOR (N-1 downto 0));
end DFF;

architecture Behavioral of DFF is  
begin  
    process(clk, reset_n)
    begin
        if (reset_n = '0') then
            q <= (others => '0');
        elsif (rising_edge(clk)) then
            if (clr = '1') then
                q <= clr_d;
            elsif (en = '1') then
                q <= d;
            end if;
        end if;
    end process;
end Behavioral;
