LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dpmreg is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	palwr	:in std_logic;
	spbusy:in std_logic;
	sbpage:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end dpmreg;

architecture rtl of dpmreg is
signal	lrd	:std_logic;
signal	palmod	:std_logic;
begin
	
	process(clk,rstn)begin
		if(rstn='0')then
			palmod<='0';
			lrd<='0';
		elsif(clk' event and clk='1')then
			if(palwr='1')then
				palmod<='1';
			elsif(lrd='1' and not(cs='1' and rd='1'))then
				palmod<='0';
			end if;
			lrd<=cs and rd;
		end if;
	end process;
	
	rdat<=palmod & "00000" & spbusy & sbpage;
	
	doe<=cs and rd;

end rtl;
