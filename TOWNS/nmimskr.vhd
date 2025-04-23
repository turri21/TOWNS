library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity nmimskr is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_Vector(7 downto 0);
	doe	:out std_logic;
	
	nmimsk	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end nmimskr;

architecture rtl of nmimskr is
signal	reg	:std_logic_vector(7 downto 0);

begin
	process(clk,rstn)begin
		if(rstn='0')then
			reg<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				reg<=wdat;
			end if;
		end if;
	end process;
	
	rdat<=reg;
	doe<='1' when cs='1' and rd='1' else '0';
	
	nmimsk<=reg(0);
	
end rtl;
