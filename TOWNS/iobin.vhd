library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity iobin is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	odat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	in0	:in std_logic;
	in1	:in std_logic;
	in2	:in std_logic;
	in3	:in std_logic;
	in4	:in std_logic;
	in5	:in std_logic;
	in6	:in std_logic;
	in7	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end iobin;

architecture rtl of iobin is
begin
	process(clk,rstn)begin
		if(rstn='0')then
			odat<=(others=>'0');
		elsif(clk' event and clk='1')then
			odat<=in7 & in6 & in5 & in4 & in3 & in2 & in1 & in0;
		end if;
	end process;
	
	doe<='1' when cs='1' and rd='1' else '0';
end rtl;
