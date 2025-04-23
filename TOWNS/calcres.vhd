LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity calcres is
port(
	DS	:in std_logic_vector(10 downto 0);
	DE	:in std_logic_vector(10 downto 0);
	Z	:in std_logic_vector(3 downto 0);

	res	:out std_logic_vector(10 downto 0)
);
end calcres;

architecture rtl of calcres is
signal	DWID	:std_logic_vector(14 downto 0);
signal	iZ		:integer range 0 to 4;
begin
	DWID(10 downto 0)<=DE-DS;
	DWID(14 downto 11)<=(others=>'0');
	
	iZ<=	0 when Z="0000" else
			1 when Z="0001" else
			2 when Z="0011" else
			3 when Z="0111" else
			4 when Z="1111" else
			0;
	
	res<=DWID(iZ+10 downto iZ);

end rtl;
