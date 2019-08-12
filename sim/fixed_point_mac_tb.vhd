--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   
-- Design Name:   
-- Module Name:   
-- Project Name:  
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
 

ENTITY FixedPointMACTB IS
END FixedPointMACTB;
 
ARCHITECTURE behavior OF FixedPointMACTB IS 
    
    constant cases_dir : STRING := "/your/path/to/Low-Precision-EMACs/sim/test_cases/";
    
    -- Constant declarations (GENERIC)
    constant clk_period : time := 10 ns;
    -- Constant declarations (AD-HOC)
    constant N : Integer := 16;
    constant K : Integer := 4;
    constant Q : Integer := 8;
    
    -- Component Declaration
    COMPONENT FixedPointMAC is
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
    END COMPONENT;
    
  file file_VECTORS : text;
  file file_RESULTS : text;
  
    -- if integers are different returns one, otherwise returns zero
    function getdiff(
        a      : STD_LOGIC_VECTOR (N-1 downto 0);
        b      : STD_LOGIC_VECTOR (N-1 downto 0);
        margin : NATURAL := 1 -- Python script doesn't round
    ) return STD_LOGIC is
    variable diff : signed(a'length - 1 downto 0);
    begin
        diff := signed(a) - signed(b);
        if diff > margin or diff < -margin then
            return '1';
        else
            return '0';
        end if;
    end getdiff;
  
    -- Generic signals
    signal err : std_logic;
    signal actual_answer : std_logic_vector(n-1 downto 0);
    -- Stimuli
    signal Weight : STD_LOGIC_VECTOR(N-1 downto 0);
    signal Activation : STD_LOGIC_VECTOR(N-1 downto 0);
    signal CLK : STD_LOGIC;
    signal reset_n : STD_LOGIC;
    signal clr : STD_LOGIC;
    signal EN : STD_LOGIC; 
    signal Output : STD_LOGIC_VECTOR(N-1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
    uut: FixedPointMAC
        Generic map ( N => N,
                      K => K,
                      Q => Q)
        Port map ( weight     => weight,
                   activation => activation,
                   bias       => (others => '0'),
                   clk        => clk,
                   reset_n    => reset_n,
                   clr        => clr,
                   en         => en,
                   output     => output);
        
    clock_process : process
    begin
         clk <= '0';
         wait for clk_period/2;
         clk <= '1';
         wait for clk_period/2;
    end process;

    -- I/O process
    process
        variable v_ILINE     : LINE;
        variable v_OLINE     : LINE;
        variable v_ACT_TERM1 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_WGT_TERM1 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_ACT_TERM2 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_WGT_TERM2 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_ACT_TERM3 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_WGT_TERM3 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_ACT_TERM4 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_WGT_TERM4 : STD_LOGIC_VECTOR (N-1 downto 0);
        variable v_COMMA     : CHARACTER;
        variable v_ANSWER    : STD_LOGIC_VECTOR (N-1 downto 0);
         
    begin
    
        file_open(file_VECTORS, cases_dir & "fixed16_mac_test_cases.csv",  READ_MODE);
        file_open(file_RESULTS, cases_dir & "output_results_fixed_mac.csv", WRITE_MODE);
        
        while not endfile(file_VECTORS) loop
            -- Enable the unit
            EN  <= '1';
            clr <= '0';

            -- Read line
            readline(file_VECTORS, v_ILINE);
            -- Mult 1
            read(v_ILINE, v_ACT_TERM1);
            read(v_ILINE, v_COMMA);
            read(v_ILINE, v_WGT_TERM1);
            read(v_ILINE, v_COMMA);
            -- Mult 2
            read(v_ILINE, v_ACT_TERM2);
            read(v_ILINE, v_COMMA);
            read(v_ILINE, v_WGT_TERM2);
            read(v_ILINE, v_COMMA);
            -- Mult 3
            read(v_ILINE, v_ACT_TERM3);
            read(v_ILINE, v_COMMA);
            read(v_ILINE, v_WGT_TERM3);
            read(v_ILINE, v_COMMA);
            -- Mult 4
            read(v_ILINE, v_ACT_TERM4);
            read(v_ILINE, v_COMMA);
            read(v_ILINE, v_WGT_TERM4);
            read(v_ILINE, v_COMMA);
            -- Result
            read(v_ILINE, v_ANSWER);
        
            -- Reset MAC
            reset_n <= '0';
            wait for clk_period;
            reset_n <= '1';
            
            -- Mult 1
            Weight <= v_ACT_TERM1;
            Activation <= v_WGT_TERM1;
            wait for clk_period;
            -- Mult 2
            Weight <= v_ACT_TERM2;
            Activation <= v_WGT_TERM2;
            wait for clk_period;
            -- Mult 3
            Weight <= v_ACT_TERM3;
            Activation <= v_WGT_TERM3;
            wait for clk_period;
            -- Mult 4
            Weight <= v_ACT_TERM4;
            Activation <= v_WGT_TERM4;
            wait for clk_period;
            
            -- Wait 2 cycles for answer to propagate to output
            wait for clk_period;
            -- Disable the unit
            EN <= '0';
            wait for clk_period;
            actual_answer <= v_ANSWER;
            
            -- Write out error
            wait for clk_period / 2;
            err <= getdiff(Output, actual_answer);
            
            -- Write MAC output to file (n bits)
            write(v_OLINE, Output, right, n);
            writeline(file_RESULTS, v_OLINE);
            
            -- Wait...
            wait for clk_period / 2;
        end loop;
    
        file_close(file_VECTORS);
        file_close(file_RESULTS);

        ASSERT FALSE REPORT "Simulation Finished" SEVERITY FAILURE;
    end process;
END;
