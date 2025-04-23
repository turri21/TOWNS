library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity spcont is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rddat	:out std_logic_vector(7 downto 0);
	wrdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	HISPEED	:out std_logic;
	HSPDEN	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end spcont;

architecture rtl of spcont is
signal	HS	:std_logic;
begin
	process(clk,rstn)begin
		if(rstn='0')then
			HS<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(HSPDEN='0' and wrdat(0)='1')then
					HS<='1';
				else
					HS<='0';
				end if;
			end if;
		end if;
	end process;
	
	rddat<=HSPDEN & "000000" & HS;
	HISPEED<=HS;
	doe<='1' when cs='1' and rd='1' else '0';
end rtl;
