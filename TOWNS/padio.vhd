LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity padio is
port(
	cs		:in std_logic;
	addr	:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	padain	:in std_logic_Vector(6 downto 0);
	padbin	:in std_logic_Vector(6 downto 0);
	triga1	:out std_logic;
	triga2	:out std_logic;
	trigb1	:out std_logic;
	trigb2	:out std_logic;
	coma		:out std_logic;
	comb		:out std_logic;
	fmmute	:out std_logic;
	pcmmute	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end padio;

architecture rtl of padio is
signal	spadain	:std_logic_vector(6 downto 0);
signal	spadbin	:std_logic_vector(6 downto 0);
signal	fmmuteb	:std_logic;
signal	pcmmuteb	:std_logic;

begin
	process(clk)begin
		if(clk' event and clk='1')then
			spadain<=padain;
			spadbin<=padbin;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			triga1<='0';
			triga2<='0';
			trigb1<='0';
			trigb2<='0';
			coma<='0';
			comb<='0';
			fmmuteb<='0';
			pcmmuteb<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(addr='1')then
					if(bsel(1)='1')then
						pcmmuteb<=wdat(8);
						fmmuteb<=wdat(9);
					end if;
					if(bsel(2)='1')then
						triga1<=wdat(16);
						triga2<=wdat(17);
						trigb1<=wdat(18);
						trigb2<=wdat(19);
						coma<=wdat(20);
						comb<=wdat(21);
					end if;
				end if;
			end if;
		end if;
	end process;
	
	rdat<=	x"00" & '0' & spadbin & x"00" & '0' & spadain when addr='0' else
				x"0000" & "000000" & fmmuteb & pcmmuteb & x"00";
	fmmute<=fmmuteb;
	pcmmute<=pcmmuteb;
	doe<=cs and rd;

end rtl;
