LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vsint is
port(
	cs		:in std_logic;
	wr		:in std_logic;
	
	vsync	:in std_logic;
	int	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end vsint;

architecture rtl of vsint is
signal	ssync	:std_logic;
begin

	process(clk)begin
		if(clk' event and clk='1')then
			ssync<=vsync;
		end if;
	end process;

	process(clk,rstn)
	variable lsync	:std_logic;
	begin
		if(rstn='0')then
			int<='0';
			lsync:='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				int<='0';
			elsif(ssync='1')then
				if(lsync='0')then
					int<='1';
				end if;
			end if;
			lsync:=ssync;
		end if;
	end process;
end rtl;
