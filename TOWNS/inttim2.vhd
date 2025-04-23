LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity inttim2 is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	bsel	:in std_logic_Vector(3 downto 0);
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_Vector(31 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	
	sft	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end inttim2;

architecture rtl of inttim2 is
signal	timval	:std_logic_vector(15 downto 0);
signal	count		:std_logic_vector(15 downto 0);
signal	enable	:std_logic;
signal	intb		:std_logic;
signal	ov			:std_logic;
signal	vwrite	:std_logic;

begin
	
	process(clk,rstn)begin
		if(rstn='0')then
			timval<=(others=>'0');
			enable<='0';
			vwrite<='0';
		elsif(clk' event and clk='1')then
			vwrite<='0';
			if(cs='1' and wr='1')then
				if(bsel(0)='1')then
					enable<=not wdat(7);
				end if;
				if(bsel(2)='1')then
					timval(7 downto 0)<=wdat(23 downto 16);
					vwrite<='1';
				end if;
				if(bsel(3)='1')then
					timval(15 downto 8)<=wdat(31 downto 24);
					vwrite<='1';
				end if;
			end if;
		end if;
	end process;
	
	process(clk,rstn)
	variable lread	:std_logic;
	begin
		if(rstn='0')then
			count<=(others=>'0');
			intb<='0';
			ov<='0';
			lread:='0';
		elsif(clk' event and clk='1')then
			if(vwrite='1')then
				count<=timval;
			elsif(cs='1' and rd='1' and bsel(0)='1')then
				lread:='1';
			elsif(lread='1')then
				lread:='0';
				intb<='0';
				ov<='0';
			elsif(enable='1' and sft='1')then
				if(count=x"0001")then
					intb<='1';
					if(intb='1')then
						ov<='1';
					end if;
					count<=timval;
				else
					count<=count-1;
				end if;
			end if;
		end if;
	end process;
	
	int<=intb;
	rdat<=timval & x"00" & enable & intb & ov & "00000";
	doe<='1' when cs='1' and rd='1' else '0';
end rtl;

	