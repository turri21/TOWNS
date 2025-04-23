library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity cdcachec is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_Vector(7 downto 0);
	doe	:out std_logic;
	
	cache		:in std_logic;
	cacheen	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end cdcachec;

architecture rtl of cdcachec is
signal	ccen	:std_logic;
begin

	process(clk,rstn)begin
		if(rstn='0')then
			ccen<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				ccen<=wdat(0);
			end if;
		end if;
	end process;
	
	rdat<=cache & "000000" & ccen;
	doe<='1' when cs='1' and rd='1' else '0';
	cacheen<=ccen;
	
end rtl;
