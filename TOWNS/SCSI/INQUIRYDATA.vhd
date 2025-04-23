LIBRARY	IEEE;
USE	IEEE.STD_LOGIC_1164.ALL;
USE	IEEE.STD_LOGIC_ARITH.ALL;
USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity INQUIRYDATA is
port(
	addr	:in std_logic_vector(7 downto 0);
	data	:out std_logic_vector(7 downto 0);
	
	clk	:in std_logic
);
end INQUIRYDATA;

architecture rtl of INQUIRYDATA is
begin
	process(clk)begin
		if(clk' event and clk='1')then
			case addr is
			when x"00" =>	data<="00000000";		--DASD
			when x"01" =>	data<="00000000";		--not removable
			when x"02" =>	data<=x"00";			--Version
			when x"03" =>	data<="00000000";
			when x"04" =>	data<=x"00";
			when x"05" =>	data<="00000000";
			when x"06" =>	data<="00000000";
			when x"07" =>	data<="00000000";
			when x"08" =>	data<=x"4e";	--M
			when x"09" =>	data<=x"69";	--i
			when x"0a" =>	data<=x"53";	--S
			when x"0b" =>	data<=x"54";	--T
			when x"0c" =>	data<=x"65";	--e
			when x"0d" =>	data<=x"72";	--r
			when x"0e" =>	data<=x"20";	--
			when x"0f" =>	data<=x"20";	--
			when x"10" =>	data<=x"76";	--v
			when x"11" =>	data<=x"69";	--i
			when x"12" =>	data<=x"72";	--r
			when x"13" =>	data<=x"74";	--t
			when x"14" =>	data<=x"75";	--u
			when x"15" =>	data<=x"61";	--a
			when x"16" =>	data<=x"6c";	--l
			when x"17" =>	data<=x"48";	--H
			when x"18" =>	data<=x"44";	--D	
			when x"19" =>	data<=x"44";	--D
			when x"1a" =>	data<=x"20";	--
			when x"1b" =>	data<=x"20";	--
			when x"1c" =>	data<=x"20";	--
			when x"1d" =>	data<=x"20";	--
			when x"1e" =>	data<=x"20";	--
			when x"1f" =>	data<=x"20";	--
			when x"20" =>	data<=x"30";	--0
			when x"21" =>	data<=x"30";	--0
			when x"22" =>	data<=x"30";	--0
			when x"23" =>	data<=x"30";	--0
			when x"24" =>	data<=x"30";	--0
			when x"25" =>	data<=x"30";	--0
			when x"26" =>	data<=x"30";	--0
			when x"27" =>	data<=x"30";	--0
			when x"28" =>	data<=x"30";	--0
			when x"29" =>	data<=x"30";	--0
			when x"2a" =>	data<=x"30";	--0
			when x"2b" =>	data<=x"30";	--0
			when others => data<=x"00";
			end case;
		end if;
	end process;
end rtl;

			
			