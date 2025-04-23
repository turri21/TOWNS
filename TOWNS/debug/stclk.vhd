LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity stclk is
port(
	datin	:in std_logic;
	clk	:in std_logic;
	
	stclk	:out std_logic
);
end stclk;

architecture rtl of stclk is
begin
	stclk<= datin and (not clk);
	
end rtl;