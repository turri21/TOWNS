LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity kbint is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	kbint	:in std_logic;
	kbnmi	:in std_logic;
	
	int	:out std_logic;
	nmi	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end kbint;

architecture rtl of kbint is
signal	msk	:std_logic;
begin

	process(clk,rstn)begin
		if(rstn='0')then
			msk<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				msk<=wdat(0);
			end if;
		end if;
	end process;
	
	int<=kbint and msk;
	nmi<=kbnmi;
	
	rdat<="000000" & kbnmi & kbint;
	
	doe<='1' when cs='1' and rd='1' else '0';
end rtl;
