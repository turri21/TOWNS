LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IDSROM is
port(
	RESET	:in std_logic;
	CLOCK	:in std_logic;
	CSn		:in std_logic;
	DATA	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end IDSROM;

architecture rtl of IDSROM is
signal	addr	:std_logic_vector(4 downto 0);
signal	bitnum	:integer range 0 to 7;
signal	romdata	:std_logic_vector(7 downto 0);
component IDROM
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

begin

	process(clk,rstn)
	variable lCLOCK	:std_logic;
	begin
		if(rstn='0')then
			addr<=(others=>'0');
			bitnum<=0;
			lCLOCK:='0';
		elsif(clk' event and clk='1')then
			if(CSn='0' and CLOCK='1' and RESET='1')then
				addr<=(others=>'0');
				bitnum<=0;
			elsif(CSn='0' and CLOCK='1' and lCLOCK='0')then
				if(bitnum=7)then
					addr<=addr+1;
					bitnum<=0;
				else
					bitnum<=bitnum+1;
				end if;
			end if;
			lCLOCK:=CLOCK;
		end if;
	end process;

	ROM	:IDROM port map(addr,clk,romdata);
	
	DATA<=romdata(bitnum);
	
end rtl;
