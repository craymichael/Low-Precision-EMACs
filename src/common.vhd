----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/15/2018 12:04:26 PM
-- Design Name: 
-- Module Name: common - Behavioral
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
use IEEE.MATH_REAL.ALL;

--Package definitions
package COMMON is

    function clog2 (V: INTEGER) return INTEGER;
    function max(LEFT, RIGHT: INTEGER) return INTEGER;
    function min(LEFT, RIGHT: INTEGER) return INTEGER;

end COMMON;

-- Local Subprograms
package body COMMON is
    
    function clog2 (V: INTEGER) return INTEGER is
    begin
        return INTEGER(ceil(log2(REAL(V))));
    end clog2;
    
    function max(LEFT, RIGHT: INTEGER) return INTEGER is
    begin
        if LEFT > RIGHT then return LEFT;
        else return RIGHT;
        end if;
    end;
    
    function min(LEFT, RIGHT: INTEGER) return INTEGER is
    begin
        if LEFT < RIGHT then return LEFT;
        else return RIGHT;
        end if;
    end;

end COMMON;
