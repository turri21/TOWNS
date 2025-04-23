LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity knjjis2rom is
port(
	jiscode	:in std_logic_vector(15 downto 0);
	
	romcode	:out std_logic_vector(12 downto 0);
	clk		:in std_logic
);
end knjjis2rom;

architecture tbl of knjjis2rom is
signal	tbladdr	:std_logic_vector(8 downto 0);
component jis2rom
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;
begin
	romcode(4 downto 0)<=jiscode(4 downto 0);
	tbladdr<=jiscode(14 downto 8) & jiscode(6 downto 5);
	tbl	:jis2rom port map(tbladdr,clk,romcode(12 downto 5));
	
end tbl;
