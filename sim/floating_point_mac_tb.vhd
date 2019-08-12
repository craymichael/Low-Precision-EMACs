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
 

ENTITY ExactFloatingPointMACTB IS
END ExactFloatingPointMACTB;

ARCHITECTURE behavior OF ExactFloatingPointMACTB IS

    constant cases_dir : STRING := "/your/path/to/Low-Precision-EMACs/sim/test_cases/";

    file file_VECTORS : text;
    file file_RESULTS : text;
    
    constant clk_period : time := 10 ns;

    constant WE : INTEGER := 7;  -- # of exponent bits
    constant WF : INTEGER := 14; -- # of fraction bits
    constant K  : INTEGER := 4; -- # of multiplications
    
      -- if integers are different returns one, otherwise returns zero
    function getdiff(
      a      : STD_LOGIC_VECTOR (WE+WF downto 0);
      b      : STD_LOGIC_VECTOR (WE+WF downto 0);
      margin : INTEGER := 5
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
    
    -- Compnent Declaration
    component ExactFloatingPointMAC is
        Generic ( K  : NATURAL := K;   -- # of multiplications
                  WE : NATURAL := WF;   -- # of exponent bits
                  WF : NATURAL := WF); -- # of mantissa bits
        Port ( weight     : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               activation : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               bias       : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (WE+WF downto 0));
    end component;
    
    -- Generic signals
    signal err : STD_LOGIC;
    signal actual_answer : STD_LOGIC_VECTOR (WE+WF downto 0);  -- s|e|m
    
    -- Inputs
    signal weight     : STD_LOGIC_VECTOR (WE+WF downto 0);
    signal activation : STD_LOGIC_VECTOR (WE+WF downto 0);
    signal clk        : STD_LOGIC;
    signal reset_n    : STD_LOGIC;
    signal clr        : STD_LOGIC;
    signal en         : STD_LOGIC;
    -- Outputs 
    signal output     : STD_LOGIC_VECTOR (WE+WF downto 0);
    
    BEGIN
     
    -- Instantiate the Unit Under Test (UUT)
    uut: ExactFloatingPointMAC
        Generic map ( K  => K,  -- # of multiplications
                      WE => WE, -- # of exponent bits
                      WF => WF) -- # of mantissa bits
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
        variable v_ACT_TERM1 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_WGT_TERM1 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_ACT_TERM2 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_WGT_TERM2 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_ACT_TERM3 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_WGT_TERM3 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_ACT_TERM4 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_WGT_TERM4 : STD_LOGIC_VECTOR (WE+WF downto 0);
        variable v_COMMA     : CHARACTER;
        variable v_ANSWER    : STD_LOGIC_VECTOR (WE+WF downto 0);
         
      begin
     
        file_open(file_VECTORS, cases_dir & "float22_we_7_wf_14_mac_test_cases.csv",  READ_MODE);
        file_open(file_RESULTS, cases_dir & "output_results_float22_we_7_wf_14_mac.csv", WRITE_MODE);
     
        while not endfile(file_VECTORS) loop
            -- Enable the unit
            en  <= '1';
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
            write(v_OLINE, Output, right, we+wf+1);
            writeline(file_RESULTS, v_OLINE);
            
            -- Wait...
            wait for clk_period / 2;
        end loop;

        file_close(file_VECTORS);
        file_close(file_RESULTS);
         
        ASSERT FALSE REPORT "Simulation Finished" SEVERITY FAILURE;
      end process;
END;
