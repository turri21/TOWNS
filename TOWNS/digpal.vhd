LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity digpal is
port(
	cs		:in std_logic;
	addr	:in std_logic_Vector(2 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	wrote	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end digpal;

architecture rtl of digpal is
subtype DAT_LAT_TYPE is std_logic_vector(3 downto 0); 
type DAT_LAT_ARRAY is array (natural range <>) of DAT_LAT_TYPE; 
signal	REG	:DAT_LAT_ARRAY(0 to 7);
signal	iaddr	:integer range 0 to 7;
begin

	iaddr<=conv_integer(addr);
	process(clk,rstn)begin
		if(rstn='0')then
			rdat<=(others=>'0');
			wrote<='0';
		elsif(clk' event and clk='1')then
			wrote<='0';
			if(cs='1' and wr='1')then
				REG(iaddr)<=wdat(3 downto 0);
				wrote<='1';
			end if;
			rdat<="0000" & REG(iaddr);
		end if;
	end process;
	
	doe<=cs and rd;

end rtl;

