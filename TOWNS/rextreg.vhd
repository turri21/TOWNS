LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rextreg	is
port(
	mcs	:in std_logic;
	mbsel	:in std_logic_vector(3 downto 0);
	mrd	:in std_logic;
	mwr	:in std_logic;
	mrdat	:out std_logic_vector(31 downto 0);
	mwdat	:in std_logic_vector(31 downto 0);
	mrval	:out std_logic;
	
	iocs	:in std_logic;
	ioaddr:in std_logic;
	iord	:in std_logic;
	iowr	:in std_logic;
	iordat	:out std_logic_vector(7 downto 0);
	iowdat	:in std_logic_vector(7 downto 0);
	iodoe		:out std_logic;

	ANKCG		:out std_logic;
	BEEPEN	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end rextreg;

architecture rtl of rextreg is
begin

	process(clk,rstn)begin
		if(rstn='0')then
			ANKCG<='0';
			BEEPEN<='0';
			mrval<='0';
		elsif(clk' event and clk='1')then
			mrval<='0';
			if(mcs='1' and mwr='1')then
				if(mbsel(0)='1')then
					BEEPEN<='0';
				end if;
				if(mbsel(1)='1')then
					ANKCG<=mwdat(8);
				end if;
			elsif(mcs='1' and mrd='1')then
				if(mbsel(0)='1')then
					BEEPEN<='1';
				end if;
				mrval<='1';
			end if;
			if(iocs='1' and iowr='1')then
				case ioaddr is
				when '0' =>
					BEEPEN<='0';
				when '1' =>
					ANKCG<=iowdat(0);
				when others =>
				end case;
			elsif(iocs='1' and iord='1')then
				case ioaddr is
				when '0' =>
					BEEPEN<='1';
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	iordat<=(others=>'0');
	mrdat<=(others=>'0');
	iodoe<=iocs and  iord;
						
	
end rtl;
