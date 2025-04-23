LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IDROMIF is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end IDROMIF;

architecture rtl of IDROMIF is
signal	RESET	:std_logic;
signal	CLOCK	:std_logic;
signal	CSn	:std_logic;
signal	DATA	:std_logic;

component IDSROM
port(
	RESET	:in std_logic;
	CLOCK	:in std_logic;
	CSn		:in std_logic;
	DATA	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;
begin
	
	process(clk,rstn)begin
		if(rstn='0')then
			RESET<='0';
			CLOCK<='0';
			CSn<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				RESET<=wdat(7);
				CLOCK<=wdat(6);
				CSn<=wdat(5);
			end if;
		end if;
	end process;
	
	rdat<=RESET & CLOCK & CSn & "0000" & DATA;
	doe<=cs and rd;
	
	ROM	:IDSROM port map(
		RESET	=>RESET,
		CLOCK	=>CLOCK,
		CSn	=>CSn,
		DATA	=>DATA,
		
		clk	=>clk,
		rstn	=>rstn
	);
	
end rtl;
