LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tvwrote is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	wrote	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end tvwrote;

architecture rtl of tvwrote is
signal	wroteb	:std_logic;
begin

	process(clk,rstn)
	variable lrd	:std_logic;
	begin
		if(rstn='0')then
			wroteb<='0';
			lrd:='0';
		elsif(clk' event and clk='1')then
			if(wrote='1')then
				wroteb<='1';
			end if;
			if(cs='1' and rd='1')then
				lrd:='1';
			elsif(lrd='1')then
				wroteb<='0';
				lrd:='0';
			end if;
--			if(cs='1' and wr='1')then
--				wroteb<='0';
--			end if;
		end if;
	end process;
	rdat<=wroteb & "0000000";
	doe<='1' when cs='1' and rd='1' else '0';

end rtl;
