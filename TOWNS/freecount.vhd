LIBRARY	IEEE;
USE	IEEE.STD_LOGIC_1164.ALL;
USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity freecount is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	odat	:out std_logic_Vector(15 downto 0);
	doe	:out std_logic;
	
	sft	:in std_logic;
	clk	:in std_logic;
	rstn	:in std_logic
);
end freecount;

architecture rtl of freecount is
signal	counter	:std_logic_vector(15 downto 0);
begin
	process(clk,rstn)begin
		if(rstn='0')then
			counter<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(sft='1')then
				counter<=counter+1;
			end if;
		end if;
	end process;
	
	odat<=counter;
	doe<='1' when cs='1' and rd='1' else '0';
end rtl;
