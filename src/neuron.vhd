----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/02/2018 05:26:10 PM
-- Design Name: 
-- Module Name: Neuron - Behavioral
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

entity Neuron is
    Generic ( -- Parameters for all MACs:
              UNIT_WIDTH : NATURAL := 6;       -- total # of bits (All MACs)
              NUM_INPUTS : NATURAL := 128;     -- total # of multiplications (All MACs)
              -- MAC-specific Parameters:
              FIXED_Q    : NATURAL := 0;       -- *Fixed Point Only: number of fractional bits
              POSIT_ES   : NATURAL := 0;       -- *Posit Only: ES (number of exponent bits)
              FLOAT_WE   : NATURAL := 0;       -- *Floating-Point Only: number of exponent bits
              -- Neuron Parameters:
              DTYPE      : STRING  := "posit"; -- The data type {fixed, float, posit}
              RELU_B     : BOOLEAN := False;   -- Whether to include ReLU activation for neuron
              USE_DSP    : STRING  := "yes");  -- Whether to use DSPs
    Port ( weight      : in  STD_LOGIC_VECTOR (UNIT_WIDTH-1 downto 0);
           activation  : in  STD_LOGIC_VECTOR (UNIT_WIDTH-1 downto 0);
           bias        : in  STD_LOGIC_VECTOR (UNIT_WIDTH-1 downto 0);
           clk         : in  STD_LOGIC;
           en          : in  STD_LOGIC;
           clr         : in  STD_LOGIC;
           reset_n     : in  STD_LOGIC;
           neuron_out  : out STD_LOGIC_VECTOR (UNIT_WIDTH-1 downto 0));

    function compute_clk_cycles return NATURAL is
    begin
        if RELU_B then return 3; -- Multiply |DFF| Accumulate |DFF| ReLU |DFF|
        else return 2;           -- Multiply |DFF| Accumulate |DFF|
        end if;
    end;

    attribute CLK_CYCLES : NATURAL;
    attribute CLK_CYCLES of Neuron: entity is compute_clk_cycles;

end Neuron;

architecture Behavioral of Neuron is

    -- MAC Modules
    component FixedPointMAC is
        Generic ( N       : NATURAL := UNIT_WIDTH; -- # of bits
                  K       : NATURAL := NUM_INPUTS; -- # of multiplications
                  Q       : NATURAL := FIXED_Q;    -- precision of fractional bits
                  USE_DSP : STRING  := USE_DSP);   -- whether to synth mult on DSP48
        Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
               activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
               bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;
    
    component ExactFloatingPointMAC is
        Generic ( K       : NATURAL := NUM_INPUTS;    -- # of multiplications
                  WE      : NATURAL := FLOAT_WE;      -- # of exponent bits
                  WF      : NATURAL := UNIT_WIDTH-FLOAT_WE-1; -- # of mantissa bits
                  USE_DSP : STRING  := USE_DSP);   -- whether to synth mult on DSP48
        Port ( weight     : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               activation : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               bias       : in  STD_LOGIC_VECTOR (WE+WF downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (WE+WF downto 0));
    end component;
    
    component posit_mac is
        Generic ( N       : NATURAL := UNIT_WIDTH; -- # of bits
                  K       : NATURAL := NUM_INPUTS; -- # of multiplications
                  ES      : NATURAL := POSIT_ES;   -- number of exponent bits
                  USE_DSP : STRING  := USE_DSP);   -- whether to synth mult on DSP48
        Port ( weight     : in  STD_LOGIC_VECTOR (N-1 downto 0);
               activation : in  STD_LOGIC_VECTOR (N-1 downto 0);
               bias       : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk        : in  STD_LOGIC;
               reset_n    : in  STD_LOGIC; -- reset DFFs
               clr        : in  STD_LOGIC; -- clear accum DFF
               en         : in  STD_LOGIC; 
               output     : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;
    
    -- ReLU Module
    component relu is
        Generic ( N : NATURAL := UNIT_WIDTH);
        Port ( value  : in  STD_LOGIC_VECTOR (N-1 downto 0);
               clk    : in  STD_LOGIC;
               reset_n: in  STD_LOGIC;
               en     : in  STD_LOGIC;
               clr    : in  STD_LOGIC;
               output : out STD_LOGIC_VECTOR (N-1 downto 0));
    end component;

    signal mac_out : STD_LOGIC_VECTOR (UNIT_WIDTH-1 downto 0);

begin

    -- === START: Check data type specified ===
    check_dtype:
    process
    begin
        if DTYPE /= "fixed" AND DTYPE /= "posit" and DTYPE /= "float" then
            ASSERT FALSE REPORT "DTYPE '" & DTYPE & "' is not implemented for neuron module." SEVERITY FAILURE;
        end if;
        wait;
    end process;
    -- === END: Check data type specified ===
    
    -- === START: MAC Unit Instantiation ===
    fixed_point_mac:
    IF DTYPE = "fixed" GENERATE
        mac0: FixedPointMAC
            Generic map ( N       => UNIT_WIDTH,       -- # of bits
                          K       => NUM_INPUTS,       -- # of multiplications
                          Q       => FIXED_Q,          -- precision of fractional bits
                          USE_DSP => USE_DSP)
            Port map ( weight     => weight,
                       activation => activation,
                       bias       => bias,
                       clk        => clk,
                       reset_n    => reset_n,
                       clr        => clr,
                       en         => en, 
                       output     => mac_out);
    END GENERATE fixed_point_mac;

    floating_point_mac:
    IF DTYPE = "float" GENERATE
        mac0: ExactFloatingPointMAC
            Generic map ( K       => NUM_INPUTS,
                          WE      => FLOAT_WE,
                          WF      => UNIT_WIDTH-FLOAT_WE-1,
                          USE_DSP => USE_DSP)
            Port map ( weight     => weight,
                       activation => activation,
                       bias       => bias,
                       clk        => clk,
                       reset_n    => reset_n,
                       clr        => clr,
                       en         => en, 
                       output     => mac_out);
    END GENERATE floating_point_mac;

    posit_type_mac:
    IF DTYPE = "posit" GENERATE
        mac0: posit_mac
            Generic map ( N       => UNIT_WIDTH,
                          K       => NUM_INPUTS, -- # of multiplications
                          ES      => POSIT_ES,   -- number of exponent bits
                          USE_DSP => USE_DSP)
            Port map ( weight     => weight,
                       activation => activation,
                       bias       => bias,
                       clk        => clk,
                       reset_n    => reset_n,
                       clr        => clr,
                       en         => en, 
                       output     => mac_out);
    END GENERATE posit_type_mac;
    -- === END: MAC Unit Instantiation ===
    
    -- === START: Neuron Output Selection ===
    relu_out:
    IF RELU_B GENERATE -- 3 DFFs total (neuron), ReLU output is output
        relu0: relu
            Generic map ( N => UNIT_WIDTH)
            Port map ( value  => mac_out,
                       clk    => clk,
                       reset_n=> reset_n,
                       en     => en,
                       clr    => clr,
                       output => neuron_out);
    END GENERATE relu_out;
    
    raw_out:
    IF NOT RELU_B GENERATE -- 2 DFFs total (neuron), MAC output is output
        neuron_out <= mac_out;
    END GENERATE raw_out;
    -- === END: Neuron Output Selection ===

end Behavioral;
