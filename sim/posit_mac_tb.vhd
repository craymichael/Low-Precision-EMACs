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
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
 

ENTITY posit_mac_tb IS
END posit_mac_tb;

ARCHITECTURE behavior OF posit_mac_tb IS

    constant cases_dir : STRING := "/your/path/to/Low-Precision-EMACs/sim/test_cases/";

    FILE file_vectors : TEXT;
    FILE file_results : TEXT;
    
    CONSTANT clk_period : TIME    := 10 ns;
    CONSTANT N          : INTEGER := 8; --# of bits
    CONSTANT ES         : INTEGER := 0;
    CONSTANT K          : INTEGER := 4; --# of multiplications
    
      -- if integers are different returns one, otherwise returns zero
    FUNCTION getdiff(
        a      : STD_LOGIC_VECTOR (N-1 downto 0);
        b      : STD_LOGIC_VECTOR (N-1 downto 0);
        margin : NATURAL := 0
    ) RETURN STD_LOGIC IS
    VARIABLE diff : SIGNED (a'length - 1 downto 0);
    BEGIN
        diff := SIGNED (a) - SIGNED (b);
        IF diff > margin OR diff < -margin THEN
            RETURN '1';
        ELSE
            RETURN '0';
        END IF;
    END getdiff;
    
    -- Component Declaration
    COMPONENT posit_mac IS
        GENERIC ( N  : natural := 8;
                  ES : natural := 0;
                  K  : natural := 4); --# of multiplications
        PORT ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
               activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
               bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC;
               clr        : in  STD_LOGIC;
               en         : in  STD_LOGIC;
               output     : out STD_LOGIC_VECTOR (N-1 downto 0));
    END COMPONENT;
    
    -- Generic signals
    SIGNAL err           : STD_LOGIC;
    SIGNAL actual_answer : STD_LOGIC_VECTOR (N-1 downto 0);
    
    -- Inputs
    SIGNAL weight     : STD_LOGIC_VECTOR (N-1 downto 0);
    SIGNAL activation : STD_LOGIC_VECTOR (N-1 downto 0);
    SIGNAL clk        : STD_LOGIC;
    SIGNAL reset_n        : STD_LOGIC; -- reset pipelined DFF
    SIGNAL clr        : STD_LOGIC; -- reset accum DFF
    SIGNAL en         : STD_LOGIC;
    -- Outputs
    SIGNAL output     : STD_LOGIC_VECTOR (N-1 downto 0);
    
BEGIN
     
    -- Instantiate the Unit Under Test (UUT)
    uut: posit_mac
        GENERIC MAP ( K  => K,  -- # of multiplications
                      ES => ES,
                      N  => N)
        PORT MAP ( weight     => weight,
                   activation => activation,
                   bias       => (others => '0'),
                   clk        => clk,
                   reset_n    => reset_n,
                   clr        => clr,
                   en         => en, 
                   output     => output);

    clock_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period / 2;
        clk <= '1';
        WAIT FOR clk_period / 2;
    END PROCESS;
        
    -- I/O process
    stimulus : PROCESS
        VARIABLE v_iline     : LINE;
        VARIABLE v_oline     : LINE;
        VARIABLE v_act_term1 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_wgt_term1 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_act_term2 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_wgt_term2 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_act_term3 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_wgt_term3 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_act_term4 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_wgt_term4 : STD_LOGIC_VECTOR (N-1 downto 0);
        VARIABLE v_comma     : CHARACTER;
        VARIABLE v_answer    : STD_LOGIC_VECTOR (N-1 downto 0);
    BEGIN

        FILE_OPEN(file_vectors, cases_dir & "posit8_mac_test_cases.csv", READ_MODE);
        FILE_OPEN(file_results, cases_dir & "output_results_posit8_mac.csv", WRITE_MODE);
     
        WHILE NOT endfile(file_VECTORS) LOOP
            -- Enable the unit
            EN <= '1';
            clr <= '0';
        
            -- Read line
            READLINE(file_vectors, v_iline);
            -- Mult 1
            READ(v_iline, v_act_term1);
            READ(v_iline, v_comma);
            READ(v_iline, v_wgt_term1);
            READ(v_iline, v_comma);
            -- Mult 2
            READ(v_iline, v_act_term2);
            READ(v_iline, v_comma);
            READ(v_iline, v_wgt_term2);
            READ(v_iline, v_comma);
            -- Mult 3
            READ(v_iline, v_act_term3);
            READ(v_iline, v_comma);
            READ(v_iline, v_wgt_term3);
            READ(v_iline, v_comma);
            -- Mult 4
            READ(v_iline, v_act_term4);
            READ(v_iline, v_comma);
            READ(v_iline, v_wgt_term4);
            READ(v_iline, v_comma);
            -- Result
            READ(v_iline, v_answer);
        
            -- Reset MAC
            reset_n <= '0';
            WAIT FOR clk_period;
            reset_n <= '1';
            
            -- Mult 1
            weight     <= v_act_term1;
            activation <= v_wgt_term1;
            WAIT FOR clk_period;
            -- Mult 2
            weight     <= v_act_term2;
            activation <= v_wgt_term2;
            WAIT FOR clk_period;
            -- Mult 3
            weight     <= v_act_term3;
            activation <= v_wgt_term3;
            WAIT FOR clk_period;
            -- Mult 4
            weight     <= v_act_term4;
            activation <= v_wgt_term4;
            WAIT FOR clk_period;
            
            -- Wait 2 cycles for answer to propagate to output
            WAIT FOR clk_period;
            -- Disable the unit
            en <= '0';
            WAIT FOR clk_period;
            actual_answer <= v_answer;
            
            -- Write out error
            WAIT FOR clk_period / 2;
            err <= getdiff(output, actual_answer);
            
            -- Write MAC output to file (n bits)
            WRITE(v_oline, output, RIGHT, N);
            WRITELINE(file_results, v_oline);
            
            -- Wait...
            WAIT FOR clk_period / 2;
        END LOOP;

        file_close(file_VECTORS);
        file_close(file_RESULTS);

        ASSERT FALSE REPORT "Simulation Finished" SEVERITY FAILURE;
    END PROCESS;
END;
