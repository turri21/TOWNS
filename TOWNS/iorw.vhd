LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity iorw	is
generic(
	ioaddr	:std_logic_vector(15 downto 0)	:=x"0000";
	regen	:std_logic_vector(7 downto 0)
);
port(
	addr	:in std_logic_vector(15 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	do0	:out std_logic;
	do1	:out std_logic;
	do2	:out std_logic;
	do3	:out std_logic;
	do4	:out std_logic;
	do5	:out std_logic;
	do6	:out std_logic;
	do7	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end iorw;

architecture rtl of iorw is
signal	obuf	:std_logic_vector(7 downto 0);
signal	cs		:std_logic;
begin

	cs<='1' when addr=ioaddr else '0';
	
	process(clk,rstn)begin
		if(rstn='0')then
			obuf<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				obuf<=wdat;
			end if;
		end if;
	end process;
	
	rdat<=obuf and regen;
	doe<=cs and rd;
	
	do0<=obuf(0);
	do1<=obuf(1);
	do2<=obuf(2);
	do3<=obuf(3);
	do4<=obuf(4);
	do5<=obuf(5);
	do6<=obuf(6);
	do7<=obuf(7);

end rtl;