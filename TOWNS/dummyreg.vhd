LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dummyreg	is
port(
	mcs	:in std_logic;
	mrd	:in std_logic;
	mrval	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end dummyreg;

architecture rtl of dummyreg is
begin

	process(clk,rstn)begin
		if(rstn='0')then
			mrval<='0';
		elsif(clk' event and clk='1')then
			mrval<='0';
			if(mcs='1' and mrd='1')then
				mrval<='1';
			end if;
		end if;
	end process;
	
end rtl;
