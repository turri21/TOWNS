LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VIDCREG is
port(
	cs		:in std_logic;
	addr	:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	
	CLMODE	:out std_logic_vector(3 downto 0);
	PMODE		:out std_logic;
	
	PLT		:out std_logic_vector(1 downto 0);
	YS			:out std_logic;
	YM			:out std_logic;
	PR1		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end VIDCREG;

architecture rtl of VIDCREG is
signal	sel	:std_logic;
begin
	process(clk,rstn)begin
		if(rstn='0')then
			sel<='0';
			CLMODE<=(others=>'0');
			PMODE<='0';
			PLT<="00";
			YS<='0';
			YM<='0';
			PR1<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(addr='0')then
					sel<=wdat(0);
				else
					if(sel='0')then
						CLMODE<=wdat(3 downto 0);
						PMODE<=wdat(4);
					else
						PLT(0)<=wdat(5);
						PLT(1)<=wdat(4);
						YS<=wdat(3);
						YM<=wdat(2);
						PR1<=wdat(0);
					end if;
				end if;
			end if;
		end if;
	end process;
	
end rtl;

		