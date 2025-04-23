LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rtc58321 is
generic(
	clkfreq	:integer	:=20000;
	YEAROFF	:std_logic_vector(7 downto 0)	:=x"00"
);
port(
	cs		:in std_logic;
	addr	:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	RTCIN	:in std_logic_vector(64 downto 0);
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end rtc58321;
architecture rtl of rtc58321 is
signal	YEH		:std_logic_vector(3 downto 0);
signal	YEL		:std_logic_vector(3 downto 0);
signal	MON		:std_logic_vector(3 downto 0);
signal	DAYH	:std_logic_vector(1 downto 0);
signal	DAYL	:std_logic_vector(3 downto 0);
signal	WDAY	:std_logic_vector(2 downto 0);
signal	HORH	:std_logic_vector(1 downto 0);
signal	HORL	:std_logic_vector(3 downto 0);
signal	MINH	:std_logic_vector(2 downto 0);
signal	MINL	:std_logic_vector(3 downto 0);
signal	SECH	:std_logic_vector(2 downto 0);
signal	SECL	:std_logic_vector(3 downto 0);
signal	HZ		:std_logic;

signal	YEHWD	:std_logic_vector(3 downto 0);
signal	YELWD	:std_logic_vector(3 downto 0);
signal	MONWD	:std_logic_vector(3 downto 0);
signal	DAYHWD	:std_logic_vector(1 downto 0);
signal	DAYLWD	:std_logic_vector(3 downto 0);
signal	WDAYWD	:std_logic_vector(2 downto 0);
signal	HORHWD	:std_logic_vector(1 downto 0);
signal	HORLWD	:std_logic_vector(3 downto 0);
signal	MINHWD	:std_logic_vector(2 downto 0);
signal	MINLWD	:std_logic_vector(3 downto 0);
signal	SECHWD	:std_logic_vector(2 downto 0);
signal	SECLWD	:std_logic_vector(3 downto 0);

signal	YEHWR	:std_logic;
signal	YELWR	:std_logic;
signal	MONWR	:std_logic;
signal	DAYHWR	:std_logic;
signal	DAYLWR	:std_logic;
signal	WDAYWR	:std_logic;
signal	HORHWR	:std_logic;
signal	HORLWR	:std_logic;
signal	MINHWR	:std_logic;
signal	MINLWR	:std_logic;
signal	SECHWR	:std_logic;
signal	SECLWR	:std_logic;
signal	SECZWR	:std_logic;

signal	YEHID	:std_logic_vector(3 downto 0);
signal	YELID	:std_logic_vector(3 downto 0);
signal	MONID	:std_logic_vector(3 downto 0);
signal	DAYHID	:std_logic_vector(1 downto 0);
signal	DAYLID	:std_logic_vector(3 downto 0);
signal	WDAYID	:std_logic_vector(2 downto 0);
signal	HORHID	:std_logic_vector(1 downto 0);
signal	HORLID	:std_logic_vector(3 downto 0);
signal	MINHID	:std_logic_vector(2 downto 0);
signal	MINLID	:std_logic_vector(3 downto 0);
signal	SECHID	:std_logic_vector(2 downto 0);
signal	SECLID	:std_logic_vector(3 downto 0);
signal	SYSSET	:std_logic;

signal	csel		:std_logic;
signal	raddr		:std_logic_vector(3 downto 0);
signal	rread		:std_logic;
signal	rwrite	:std_logic;
signal	rsel		:std_logic;
signal	rdata		:std_logic_vector(3 downto 0);
signal	MONHt	:std_logic;
signal	MONLt	:std_logic_vector(3 downto 0);
signal	monwdat	:std_logic_vector(3 downto 0);
signal	subsec	:integer range 0 to clkfreq-1;
constant HZthresh	:integer	:=clkfreq/2000;
component rtcbody
generic(
	clkfreq	:integer	:=21477270
);
port(
	YERHIN	:in std_logic_vector(3 downto 0);
	YERHWR	:in std_logic;
	YERLIN	:in std_logic_vector(3 downto 0);
	YERLWR	:in std_logic;
	MONIN	:in std_logic_vector(3 downto 0);
	MONWR	:in std_logic;
	DAYHIN	:in std_logic_vector(1 downto 0);
	DAYHWR	:in std_logic;
	DAYLIN	:in std_logic_vector(3 downto 0);
	DAYLWR	:in std_logic;
	WDAYIN	:in std_logic_vector(2 downto 0);
	WDAYWR	:in std_logic;
	HORHIN	:in std_logic_vector(1 downto 0);
	HORHWR	:in std_logic;
	HORLIN	:in std_logic_vector(3 downto 0);
	HORLWR	:in std_logic;
	MINHIN	:in std_logic_vector(2 downto 0);
	MINHWR	:in std_logic;
	MINLIN	:in std_logic_vector(3 downto 0);
	MINLWR	:in std_logic;
	SECHIN	:in std_logic_vector(2 downto 0);
	SECHWR	:in std_logic;
	SECLIN	:in std_logic_vector(3 downto 0);
	SECLWR	:in std_logic;
	SECZERO	:in std_logic;
	
	YERHOUT	:out std_logic_vector(3 downto 0);
	YERLOUT	:out std_logic_vector(3 downto 0);
	MONOUT	:out std_logic_vector(3 downto 0);
	DAYHOUT	:out std_logic_vector(1 downto 0);
	DAYLOUT	:out std_logic_vector(3 downto 0);
	WDAYOUT	:out std_logic_vector(2 downto 0);
	HORHOUT	:out std_logic_vector(1 downto 0);
	HORLOUT	:out std_logic_vector(3 downto 0);
	MINHOUT	:out std_logic_vector(2 downto 0);
	MINLOUT	:out std_logic_vector(3 downto 0);
	SECHOUT	:out std_logic_vector(2 downto 0);
	SECLOUT	:out std_logic_vector(3 downto 0);

	OUT1Hz	:out std_logic;
	SUBSEC	:out integer range 0 to clkfreq-1;
	
	fast	:in std_logic;

 	sclk	:in std_logic;
	rstn	:in std_logic
);
end component;


begin
	rtc	:rtcbody generic map(clkfreq) port map(
		YERHIN	=>YEHWD,
		YERHWR	=>YEHWR,
		YERLIN	=>YELWD,
		YERLWR	=>YELWR,
		MONIN	=>MONWD,
		MONWR	=>MONWR,
		DAYHIN	=>DAYHWD,
		DAYHWR	=>DAYHWR,
		DAYLIN	=>DAYLWD,
		DAYLWR	=>DAYLWR,
		WDAYIN	=>WDAYWD,
		WDAYWR	=>WDAYWR,
		HORHIN	=>HORHWD,
		HORHWR	=>HORHWR,
		HORLIN	=>HORLWD,
		HORLWR	=>HORLWR,
		MINHIN	=>MINHWD,
		MINHWR	=>MINHWR,
		MINLIN	=>MINLWD,
		MINLWR	=>MINLWR,
		SECHIN	=>SECHWD,
		SECHWR	=>SECHWR,
		SECLIN	=>SECLWD,
		SECLWR	=>SECLWR,
		SECZERO	=>SECZWR,
		
		YERHOUT	=>YEH,
		YERLOUT	=>YEL,
		MONOUT	=>MON,
		DAYHOUT	=>DAYH,
		DAYLOUT	=>DAYL,
		WDAYOUT	=>WDAY,
		HORHOUT	=>HORH,
		HORLOUT	=>HORL,
		MINHOUT	=>MINH,
		MINLOUT	=>MINL,
		SECHOUT	=>SECH,
		SECLOUT	=>SECL,

		OUT1Hz	=>open,
		SUBSEC	=>subsec,
		
		fast	=>'0',

		sclk	=>clk,
		rstn	=>'1'
	);
	
	process(clk,rstn)begin
		if(rstn='0')then
			HZ<='0';
		elsif(clk' event and clk='1')then
			if(subsec<HZthresh)then
				HZ<='0';
			else
				HZ<='1';
			end if;
		end if;
	end process;
			
	SECLID<=RTCIN(3 downto 0);
	SECHID<=RTCIN(6 downto 4);
	MINLID<=RTCIN(11 downto 8);
	MINHID<=RTCIN(14 downto 12);
	HORLID<=RTCIN(19 downto 16);
	HORHID<=RTCIN(21 downto 20);
	DAYLID<=RTCIN(27 downto 24);
	DAYHID<=RTCIN(29 downto 28);
	MONID<=	RTCIN(35 downto 32) when RTCIN(36)='0' else
				RTCIN(35 downto 32)+x"a";
	
	process(RTCIN)
	variable carry	:std_logic;
	variable	tmpval	:std_logic_vector(4 downto 0);
	begin
		tmpval:=('0' & RTCIN(43 downto 40))+('0' & YEAROFF(3 downto 0));
		if(tmpval>"01010")then
			carry:='1';
			tmpval:=tmpval-"01010";
		else
			carry:='0';
		end if;
		YELID<=tmpval(3 downto 0);
		tmpval:=('0' & RTCIN(47 downto 44))+('0' & YEAROFF(7 downto 4));
		if(carry='1')then
			tmpval:=tmpval+1;
		end if;
		if(tmpval>"01010")then
			tmpval:=tmpval-"01010";
		end if;
		YEHID<=tmpval(3 downto 0);
	end process;

	WDAYID<=RTCIN(50 downto 48);

	YEHWD<=YEHID when SYSSET='1' else rdata(3 downto 0);
	YELWD<=YELID when SYSSET='1' else rdata(3 downto 0);
	MONWD<=MONID when SYSSET='1' else monwdat;
	DAYHWD<=DAYHID when SYSSET='1' else rdata(1 downto 0);
	DAYLWD<=DAYLID when SYSSET='1' else rdata(3 downto 0);
	WDAYWD<=WDAYID when SYSSET='1' else rdata(2 downto 0);
	HORHWD<=HORHID when SYSSET='1' else rdata(1 downto 0);
	HORLWD<=HORLID when SYSSET='1' else rdata(3 downto 0);
	MINHWD<=MINHID when SYSSET='1' else rdata(2 downto 0);
	MINLWD<=MINLID when SYSSET='1' else rdata(3 downto 0);
	SECHWD<=SECHID when SYSSET='1' else rdata(2 downto 0);
	SECLWD<=SECLID when SYSSET='1' else rdata(3 downto 0);
	
	process(clk,rstn)
	variable state	:integer range 0 to 2;
	begin
		if(rstn='0')then
			state:=0;
			SYSSET<='0';
		elsif(clk' event and clk='1')then
			SYSSET<='0';
			case state is
			when 2 =>
			when 1 =>
				SYSSET<='1';
				state:=2;
			when 0 =>
				if(RTCIN(64)='1')then
					state:=1;
				end if;
			when others =>
				state:=2;
			end case;
		end if;
	end process;
	
	YEHWR<=	'1' when raddr=x"c" and rwrite='1' else SYSSET;
	YELWR<=	'1' when raddr=x"b" and rwrite='1' else SYSSET;
	MONWR<=	'1' when (raddr=x"9" or raddr=x"a") and rwrite='1' else SYSSET;
	DAYHWR<='1' when raddr=x"8" and rwrite='1' else SYSSET;
	DAYLWR<='1' when raddr=x"7" and rwrite='1' else SYSSET;
	WDAYWR<='1' when raddr=x"6" and rwrite='1' else SYSSET;
	HORHWR<='1' when raddr=x"5" and rwrite='1' else SYSSET;
	HORLWR<='1' when raddr=x"4" and rwrite='1' else SYSSET;
	MINHWR<='1' when raddr=x"3" and rwrite='1' else SYSSET;
	MINLWR<='1' when raddr=x"2" and rwrite='1' else SYSSET;
	SECHWR<='1' when raddr=x"1" and rwrite='1' else SYSSET;
	SECLWR<='1' when raddr=x"0" and rwrite='1' else SYSSET;
	SECZWR<='1' when raddr=x"0" and rwrite='1' else SYSSET;
	
	process(clk,rstn)begin
		if(rstn='0')then
			MONHt<='0';
			MONLt<=x"0";
		elsif(clk' event and clk='1')then
			if(rwrite='1')then
				case raddr is
				when x"9" =>
					MONLt<=rdata(3 downto 0);
				when x"a" =>
					MONHt<=rdata(0);
				when others =>
				end case;
			end if;
		end if;
	end process;
	monwdat<=MONLt when MONHt='0' else MONLt+x"a";
	
	process(clk,rstn)begin
		if(rstn='0')then
			rwrite<='0';
			rread<='0';
			rdata<=(others=>'0');
			rsel<='0';
			raddr<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				case addr is
				when '0' =>
					if(csel='1')then
						rdata<=wdat(3 downto 0);
					end if;
				when '1' =>
					rsel<=wdat(0);
					rwrite<=wdat(1);
					rread<=wdat(2);
					csel<=wdat(7);
				end case;
			end if;
			if(rsel='1' and csel='1')then
				raddr<=rdata;
			end if;
			if(rread='1' and csel='1')then
				case raddr is
				when x"0" =>
					rdata<=SECL;
				when x"1" =>
					rdata<='0' & SECH;
				when x"2" =>
					rdata<=MINL;
				when x"3" =>
					rdata<='0' & MINH;
				when x"4" =>
					rdata<=HORL;
				when x"5" =>
					rdata<="00" & HORH;
				when x"6" =>
					rdata<='0' & WDAY;
				when x"7" =>
					rdata<=DAYL;
				when x"8" =>
					rdata<="00" & DAYH;
				when x"9" =>
					if(MON<x"a")then
						rdata<=MON;
					else
						rdata<=mon-x"a";
					end if;
				when x"a" =>
					if(MON<x"a")then
						rdata<=x"0";
					else
						rdata<=x"1";
					end if;
				when x"b" =>
					rdata<=YEL;
				when x"c" =>
					rdata<=YEH;
				when others =>
					rdata<=x"0";
				end case;
			end if;
		end if;
	end process;
					
	rdat<=HZ & "000" & rdata;
	doe<='1' when cs='1' and addr='0' and rd='1' else '0';
	
end rtl;
			
