LIBRARY	IEEE,work;
USE	IEEE.STD_LOGIC_1164.ALL;
USE	IEEE.STD_LOGIC_ARITH.ALL;
USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pcmcreg is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	ben	:in std_logic_vector(1 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	doe	:out std_logic;
	
	bank	:out std_logic_vector(5 downto 0);
	reg	:out std_logic;
	ver4	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end pcmcreg;

architecture rtl of pcmcreg is
signal	bankb	:std_logic_vector(5 downto 0);
signal	regb	:std_logic;
begin

	process(clk,rstn)begin
		if(rstn='0')then
			bank<=(others=>'0');
			regb<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(ben(0)='1')then
					bankb<=wdat(5 downto 0);
				end if;
				if(ben(1)='1')then
					regb<=wdat(8);
				end if;
			end if;
		end if;
	end process;
	
	rdat<=ver4 & "000000" & regb & "00" & bankb;
	doe<='1' when cs='1' and rd='1' else '0';

end rtl;
