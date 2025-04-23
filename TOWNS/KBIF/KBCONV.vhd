LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity KBCONV is
generic(
	CLKCYC	:integer	:=20000;
	SFTCYC	:integer	:=400;
	RPSET		:integer	:=1;
	KWAIT		:integer	:=960
);
port(
	cs		:in std_logic;
	addr	:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	
	KBCLKIN	:in std_logic;
	KBCLKOUT:out std_logic;
	KBDATIN	:in std_logic;
	KBDATOUT:out std_logic;
	
	mous_recv	:in std_logic;
	mous_clr		:out std_logic;
	mous_Xdat	:in std_logic_vector(9 downto 0);
	mous_Ydat	:in std_logic_Vector(9 downto 0);
	mous_swdat	:in std_logic_vector(1 downto 0);
	
	emuen		:in std_logic;
	emurx		:out std_logic;
	emurxdat	:out std_logic_vector(7 downto 0);

	clk	:in std_logic;
	rstn	:in std_logic
);
end KBCONV;

architecture rtl of KBCONV is

signal	E0en	:std_logic;
signal	F0en	:std_logic;
signal	SFT		:std_logic;
signal	TBLADR	:std_logic_vector(7 downto 0);
signal	TBLADRx	:std_logic_vector(7 downto 0);
signal	TBLDAT	:std_logic_vector(7 downto 0);
signal	semuen	:std_logic;
signal	shiften	:std_logic;
signal	ctrlen	:std_logic;
signal	keyrecv	:std_logic;
signal	break		:std_logic;
signal	rep		:std_logic;
signal	lastkey	:std_logic_vector(7 downto 0);


constant cmd_reset	:std_logic_vector(4 downto 0)	:="00001";
constant cmd_reset3	:std_logic_vector(4 downto 0)	:="00000";
constant cmd_simon	:std_logic_vector(4 downto 0)	:="00100";
constant cmd_simoff	:std_logic_vector(4 downto 0)	:="00101";
constant cmd_tst400	:std_logic_vector(4 downto 0)	:="01001";
constant cmd_tst500	:std_logic_vector(4 downto 0)	:="01010";
constant cmd_tst300	:std_logic_vector(4 downto 0)	:="01011";
constant cmd_trp50	:std_logic_vector(4 downto 0)	:="01100";
constant cmd_trp30	:std_logic_vector(4 downto 0)	:="01101";
constant cmd_trp20	:std_logic_vector(4 downto 0)	:="01110";
constant cmd_slanon	:std_logic_vector(4 downto 0)	:="10000";
constant cmd_slanoff	:std_logic_vector(4 downto 0)	:="10001";
constant cmd_nmiack	:std_logic_vector(4 downto 0)	:="10010";
signal	cmdrecv		:std_logic;
signal	cmddat		:std_logic_vector(4 downto 0);

signal	curtstart	:std_logic_Vector(1 downto 0);
signal	curtrep		:std_logic_Vector(1 downto 0);
signal	intmsk		:std_logic;
signal	simen			:std_logic;
signal	slaen			:std_logic;

signal	intreq	:std_logic;
signal	intb		:std_logic;
signal	IBF		:std_logic;
signal	OBF		:std_logic;

signal	ps2tmat		:std_logic_vector(7 downto 0);

signal	kbdatreg	:std_logic_vector(7 downto 0);
signal	kbstatus	:std_logic_vector(7 downto 0);
signal	kbintsrc	:std_logic_vector(7 downto 0);
signal	fifowdat	:std_logic_vector(7 downto 0);
signal	fifowr	:std_logic;
signal	fifordat	:std_logic_vector(7 downto 0);
signal	fiford	:std_logic;
signal	fifoex	:std_logic;

constant waitlen	:integer	:=CLKCYC*1000/KWAIT;


type KBSTATE_T is (
	KS_IDLE,
	KS_RESET,
	KS_RESET_BAT,
	KS_IDRD,
	KS_IDRD_ACK,
	KS_IDRD_LB,
	KS_IDRD_HB,
	KS_LEDS,
	KS_LEDW,
	KS_LEDB,
	KS_LEDS_ACK,
	KS_SETREPS,
	KS_SETREPW,
	KS_SETREPB,
	KS_SETREP_ACK,
	KS_RDTBL,
	KS_WDAT1,
	KS_WDAT2,
	KS_RESET_W1,
	KS_RESET_W2,
	KS_RESET_W3,
	KS_RESET_W4,
	KS_RESET_W5,
	KS_RESET_W6,
	KS_MOUS0,
	KS_MOUS1,
	KS_MOUS2
);
signal	KBSTATE	:KBSTATE_T;
signal	KB_TXDAT	:std_logic_vector(7 downto 0);
signal	KB_RXDAT	:std_logic_vector(7 downto 0);
signal	KB_WRn		:std_logic;
signal	KB_BUSY		:std_logic;
signal	KB_RXED		:std_logic;
signal	KB_RESET	:std_logic;
signal	KB_COL		:std_logic;
signal	KB_PERR		:std_logic;
signal	WAITCNT		:integer range 0 to waitlen-1;
constant waitcont	:integer	:=1;		--ms
constant waitsep	:integer	:=20;		--ms
constant waitccount	:integer	:=SFTCYC*waitcont;
constant waitscount	:integer	:=SFTCYC*waitsep;
constant waitrcount	:integer	:=SFTCYC*1000/1920;
signal	WAITSFT		:integer range 0 to waitscount;
signal	MOUS_TX0		:std_logic_vector(7 downto 0);
signal	MOUS_TX1		:std_logic_vector(7 downto 0);
signal	MOUS_TX2		:std_logic_vector(7 downto 0);

component PS2IF
generic(
	SFTCYC	:integer	:=400;		--kHz
	STCLK	:integer	:=150;		--usec
	TOUT	:integer	:=150		--usec
);
port(
	DATIN	:in std_logic_vector(7 downto 0);
	DATOUT	:out std_logic_vector(7 downto 0);
	WRn		:in std_logic;
	BUSY	:out std_logic;
	RXED	:out std_logic;
	RESET	:in std_logic;
	COL		:out std_logic;
	PERR	:out std_logic;
	TWAIT	:in std_logic;
	
	KBCLKIN	:in	std_logic;
	KBCLKOUT :out std_logic;
	KBDATIN	:in std_logic;
	KBDATOUT :out std_logic;
	
	SFT		:in std_logic;
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component SFTCLK
generic(
	SYS_CLK	:integer	:=20000;
	OUT_CLK	:integer	:=1600;
	selWIDTH :integer	:=2
);
port(
	sel		:in std_logic_vector(selWIDTH-1 downto 0);
	SFT		:out std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component kbtbl
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component datfifo
generic(
	depth		:integer	:=32;
	dwidth	:integer	:=8
);
port(
	datin		:in std_logic_vector(dwidth-1 downto 0);
	datwr		:in std_logic;
	
	datout	:out std_logic_vector(dwidth-1 downto 0);
	datrd		:in std_logic;
	
	indat		:out std_logic;
	buffull	:out std_logic;
	datnum	:out integer range 0 to depth-1;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

begin

	process(clk)begin
		if(clk' event and clk='1')then
			semuen<=emuen;
		end if;
	end process;

	KBSFT	:sftclk generic map(CLKCYC,SFTCYC,1) port map("1",SFT,clk,rstn);

	KB	:PS2IF generic map(400,150,150) port map(
		DATIN		=>KB_TXDAT,
		DATOUT	=>KB_RXDAT,
		WRn		=>KB_WRn,
		BUSY		=>KB_BUSY,
		RXED		=>KB_RXED,
		RESET		=>KB_RESET,
		COL		=>KB_COL,
		PERR		=>KB_PERR,
		TWAIT		=>'0',
	
		KBCLKIN	=>KBCLKIN,
		KBCLKOUT	=>KBCLKOUT,
		KBDATIN	=>KBDATIN,
		KBDATOUT	=>KBDATOUT,
	
		SFT		=>SFT,
		clk		=>clk,
		rstn		=>rstn
	);

	ps2tmat(7)<='0';
	ps2tmat(6 downto 5)<=
		"01" when curtstart="01" else
		"01" when curtstart="10" else
		"10" when curtstart="11" else
		"01";
	ps2tmat(4 downto 0)<=
		"00100" when curtrep="00" else
		"00000" when curtrep="01" else
		"00000" when curtrep="10" else
		"00000";
	
	process(clk,rstn)begin
		if(rstn='0')then
			curtstart<="01";
			curtrep<="01";
			cmdrecv<='0';
			cmddat<=(others=>'0');
			intmsk<='0';
			simen<='0';
			slaen<='0';
		elsif(clk' event and clk='1')then
			cmdrecv<='0';
			if(cs='1' and wr='1')then
				case addr is
				when '0' =>
					if(bsel(0)='1')then
						if(wdat(7 downto 0)=x"a1" or wdat(7 downto 0)=x"a2")then
							curtstart<="01";
							curtrep<="01";
--							intmsk<='0';
							simen<='0';
							slaen<='0';
							cmddat<="00000";
							cmdrecv<='1';
						end if;
					end if;
					if(bsel(2)='1')then
						if(wdat(23 downto 21)="101")then
							cmddat<=wdat(20 downto 16);
							cmdrecv<='1';
							case wdat(20 downto 16) is
							when cmd_reset =>
								curtstart<="01";
								curtrep<="01";
--								intmsk<='0';
								simen<='0';
								slaen<='0';
							when cmd_simon	=>
								simen<='1';
							when cmd_simoff =>
								simen<='0';
							when cmd_tst400 =>
								curtstart<="01";
							when cmd_tst500 =>
								curtstart<="10";
							when cmd_tst300 =>
								curtstart<="11";
							when cmd_trp50 =>
								curtrep<="00";
							when cmd_trp30 =>
								curtrep<="01";
							when cmd_trp20 =>
								curtrep<="10";
							when cmd_slanon =>
								slaen<='1';
							when cmd_slanoff =>
								slaen<='0';
							when others =>
							end case;
						end if;
					end if;
				when '1' =>
					if(bsel(0)='1')then
						intmsk<=wdat(0);
					end if;
				end case;
			end if;
		end if;
	end process;

	process(clk,rstn)
	variable iBITSEL	:integer range 0 to 7;
	begin
		if(rstn='0')then
			KBSTATE<=KS_RESET;
			E0EN<='0';
			F0EN<='0';
			KB_WRn<='1';
			KB_RESET<='0';
			WAITCNT<=0;
			WAITSFT<=0;
			
			shiften<='0';
			ctrlen<='0';
			KB_TXDAT<=(others=>'0');
			keyrecv<='0';
			break<='0';
			IBF<='0';
			lastkey<=(others=>'0');
			emurxdat<=(others=>'0');
			fifowdat<=(others=>'0');
			fifowr<='0';
			MOUS_TX0<=(others=>'0');
			MOUS_TX1<=(others=>'0');
			MOUS_TX2<=(others=>'0');
			mous_clr<='0';
		elsif(clk' event and clk='1')then
			KB_WRn<='1';
			keyrecv<='0';
			emurx<='0';
			fifowr<='0';
			mous_clr<='0';
			if(WAITCNT>0)then
				WAITCNT<=WAITCNT-1;
			elsif(WAITSFT>0)then
				if(SFT='1')then
					WAITSFT<=WAITSFT-1;
				end if;
			else
				case KBSTATE is
				when KS_RESET =>
					if(KB_BUSY='0')then
						KB_TXDAT<=x"ff";
						KB_WRn<='0';
						KBSTATE<=KS_RESET_BAT;
					end if;
				when KS_RESET_BAT =>
					if(KB_RXED='1' and KB_RXDAT=x"aa")then
						WAITSFT<=waitscount;
						KBSTATE<=KS_IDRD;
					end if;
				when KS_IDRD =>
					if(KB_BUSY='0')then
						KB_TXDAT<=x"f2";
						KB_WRn<='0';
						KBSTATE<=KS_IDRD_ACK;
					end if;
				when KS_IDRD_ACK =>
					if(KB_RXED='1' and KB_RXDAT=x"fa")then
						KBSTATE<=KS_IDRD_LB;
					end if;
				when KS_IDRD_LB =>
					if(KB_RXED='1')then
						KBSTATE<=KS_IDRD_HB;
					end if;
				when KS_IDRD_HB =>
					if(KB_RXED='1')then
						WAITSFT<=waitscount;
						KBSTATE<=KS_LEDS;
					end if;
				when KS_LEDS =>
					if(KB_BUSY='0')then
						KB_TXDAT<=x"ed";
						KB_WRn<='0';
						KBSTATE<=KS_LEDW;
						WAITSFT<=1;
					end if;
				when KS_LEDW =>
					if(KB_BUSY='0')then
						WAITSFT<=waitccount;
						KBSTATE<=KS_LEDB;
					end if;
				when KS_LEDB =>
					if(KB_BUSY='0')then
						KB_TXDAT<="00000000" ;
						KB_WRn<='0';
						KBSTATE<=KS_LEDS_ACK;
					end if;
				when KS_LEDS_ACK =>
					if(KB_RXED='1')then
--					monout<=KB_RXDAT;
						if(KB_RXDAT=x"fa")then
							WAITSFT<=waitscount;
							if(RPSET=0)then
								KBSTATE<=KS_IDLE;
							else
								KBSTATE<=KS_SETREPS;
							end if;
						elsif(KB_RXDAT=x"fe")then
							WAITSFT<=waitscount;
							KBSTATE<=KS_LEDS;
						end if;
					end if;
				when KS_SETREPS =>
					if(KB_BUSY='0')then
						KB_TXDAT<=x"f3";
						KB_WRn<='0';
						KBSTATE<=KS_SETREPW;
					end if;
				when KS_SETREPW =>
					if(KB_BUSY='0')then
						WAITSFT<=waitccount;
						KBSTATE<=KS_SETREPB;
					end if;
				when KS_SETREPB =>
					if(KB_BUSY='0')then
						KB_TXDAT<="00100111";
						KB_WRn<='0';
						KBSTATE<=KS_SETREP_ACK;
					end if;
				when KS_SETREP_ACK =>
					if(KB_RXED='1')then
						if(KB_RXDAT=x"fa")then
							WAITSFT<=waitscount;
							KBSTATE<=KS_IDLE;
						else
							WAITSFT<=waitscount;
							KBSTATE<=KS_SETREPS;
						end if;
					end if;
				when KS_IDLE =>
					IBF<='0';
					if(cmdrecv='1')then
						case cmddat is
						when cmd_reset =>
							KBSTATE<=KS_RESET_W1;
							IBF<='1';
						when cmd_reset3 =>
							KBSTATE<=KS_RESET_W3;
							IBF<='1';
						when cmd_TST400 | cmd_tst500 | cmd_tst300 |
								cmd_trp50 | cmd_trp30 | cmd_trp20 =>
							KBSTATE<=KS_SETREPS;
							IBF<='1';
						when others =>
						end case;
					end if;
					if(semuen='1')then
						if(KB_RXED='1')then
							emurx<='1';
							emurxdat<=KB_RXDAT;
						end if;
					elsif(KB_RXED='1' and semuen='0')then
						if(KB_RXDAT=x"e0")then
							E0en<='1';
						elsif(KB_RXDAT=x"f0")then
							F0en<='1';
						else
							KBSTATE<=KS_RDTBL;
							TBLADR<=KB_RXDAT;
							WAITCNT<=2;
						end if;
					elsif(mous_recv='1')then
						fifowdat(7 downto 2)<="111001";
						case mous_Xdat(9 downto 7) is
						when "000" =>
							fifowdat(0)<='0';
							MOUS_TX0<='0' & mous_Xdat(6 downto 0);
						when "001" | "010" | "011" =>
							fifowdat(0)<='0';
							MOUS_TX0<=x"3f";
						when "111" =>
							fifowdat(0)<='1';
							MOUS_TX0<='0' & mous_Xdat(6 downto 0);
						when "110" | "101" | "100" =>
							fifowdat(0)<='1';
							MOUS_TX0<=x"40";
						when others =>
							fifowdat(0)<='0';
							MOUS_TX0<=x"00";
						end case;
						case mous_Ydat(9 downto 7) is
						when "000" =>
							fifowdat(1)<='0';
							MOUS_TX1<='0' & mous_Ydat(6 downto 0);
						when "001" | "010" | "011" =>
							fifowdat(1)<='0';
							MOUS_TX1<=x"3f";
						when "111" =>
							fifowdat(1)<='1';
							MOUS_TX1<='0' & mous_Ydat(6 downto 0);
						when "110" | "101" | "100" =>
							fifowdat(1)<='1';
							MOUS_TX1<=x"40";
						when others =>
							fifowdat(1)<='0';
							MOUS_TX1<=x"00";
						end case;
						MOUS_TX2<="00000" & not mous_swdat & '0';
						fifowr<='1';
						mous_clr<='1';
						KBSTATE<=KS_MOUS0;
						WAITCNT<=waitlen-1;
					end if;
				when KS_RESET_W1 =>
					fifowdat<=x"b0";
					fifowr<='1';
					KBSTATE<=KS_RESET_W2;
					WAITCNT<=waitlen-1;
				when KS_RESET_W2 =>
					fifowdat<=x"7f";
					fifowr<='1';
					KBSTATE<=KS_RESET;
					WAITCNT<=waitlen-1;
				when KS_RESET_W3 =>
					fifowdat<=x"b0";
					fifowr<='1';
					KBSTATE<=KS_RESET_W4;
					WAITCNT<=waitlen-1;
				when KS_RESET_W4 =>
					fifowdat<=x"7f";
					fifowr<='1';
					KBSTATE<=KS_RESET_W5;
					WAITCNT<=waitlen-1;
				when KS_RESET_W5 =>
					fifowdat<=x"e8";
					fifowr<='1';
					KBSTATE<=KS_RESET_W6;
					WAITCNT<=waitlen-1;
				when KS_RESET_W6 =>
					fifowdat<=x"25";
					fifowr<='1';
					KBSTATE<=KS_RESET;
					WAITCNT<=waitlen-1;
				when KS_RDTBL =>
					if(TBLDAT=x"00")then
						E0en<='0';
						F0en<='0';
						KBSTATE<=KS_IDLE;
						WAITCNT<=1;
					else
						if(F0en='1')then
							f0en<='0';
							break<='1';
							rep<='0';
							lastkey<=x"00";
							case TBLDAT is
							when x"53" =>
								shiften<='0';
							when x"52" =>
								ctrlen<='0';
							when others =>
							end case;
						else
							if(lastkey=TBLDAT)then
								rep<='1';
							else
								rep<='0';
							end if;
							break<='0';
							lastkey<=TBLDAT;
							case TBLDAT is
							when x"53" =>
								shiften<='1';
							when x"52" =>
								ctrlen<='1';
							when others =>
							end case;
						end if;
						KBSTATE<=KS_WDAT1;
						WAITCNT<=1;
					end if;
				when KS_WDAT1 =>
					if(rep='0')then
						fifowdat<="101" & break & ctrlen &shiften & "00";
					else
						fifowdat<="1111" & ctrlen & shiften & "00";
					end if;
					break<='0';
					fifowr<='1';
					KBSTATE<=KS_WDAT2;
					WAITCNT<=waitlen-1;
				when KS_WDAT2 =>
					fifowdat<='0' & TBLDAT(6 downto 0);
					fifowr<='1';
					keyrecv<='1';
					E0en<='0';
					KBSTATE<=KS_IDLE;
					WAITCNT<=waitlen-1;
				when KS_MOUS0 =>
					fifowdat<=MOUS_TX0;
					fifowr<='1';
					KBSTATE<=KS_MOUS1;
					WAITCNT<=waitlen-1;
				when KS_MOUS1 =>
					fifowdat<=MOUS_TX1;
					fifowr<='1';
					KBSTATE<=KS_MOUS2;
					WAITCNT<=waitlen-1;
				when KS_MOUS2 =>
					fifowdat<=MOUS_TX2;
					fifowr<='1';
					keyrecv<='1';
					KBSTATE<=KS_IDLE;
					WAITCNT<=waitlen-1;
				when others =>
					KBSTATE<=KS_IDLE;
				end case;
			end if;
		end if;
	end process;
	
	TBLADRx<=	'1' & TBLADR(6 downto 0) when E0en='1' else
					TBLADR;
					
	tbl	:kbtbl port map(
		address		=>TBLADRx,
		clock			=>clk,
		q				=>TBLDAT
	);
	
	fifo	:datfifo generic map(32,8)port map(
		datin		=>fifowdat,
		datwr		=>fifowr,
		
		datout	=>fifordat,
		datrd		=>fiford,
		
		indat		=>fifoex,
		buffull	=>open,
		datnum	=>open,
		
		clk		=>clk,
		rstn		=>rstn
	);
	
	process(clk,rstn)
	variable lrd	:std_logic;
	variable vrd	:std_logic;
	begin
		if(rstn='0')then
			intreq<='0';
			lrd:='0';
			fiford<='0';
		elsif(clk' event and clk='1')then
			vrd:=cs and rd;
			fiford<='0';
			if(keyrecv='1')then
				intreq<='1';
			end if;
			if(vrd='0' and lrd='1')then
				if(addr='0' and bsel(0)='1')then
					fiford<='1';
				end if;
				intreq<='0';
			end if;
			lrd:=vrd;
		end if;
	end process;
	
	OBF<=fifoex;
	
	
	kbstatus<="000000" & IBF & OBF;
	
	kbintsrc<="0000000" & intb;
	
	rdat<=	x"00" & kbstatus & x"00" & fifordat when addr='0' else
				x"000000" & kbintsrc;
	doe<=rd when cs='1' else '0';
		
--	intb<=intreq and intmsk;
	intb<=fifoex and intmsk;
	int<=intb;

end rtl;
