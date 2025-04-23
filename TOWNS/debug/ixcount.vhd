LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ixcount is
generic(
	cwidth	:integer	:=32
);
port(
	cin	:in std_logic;
	
	cout	:out std_logic_vector(cwidth-1 downto 0);
	clk	:in std_logic;
	rstn	:in std_logic
);
end ixcount;

architecture rtl of ixcount is
signal counter	:std_logic_vector(cwidth-1 downto 0);
begin

	process(clk,rstn)begin
		if(rstn='0')then
			counter<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cin='1')then
				counter<=counter+1;
			end if;
		end if;
	end process;
	
	cout<=counter;

end rtl;
