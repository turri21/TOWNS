LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CRTCREG is
port(
	cs		:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	odat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	HSW1	:out std_logic_vector(7 downto 1);
	HSW2	:out std_logic_vector(10 downto 1);
	HST	:out std_logic_vector(10 downto 1);
	VST1	:out std_logic_vector(4 downto 0);
	VST2	:out std_logic_vector(4 downto 0);
	EET	:out std_logic_vector(4 downto 0);
	VST	:out std_logic_vector(10 downto 0);
	HDS0	:out std_logic_vector(10 downto 0);
	HDE0	:out std_logic_vector(10 downto 0);
	HDS1	:out std_logic_vector(10 downto 0);
	HDE1	:out std_logic_vector(10 downto 0);
	VDS0	:out std_logic_vector(10 downto 0);
	VDE0	:out std_logic_vector(10 downto 0);
	VDS1	:out std_logic_vector(10 downto 0);
	VDE1	:out std_logic_vector(10 downto 0);
	FA0	:out std_logic_vector(15 downto 0);
	HAJ0	:out std_logic_vector(10 downto 0);
	FO0	:out std_logic_vector(15 downto 0);
	LO0	:out std_logic_vector(15 downto 0);
	FA1	:out std_logic_vector(15 downto 0);
	HAJ1	:out std_logic_vector(10 downto 0);
	FO1	:out std_logic_vector(15 downto 0);
	LO1	:out std_logic_vector(15 downto 0);
	EHAJ	:out std_logic_vector(10 downto 0);
	EVAJ	:out std_logic_vector(10 downto 0);
	ZV1	:out std_logic_vector(3 downto 0);
	ZH1	:out std_logic_vector(3 downto 0);
	ZV0	:out std_logic_vector(3 downto 0);
	ZH0	:out std_logic_vector(3 downto 0);
	CL0	:out std_logic_vector(1 downto 0);
	CL1	:out std_logic_vector(1 downto 0);
	CEN0	:out std_logic;
	CEN1	:out std_logic;
	ESM0	:out std_logic;
	ESM1	:out std_logic;
	ESYN	:out std_logic;
	START	:out std_logic;
	
	DSPTV1	:in std_logic;
	DSPTV0	:in std_logic;
	DSPTH1	:in std_logic;
	DSPTH0	:in std_logic;
	FIELD		:in std_logic;
	VSYNC		:in std_logic;
	HSYNC		:in std_logic;
	VIDIN		:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end CRTCREG;

architecture rtl of CRTCREG is
signal	addr	:std_logic_vector(4 downto 0);
signal	STARTb	:std_logic;
signal	state	:std_logic_vector(7 downto 0);
signal	dummy	:std_logic_vector(7 downto 0);
begin

	process(clk,rstn)begin
		if(rstn='0')then
			HSW1	<=(others=>'0');
			HSW2	<=(others=>'0');
			HST	<=(others=>'0');
			VST1	<=(others=>'0');
			VST2	<=(others=>'0');
			EET	<=(others=>'0');
			VST	<=(others=>'0');
			HDS0	<=(others=>'0');
			HDE0	<=(others=>'0');
			HDS1	<=(others=>'0');
			HDE1	<=(others=>'0');
			VDS0	<=(others=>'0');
			VDE0	<=(others=>'0');
			VDS1	<=(others=>'0');
			VDE1	<=(others=>'0');
			FA0	<=(others=>'0');
			HAJ0	<=(others=>'0');
			FO0	<=(others=>'0');
			LO0	<=(others=>'0');
			FA1	<=(others=>'0');
			HAJ1	<=(others=>'0');
			FO1	<=(others=>'0');
			LO1	<=(others=>'0');
			EHAJ	<=(others=>'0');
			EVAJ	<=(others=>'0');
			ZV1	<=(others=>'0');
			ZH1	<=(others=>'0');
			ZV0	<=(others=>'0');
			ZH0	<=(others=>'0');
			CL0	<=(others=>'0');
			CL1	<=(others=>'0');
			CEN0	<='0';
			CEN1	<='0';
			ESM0	<='0';
			ESM1	<='0';
			ESYN	<='0';
			STARTb<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(bsel(0)='1')then
					addr<=wdat(4 downto 0);
				end if;
				if(bsel(2)='1')then
					case addr is
					when "00000" =>
						HSW1<=wdat(23 downto 17);
					when "00001" =>
						HSW2(7 downto 1)<=wdat(23 downto 17);
					when "00100" =>
						HST(7 downto 1)<=wdat(23 downto 17);
					when "00101" =>
						VST1<=wdat(20 downto 16);
					when "00110" =>
						VST2<=wdat(20 downto 16);
					when "00111" =>
						EET<=wdat(20 downto 16);
					when "01000" =>
						VST(7 downto 0)<=wdat(23 downto 16);
					when "01001" =>
						HDS0(7 downto 0)<=wdat(23 downto 16);
					when "01010" =>
						HDE0(7 downto 0)<=wdat(23 downto 16);
					when "01011" =>
						HDS1(7 downto 0)<=wdat(23 downto 16);
					when "01100" =>
						HDE1(7 downto 0)<=wdat(23 downto 16);
					when "01101" =>
						VDS0(7 downto 0)<=wdat(23 downto 16);
					when "01110" =>
						VDE0(7 downto 0)<=wdat(23 downto 16);
					when "01111" =>
						VDS1(7 downto 0)<=wdat(23 downto 16);
					when "10000" =>
						VDE1(7 downto 0)<=wdat(23 downto 16);
					when "10001" =>
						FA0(7 downto 0)<=wdat(23 downto 16);
					when "10010" =>
						HAJ0(7 downto 0)<=wdat(23 downto 16);
					when "10011" =>
						FO0(7 downto 0)<=wdat(23 downto 16);
					when "10100" =>
						LO0(7 downto 0)<=wdat(23 downto 16);
					when "10101" =>
						FA1(7 downto 0)<=wdat(23 downto 16);
					when "10110" =>
						HAJ1(7 downto 0)<=wdat(23 downto 16);
					when "10111" =>
						FO1(7 downto 0)<=wdat(23 downto 16);
					when "11000" =>
						LO1(7 downto 0)<=wdat(23 downto 16);
					when "11001" =>
						EHAJ(7 downto 0)<=wdat(23 downto 16);
					when "11010" =>
						EVAJ(7 downto 0)<=wdat(23 downto 16);
					when "11011" =>
						ZH0<=wdat(19 downto 16);
						ZV0<=wdat(23 downto 20);
					when "11100" =>
						CL0<=wdat(17 downto 16);
						CL1<=wdat(19 downto 18);
						CEN0<=wdat(20);
						CEN1<=wdat(21);
						ESM0<=wdat(22);
						ESM1<=wdat(23);
					when others =>
					end case;
				end if;
				if(bsel(3)='1')then
					case addr is
					when "00001" =>
						HSW2(9 downto 8)<=wdat(25 downto 24);
					when "00100" =>
						HST(10 downto 8)<=wdat(26 downto 24);
					when "01000" =>
						VST(10 downto 8)<=wdat(26 downto 24);
					when "01001" =>
						HDS0(10 downto 8)<=wdat(26 downto 24);
					when "01010" =>
						HDE0(10 downto 8)<=wdat(26 downto 24);
					when "01011" =>
						HDS1(10 downto 8)<=wdat(26 downto 24);
					when "01100" =>
						HDE1(10 downto 8)<=wdat(26 downto 24);
					when "01101" =>
						VDS0(10 downto 8)<=wdat(26 downto 24);
					when "01110" =>
						VDE0(10 downto 8)<=wdat(26 downto 24);
					when "01111" =>
						VDS1(10 downto 8)<=wdat(26 downto 24);
					when "10000" =>
						VDE1(10 downto 8)<=wdat(26 downto 24);
					when "10001" =>
						FA0(15 downto 8)<=wdat(31 downto 24);
					when "10010" =>
						HAJ0(10 downto 8)<=wdat(26 downto 24);
					when "10011" =>
						FO0(15 downto 8)<=wdat(31 downto 24);
					when "10100" =>
						LO0(15 downto 8)<=wdat(31 downto 24);
					when "10101" =>
						FA1(10 downto 8)<=wdat(26 downto 24);
					when "10110" =>
						HAJ1(10 downto 8)<=wdat(26 downto 24);
					when "10111" =>
						FO1(10 downto 8)<=wdat(26 downto 24);
					when "11000" =>
						LO1(10 downto 8)<=wdat(26 downto 24);
					when "11001" =>
						EHAJ(10 downto 8)<=wdat(26 downto 24);
					when "11010" =>
						EVAJ(10 downto 8)<=wdat(26 downto 24);
					when "11011" =>
						ZH1<=wdat(27 downto 24);
						ZV1<=wdat(31 downto 28);
					when "11100" =>
						ESYN<=wdat(30);
						STARTb<=wdat(31);
					when others =>
					end case;
				end if;
			end if;
		end if;
	end process;
	START<=STARTb;
	state<=STARTb & "0000000";
	dummy<=DSPTV1 & DSPTV0 & DSPTH1 & DSPTH0 & FIELD & VSYNC & HSYNC & VIDIN;
	
	odat<=	state & x"0000" & "000" & addr when addr="11100" else
				dummy & x"0000" & "000" & addr when addr="11110" else
				x"000000" & "000" & addr;
	doe<=rd when cs='1' else '0';

end rtl;