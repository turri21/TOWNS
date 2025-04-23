LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lenwait is
generic(
	len	:integer	:=100
);
port(
	cs		:in std_logic;
	wr		:in std_logic;
	
	wreq	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end lenwait;

architecture rtl of lenwait is
signal	count	:integer range 0 to len;
signal	lwr	:std_logic;
begin
	process(clk,rstn)
	variable vwr	:std_logic;
	begin
		if(rstn='0')then
			count<=0;
			wreq<='0';
			lwr<='0';
		elsif(clk' event and clk='1')then
			vwr:=cs and wr;
			if(vwr='0' and lwr='1')then
				wreq<='1';
				count<=len;
			elsif(count>0)then
				count<=count-1;
			else
				wreq<='0';
			end if;
			lwr<=vwr;
		end if;
	end process;

end rtl;