LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MiST8877 is
generic(
	drives	:integer	:=2;
	sysfreq	:integer	:=20000
);
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(1 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	drq	:out std_logic;
	drdat	:out std_logic_vector(7 downto 0);
	dwdat	:in std_logic_vector(7 downto 0);
	dack	:in std_logic;
	int		:out std_logic;
	
	dsel	:in std_logic_vector(drives-1 downto 0);
	head	:in std_logic;
	motor	:in std_logic_vector(drives-1 downto 0);
	dready	:out std_logic;
	
	seekwait	:in std_logic;
	txwait	:in std_logic;
	
	mist_mounted	:in std_logic_vector(drives-1 downto 0);
	mist_readonly	:in std_logic_vector(drives-1 downto 0);
	mist_imgsize	:in std_logic_vector(63 downto 0);
	mist_lba			:out std_logic_vector(31 downto 0);
	mist_rd			:out std_logic_vector(drives-1 downto 0);
	mist_wr			:out std_logic_vector(drives-1 downto 0);
	mist_ack			:in std_logic;
	mist_buffaddr	:in std_logic_vector(8 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffdin	:out std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;
	
	mist_busyout	:out std_logic;
	mist_busyin		:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end MiST8877;

architecture rtl of MiST8877 is
signal	STR		:std_logic_vector(7 downto 0);
signal	CR		:std_logic_vector(7 downto 0);
signal	CRST	:std_logic_vector(7 downto 0);
signal	CRproc:std_logic_vector(7 downto 0);
signal	TR		:std_logic_vector(7 downto 0);
signal	SCR		:std_logic_vector(7 downto 0);
signal	DR		:std_logic_vector(7 downto 0);
signal	CMDTYPE	:std_logic_vector(1 downto 0);
signal	proc_bgn	:std_logic;
signal	proc_done	:std_logic;
signal	S_BUSY	:std_logic;
signal	S_BUSYm	:std_logic;
signal	S_DRQ	:std_logic;
signal	S_NRDY	:std_logic;
signal	S_WPROT	:std_logic;
signal	S_HLOAD	:std_logic;
signal	S_SEEKERR:std_logic;
signal	S_CRCERR:std_logic;
signal	S_TRK0	:std_logic;
signal	S_RTYPE	:std_logic;
signal	S_LOSTDATA:std_logic;
signal	S_INDEX	:std_logic;
signal	S_WFAULT:std_logic;
signal	S_RECNF	:std_logic;
subtype CURTRACK_TYPE is std_logic_vector(7 downto 0); 
type CURTRACK_ARRAY is array (natural range <>) of CURTRACK_TYPE; 
signal	CURTRACK	:CURTRACK_ARRAY(0 to drives-1);
signal	selunit	:integer range 0 to drives-1;
signal	indisk	:std_logic_vector(drives-1 downto 0);
constant size0	:std_logic_vector(63 downto 0)	:=(others=>'0');
signal	READY	:std_logic;
signal	lREADY:std_logic;
signal	curunit	:integer range 0 to drives-1;
signal	curlba	:std_logic_vector(31 downto 0);
signal	cursect	:std_logic_vector(7 downto 0);
signal	nxtsect	:std_logic_vector(7 downto 0);
signal	wrote		:std_logic;
signal	trackpos	:std_logic_vector(31 downto 0);
signal	ramaddr	:std_logic_vector(8 downto 0);
signal	ramrdat	:std_logic_vector(7 downto 0);
signal	ramwdat	:std_logic_vector(7 downto 0);
signal	ramwr		:std_logic;
signal	imgunit	:integer range 0 to drives-1;
signal	imgaddr	:std_logic_vector(31 downto 0);
signal	imgrd		:std_logic;
signal	imgwr		:std_logic;
signal	imgsync	:std_logic;
signal	imgdone	:std_logic;
signal	imgrdat	:std_logic_vector(7 downto 0);
signal	imgwdat	:std_logic_vector(7 downto 0);
signal	secthead	:std_logic_vector(31 downto 0);
signal	numsects	:std_logic_vector(7 downto 0);
signal	sectcount:std_logic_vector(7 downto 0);
signal	sectsize	:std_logic_vector(15 downto 0);
signal	datcount	:std_logic_vector(15 downto 0);
signal	sectdeleted	:std_logic;
signal	sectstatus	:std_logic_vector(7 downto 0);
signal	sectinc	:std_logic;
signal	DRwr		:std_logic;
signal	DRwdat	:std_logic_vector(7 downto 0);
signal	intsel	:std_logic_vector(3 downto 0);
signal	round	:std_logic;
constant	seekwlen	:integer	:=3*sysfreq;
constant txwlenh	:integer	:=sysfreq/500;
constant txwlend	:integer	:=sysfreq/250;
signal	seekwcount	:integer range 0 to seekwlen-1;
signal	txwcount		:integer range 0 to txwlend-1;

signal	crcwdat	:std_logic_vector(7 downto 0);
signal	crcwr		:std_logic;
signal	crcclr	:std_logic;
signal	crcbusy	:std_logic;
signal	crcdat	:std_logic_vector(15 downto 0);
signal	stepdir	:std_logic;
signal	tracklen	:integer range 0 to 12500;
signal	tlencount:integer range 0 to 12500;

signal	datwr		:std_logic;
signal	datrd		:std_logic;
signal	datwdat	:std_logic_vector(7 downto 0);
signal	datn		:std_logic_vector(7 downto 0);
signal	datlen	:std_logic_Vector(15 downto 0);

type ramstate_t is(
	rs_idle,
	rs_readchk,
	rs_writechk,
	rs_read,
	rs_read2,
	rs_write,
	rs_write2,
	rs_done
);
signal	ramstate,rampend	:ramstate_t;
type state_t is(
	st_idle,
	st_readtype,
	st_readtbl0,
	st_readtbl1,
	st_readtbl2,
	st_readtbl3,
	st_readwprot,
	st_readsects,
	st_readsize0,
	st_readsize1,
	st_searchsect,
	st_readhead,
	st_readdeleted,
	st_readstatus,
	st_read,
	st_write,
	st_readwait,
	st_writewait,
	st_crcI0,
	st_crcI1,
	st_crcI2,
	st_crcI3,
	st_readC,
	st_writeC,
	st_crcC,
	st_readH,
	st_writeH,
	st_crcH,
	st_readR,
	st_writeR,
	st_crcR,
	st_readN,
	st_writeN,
	st_crcN,
	st_writecrcI0,
	st_waitcrcI0,
	st_writecrcI1,
	st_sync,
	st_dati0,
	st_dati0x,
	st_dati0w,
	st_dati1,
	st_dati1w,
	st_dati2,
	st_dati2w,
	st_dati3,
	st_dati3w,
	st_datic,
	st_daticw,
	st_datih,
	st_datihw,
	st_datir,
	st_datirw,
	st_datin,
	st_datinw,
	st_daticrc,
	st_daticrcw,
	st_datdi0,
	st_datdi0x,
	st_datdi0w,
	st_datdi1,
	st_datdi1w,
	st_datdi2,
	st_datdi2w,
	st_datdi3,
	st_datdi3w,
	st_datdat,
	st_datdatw,
	st_datdcrc,
	st_datdcrcw,
	st_seek
);
signal	state	:state_t;

constant CMD_RECARIB	:std_logic_Vector(3 downto 0)	:="0000";
constant CMD_SEEK		:std_logic_Vector(3 downto 0)	:="0001";
constant CMD_STEP		:std_logic_Vector(3 downto 0)	:="0010";
constant CMD_STEPIN	:std_logic_Vector(3 downto 0)	:="0100";
constant CMD_STEPINR	:std_logic_Vector(3 downto 0)	:="0101";
constant CMD_STEPOUT	:std_logic_Vector(3 downto 0)	:="0110";
constant CMD_STEPOUTR:std_logic_Vector(3 downto 0)	:="0111";
constant CMD_RDDATA	:std_logic_Vector(3 downto 0)	:="1000";
constant CMD_RDDATAM	:std_logic_Vector(3 downto 0)	:="1001";
constant CMD_WRDATA	:std_logic_Vector(3 downto 0)	:="1010";
constant CMD_WRDATAM	:std_logic_Vector(3 downto 0)	:="1011";
constant CMD_RDADDR	:std_logic_Vector(3 downto 0)	:="1100";
constant CMD_RDTRK	:std_logic_Vector(3 downto 0)	:="1110";
constant CMD_WRTRK	:std_logic_Vector(3 downto 0)	:="1111";
constant CMD_FINT		:std_logic_Vector(3 downto 0)	:="1101";

--component dpssram
--generic(
--	awidth	:integer	:=8;
--	dwidth	:integer	:=8
--);
--port(
--	addr1	:in std_logic_vector(awidth-1 downto 0);
--	wdat1	:in std_logic_vector(dwidth-1 downto 0);
--	wr1	:in std_logic;
--	rdat1	:out std_logic_vector(dwidth-1 downto 0);
--	
--	addr2	:in std_logic_vector(awidth-1 downto 0);
--	wdat2	:in std_logic_vector(dwidth-1 downto 0);
--	wr2	:in std_logic;
--	rdat2	:out std_logic_vector(dwidth-1 downto 0);
--	
--	clk	:in std_logic
--);
--end component;

component mistram
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component CRCGENN
	generic(
		DATWIDTH :integer	:=10;
		WIDTH	:integer	:=3
	);
	port(
		POLY	:in std_logic_vector(WIDTH downto 0);
		DATA	:in std_logic_vector(DATWIDTH-1 downto 0);
		DIR		:in std_logic;
		WRITE	:in std_logic;
		BITIN	:in std_logic;
		BITWR	:in std_logic;
		CLR		:in std_logic;
		CLRDAT	:in std_logic_vector(WIDTH-1 downto 0);
		CRC		:out std_logic_vector(WIDTH-1 downto 0);
		BUSY	:out std_logic;
		DONE	:out std_logic;
		CRCZERO	:out std_logic;

		clk		:in std_logic;
		rstn	:in std_logic
	);
end component;


begin

	rdat<=	STR	when addr="00" else
			TR	when addr="01" else
			SCR	when addr="10" else
			DR	when addr="11" else
			(others=>'0');
	doe<='1' when cs='1' and rd='1' else '0';
	
	process(clk,rstn)begin
		if(rstn='0')then
			CR<=(others=>'0');
			TR<=(others=>'0');
			SCR<=(others=>'0');
			DR<=(others=>'0');
			INT<='0';
			intsel<=(others=>'0');
			stepdir<='0';
		elsif(clk' event and clk='1')then
			proc_bgn<='0';
			if(cs='1' and wr='1')then
				case addr is
				when "00" =>
					CR<=wdat;
					case wdat(7 downto 4) is
					when CMD_RECARIB =>
						TR<=(others=>'0');
						stepdir<='1';
						proc_bgn<='1';
					when CMD_SEEK =>
						if(TR<DR)then
							stepdir<='0';
						elsif(TR>DR)then
							stepdir<='1';
						end if;
						TR<=DR;
						proc_bgn<='1';
					when CMD_STEP =>
						proc_bgn<='1';
					when CMD_STEPIN =>
						stepdir<='0';
						proc_bgn<='1';
					when CMD_STEPOUT =>
						stepdir<='1';
						proc_bgn<='1';
					when "0011" =>
						if(stepdir='0')then
							TR<=TR+1;
						else
							TR<=TR-1;
						end if;
					when CMD_STEPINR =>
						stepdir<='0';
						TR<=TR+1;
						proc_bgn<='1';
					when CMD_STEPOUTR =>
						stepdir<='1';
						TR<=TR-1;
						proc_bgn<='1';
					when CMD_FINT =>
						intsel<=wdat(3 downto 0);
					when others =>
						if(READY='1')then
							proc_bgn<='1';
						end if;
					end case;
				when "01" =>
					TR<=wdat;
				when "10" =>
					SCR<=wdat;
				when "11" =>
					DR<=wdat;
				end case;
			end if;
			if(sectinc='1')then
				SCR<=SCR+1;
			end if;
			if(DRwr='1')then
				DR<=DRwdat;
			end if;
			if(proc_done='1')then
				INT<='1';
			elsif(cs='1' and rd='1')then
				INT<='0';
			end if;
			if(intsel(0)='1' and lREADY='0' and READY='1')then
				INT<='1';
			end if;
			if(intsel(1)='1' and lREADY='1' and READY='0')then
				INT<='1';
			end if;
			if(intsel(2)='1' and S_INDEX='1')then
				INT<='1';
			end if;
			if(intsel(3)='1')then
				INT<='1';
			end if;
			lREADY<=READY;
		end if;
	end process;
			
	CMDTYPE<=	"00" when CR(7)='0' else
				"01" when CR(7 downto 6)="10" else
				"11" when CR(7 downto 4)=CMD_FINT else
				"10";

	CRST<=	CR			when CR(7 downto 4)=CMD_FINT and S_BUSY='0' else
				CRproc	when CR(7 downto 4)=CMD_FINT else
				CR;
	
	S_BUSYm<=	'0' when CR(7 downto 4)=CMD_FINT else S_BUSY;
		
	STR<=	S_NRDY & '0' & S_RTYPE & S_RECNF & S_CRCERR & S_LOSTDATA & S_DRQ & S_BUSYm when CRST(7 downto 5)=CMD_RDDATA(3 downto 1) else			--READDATA
			S_NRDY & S_WPROT & S_WFAULT & S_RECNF & S_CRCERR & S_LOSTDATA & S_DRQ & S_BUSYm when CRST(7 downto 5)=CMD_WRDATA(3 downto 1) else	--WRITEDATA
			S_NRDY & "00" & S_RECNF & S_CRCERR & S_LOSTDATA & S_DRQ & S_BUSYm when CRST(7 downto 4)=CMD_RDADDR else										--READADDRESS
			S_NRDY & S_WPROT & S_HLOAD & "00" & S_TRK0 & S_INDEX & S_BUSYm when CRST(7 downto 4)=CMD_FINT else												--INTERRUPT&INACTIVE
			S_NRDY & "0000" & S_LOSTDATA & S_DRQ & S_BUSYm when CRST(7 downto 4)=CMD_RDTRK else																	--READTRACK
			S_NRDY & S_WPROT & S_WFAULT & "00" & S_LOSTDATA & S_DRQ & S_BUSYm when CRST(7 downto 4)=CMD_WRTRK else										--WRITETRACK
			S_NRDY & S_WPROT & S_HLOAD & S_SEEKERR & S_CRCERR & S_TRK0 & S_INDEX & S_BUSYm;																		--TYPE I
	
	process(dsel)begin
		selunit<=0;
		for i in drives-1 downto 0 loop
			if(dsel(i)='1')then
				selunit<=i;
			end if;
		end loop;
	end process;
	
	nxtsect<=	cursect+1 when (cursect+1)<numsects else
					(others=>'0');
					
	process(clk,rstn)
	variable lwr	:std_logic;
	variable lrd	:std_logic;
	begin
		if(rstn='0')then
			lwr:='0';
			lrd:='0';
			datwr<='0';
			datrd<='0';
			datwdat<=(others=>'0');
		elsif(clk' event and clk='1')then
			datwr<='0';
			datrd<='0';
			if(cs='1' and wr='1' and addr="11")then
				if(lwr='0')then
					datwdat<=wdat;
					datwr<='1';
				end if;
				lwr:='1';
			else
				lwr:='0';
			end if;
			if(cs='1' and rd='1' and addr="11")then
				lrd:='0';
			elsif(lrd='1')then
				datrd<='1';
				lrd:='0';
			end if;
			if(dack='1')then
				datwdat<=dwdat;
				datwr<='1';
				datrd<='1';
			end if;
		end if;
	end process;
	
	datlen<=	x"0080" when datn=x"00" else
				x"0100" when datn=x"01" else
				x"0200" when datn=x"02" else
				x"0400" when datn=x"03" else
				x"0800" when datn=x"04" else
				x"1000" when datn=x"05" else
				x"2000" when datn=x"06" else
				x"4000" when datn=x"07" else
				x"8000" when datn=x"08" else
				(others=>'0');
	
	process(clk,rstn)
	variable tmpaddr	:std_logic_vector(31 downto 0);
	begin
		if(rstn='0')then
			S_DRQ<='0';
			S_WPROT<='0';
			S_HLOAD<='0';
			S_SEEKERR<='0';
			S_CRCERR<='0';
			S_RTYPE<='0';
			S_LOSTDATA<='0';
			S_INDEX<='0';
			S_WFAULT<='0';
			S_RECNF<='0';
			tmpaddr:=(others=>'0');
			imgwdat<=(others=>'0');
			drq<='0';
			DRwdat<=(others=>'0');
			datcount<=(others=>'0');
			imgunit<=0;
			for i in 0 to drives-1 loop
				CURTRACK(i)<=(others=>'0');
			end loop;
			round<='0';
			imgaddr<=(others=>'0');
			cursect<=(others=>'0');
			crcwdat<=(others=>'0');
			crcwr<='0';
			crcclr<='0';
			CRproc<=(others=>'0');
			tracklen<=0;
			tlencount<=0;
			secthead<=(others=>'0');
			datn<=(others=>'0');
		elsif(clk' event and clk='1')then
			proc_done<='0';
			imgrd<='0';
			imgwr<='0';
			imgsync<='0';
			sectinc<='0';
			DRwr<='0';
			S_INDEX<='0';
			crcwr<='0';
			crcclr<='0';
			if(CR(7 downto 4)=CMD_WRTRK and tlencount>tracklen)then
				imgsync<='1';
				drq<='0';
				S_DRQ<='0';
				state<=st_sync;
			elsif(CR=CMD_FINT and state/=st_idle and state/=st_sync)then
				imgsync<='1';
				drq<='0';
				S_DRQ<='0';
				state<=st_sync;
			else
				case state is
				when st_idle =>
					if(proc_bgn='1')then
						CRproc<=CR;
						case CR(7 downto 4) is
						when CMD_RECARIB =>
							CURTRACK(selunit)<=(others=>'0');
							proc_done<='1';
							S_HLOAD<=CR(3);
							S_CRCERR<='0';
							S_SEEKERR<='0';
						when CMD_SEEK =>
							if(DR>x"55")then
								S_SEEKERR<='1';
							else
								S_SEEKERR<='0';
								CURTRACK(selunit)<=DR;
							end if;
							proc_done<='1';
							S_HLOAD<=CR(3);
							S_CRCERR<='0';
						when CMD_STEP | "0011"  =>
							if(stepdir='0')then
								if(CURTRACK(selunit)>x"54")then
									S_SEEKERR<='1';
								else
									S_SEEKERR<='0';
									CURTRACK(selunit)<=CURTRACK(selunit)+1;
								end if;
							else
								if(CURTRACK(selunit)=x"00")then
									S_SEEKERR<='1';
								else
									S_SEEKERR<='0';
									CURTRACK(selunit)<=CURTRACK(selunit)-1;
								end if;
							end if;
							proc_done<='1';
							S_HLOAD<=CR(3);
							S_CRCERR<='0';
						when CMD_STEPIN | CMD_STEPINR =>
							if(CURTRACK(selunit)>x"54")then
								S_SEEKERR<='1';
							else
								S_SEEKERR<='0';
								CURTRACK(selunit)<=CURTRACK(selunit)+1;
							end if;
							proc_done<='1';
							S_HLOAD<=CR(3);
							S_CRCERR<='0';
						when CMD_STEPOUT | CMD_STEPOUTR =>
							if(CURTRACK(selunit)=x"00")then
								S_SEEKERR<='1';
							else
								S_SEEKERR<='0';
								CURTRACK(selunit)<=CURTRACK(selunit)-1;
							end if;
							proc_done<='1';
							S_HLOAD<=CR(3);
							S_CRCERR<='0';
						when CMD_RDDATA | CMD_RDDATAM =>
							imgunit<=selunit;
							imgaddr<=x"00000020"+(CURTRACK(selunit) & head & "00");
							imgrd<='1';
							S_RTYPE<='0';
							S_CRCERR<='0';
							state<=st_readtbl0;
						when CMD_WRDATA | CMD_WRDATAM =>
							imgunit<=selunit;
							imgaddr<=x"00000020"+(CURTRACK(selunit) & head & "00");
							imgrd<='1';
							S_CRCERR<='0';
							state<=st_readtbl0;
						when CMD_RDADDR =>	--read address
							imgunit<=selunit;
							imgaddr<=x"00000020"+(CURTRACK(selunit) & head & "00");
							imgrd<='1';
							S_CRCERR<='0';
							state<=st_readtbl0;
						when CMD_WRTRK =>
							imgunit<=selunit;
							imgaddr<=x"0000001b";
							imgrd<='1';
							state<=st_readtype;
							S_CRCERR<='0';
						when others =>
							proc_done<='1';
						end case;
					end if;
				when st_readtype =>
					if(imgdone='1')then
						case imgrdat is
						when x"00" =>
							tracklen<=6250;
						when x"10" =>
							tracklen<=6250;
						when x"20" =>
							tracklen<=10416;
						when x"30" =>
							tracklen<=12500;
						when others =>
							tracklen<=6250;
						end case;
						imgaddr<=x"00000020"+(CURTRACK(selunit) & head & "00");
						imgrd<='1';
						state<=st_readtbl0;
					end if;
				when st_readtbl0 =>
					if(imgdone='1')then
						tmpaddr(7 downto 0):=imgrdat;
						imgaddr<=imgaddr+1;
						imgrd<='1';
						state<=st_readtbl1;
					end if;
				when st_readtbl1 =>
					if(imgdone='1')then
						tmpaddr(15 downto 8):=imgrdat;
						imgaddr<=imgaddr+1;
						imgrd<='1';
						state<=st_readtbl2;
					end if;
				when st_readtbl2 =>
					if(imgdone='1')then
						tmpaddr(23 downto 16):=imgrdat;
						imgaddr<=imgaddr+1;
						imgrd<='1';
						state<=st_readtbl3;
					end if;
				when st_readtbl3 =>
					if(imgdone='1')then
						tmpaddr(31 downto 24):=imgrdat;
						imgaddr<=x"0000001a";
						imgrd<='1';
						state<=st_readwprot;
					end if;
				when st_readwprot =>
					if(imgdone='1')then
						if(imgrdat=x"10")then
							S_WPROT<='1';
						else
							S_WPROT<='0';
						end if;
						trackpos<=tmpaddr;
						secthead<=tmpaddr;
						imgaddr<=tmpaddr+4;
						imgrd<='1';
						state<=st_readsects;
					end if;
				when st_readsects =>
					if(imgdone='1')then
						numsects<=imgrdat;
						sectcount<=x"00";
						imgaddr<=secthead+x"e";
						imgrd<='1';
						state<=st_readsize0;
						round<='0';
					end if;
				when st_readsize0 =>
					if(imgdone='1')then
						sectsize(7 downto 0)<=imgrdat;
						imgaddr<=imgaddr+1;
						imgrd<='1';
						state<=st_readsize1;
					end if;
				when st_readsize1 =>
					if(imgdone='1')then
						sectsize(15 downto 8)<=imgrdat;
						imgaddr<=secthead+x"2";
						imgrd<='1';
						case CR(7 downto 4) is
						when CMD_WRTRK =>
							if(S_WPROT='1')then
								proc_done<='1';
								state<=st_idle;
							else
								drq<='1';
								S_DRQ<='1';
								tlencount<=0;
								state<=st_dati0;
							end if;
						when CMD_WRDATA | CMD_WRDATAM =>
							if(S_WPROT='1')then
								proc_done<='1';
								state<=st_idle;
							else
								state<=st_searchsect;
							end if;
						when others =>
							state<=st_searchsect;
						end case;
					end if;
				when st_searchsect =>
					if(imgdone='1')then
						if(imgrdat=SCR and (CR(7 downto 5)="100" or CR(7 downto 5)="101"))then
							imgaddr<=secthead+x"1";
							imgrd<='1';
							state<=st_readhead;
							cursect<=sectcount;
	--					elsif(sectcount=nxtsect and CR(7 downto 4)=CMD_RDADDR)then
						elsif(CR(7 downto 4)=CMD_RDADDR)then
							crcclr<='1';
							crcwdat<=x"a1";
							crcwr<='1';
							state<=st_CRCI0;
							cursect<=nxtsect;
						else
							if((sectcount+1)<numsects)then
								sectcount<=sectcount+1;
								imgaddr<=secthead+sectsize+x"1e";
								secthead<=secthead+sectsize+x"10";
								imgrd<='1';
								state<=st_readsize0;
							elsif(round='0')then
								round<='1';
								imgaddr<=trackpos+x"0e";
								secthead<=trackpos;
								imgrd<='1';
								state<=st_readsize0;
							else
								S_RECNF<='1';
								S_INDEX<='1';
								proc_done<='1';
								state<=st_idle;
							end if;
						end if;
					end if;
				when st_readhead =>
					if(imgdone='1')then
						if(CR(1)='0' or (CR(3)=imgrdat(0) and imgrdat(7 downto 1)="0000000"))then
							imgaddr<=secthead+x"7";
							case CR(7 downto 5) is
							when "100" =>
								imgrd<='1';
							when "101" =>
								if(CR(0)='1')then
									imgwdat<=x"10";
								else
									imgwdat<=x"00";
								end if;
								imgwr<='1';
							when others =>
								imgrd<='1';
							end case;
							state<=st_readdeleted;
						else
							if(sectcount<numsects)then
								sectcount<=sectcount+1;
								imgaddr<=secthead+sectsize+x"1e";
								secthead<=secthead+sectsize+x"10";
								imgrd<='1';
								state<=st_readsize0;
							elsif(round='0')then
								round<='1';
								imgaddr<=trackpos+x"e";
								secthead<=trackpos;
								imgrd<='1';
								state<=st_readsize0;
							else
								S_RECNF<='1';
								S_INDEX<='1';
								proc_done<='1';
								state<=st_idle;
							end if;
						end if;
					end if;
				when st_readdeleted =>
					if(imgdone='1')then
						if(imgrdat=x"00")then
							sectdeleted<='0';
						else
							sectdeleted<='1';
							S_RTYPE<='1';
						end if;
						imgaddr<=secthead+x"8";
						case CR(7 downto 5) is
						when "100" =>
							imgrd<='1';
						when "101" =>
							if(CR(0)='1')then
								imgwdat<=x"10";
							else
								imgwdat<=x"00";
							end if;
							imgwr<='1';
						when others =>
							imgrd<='1';
						end case;
						state<=st_readstatus;
					end if;
				when st_readstatus =>
					if(imgdone='1')then
						sectstatus<=imgrdat;
						datcount<=x"0001";
						imgaddr<=secthead+x"10";
						case CR(7 downto 5) is
						when "100" =>
							imgrd<='1';
							state<=st_read;
						when "101" =>
							drq<='1';
							S_DRQ<='1';
							state<=st_write;
						when others =>
							state<=st_idle;
						end case;
					end if;
				when st_read =>
					if(imgdone='1')then
						DRwdat<=imgrdat;
						DRwr<='1';
						drdat<=imgrdat;
						drq<='1';
						S_DRQ<='1';
						state<=st_readwait;
					end if;
				when st_readwait =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						if(datcount=sectsize)then
							if(CR(4)='1')then
								sectinc<='1';
								imgaddr<=secthead+sectsize+x"10";
								imgrd<='1';
								state<=st_searchsect;
							else
								proc_done<='1';
								state<=st_idle;
							end if;
						else
							datcount<=datcount+1;
							imgaddr<=imgaddr+1;
							imgrd<='1';
							state<=st_read;
						end if;
					end if;
				when st_write =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						imgwdat<=datwdat;
	--					DRwdat<=dwdat;
	--					DRwr<='1';
						imgwr<='1';
						state<=st_writewait;
					end if;
				when st_writewait =>
					if(imgdone='1')then
						if(datcount=sectsize)then
							if(CR(4)='1')then
								sectinc<='1';
								imgaddr<=secthead+sectsize+x"10";
								imgrd<='1';
								state<=st_searchsect;
							else
								imgsync<='1';
								state<=st_sync;
							end if;
						else
							datcount<=datcount+1;
							imgaddr<=imgaddr+1;
							drq<='1';
							S_DRQ<='1';
							state<=st_write;
						end if;
					end if;
				when st_crcI0 =>
					if(crcbusy='0')then
						crcwdat<=x"a1";
						crcwr<='1';
						state<=st_crcI1;
					end if;
				when st_crcI1 =>
					if(crcbusy='0')then
						crcwdat<=x"a1";
						crcwr<='1';
						state<=st_crcI2;
					end if;
				when st_crcI2 =>
					if(crcbusy='0')then
						crcwdat<=x"fe";
						crcwr<='1';
						state<=st_crcI3;
					end if;
				when st_crcI3 =>
					if(crcbusy='0')then
						imgaddr<=secthead+x"0";
						imgrd<='1';
						state<=st_readC;
					end if;
				when st_readC =>
					if(imgdone='1')then
						DRwdat<=imgrdat;
						DRwr<='1';
						drdat<=imgrdat;
						drq<='1';
						crcwdat<=imgrdat;
						crcwr<='1';
						S_DRQ<='1';
						state<=st_writeC;
					end if;
				when st_writeC =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						state<=st_crcC;
					end if;
				when st_crcC =>
					if(crcbusy='0')then
						imgaddr<=secthead+x"1";
						imgrd<='1';
						state<=st_readH;
					end if;
				when st_readH =>
					if(imgdone='1')then
						DRwdat<=imgrdat;
						DRwr<='1';
						drdat<=imgrdat;
						drq<='1';
						crcwdat<=imgrdat;
						crcwr<='1';
						S_DRQ<='1';
						state<=st_writeH;
					end if;
				when st_writeH =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						state<=st_crcH;
					end if;
				when st_crcH =>
					if(crcbusy='0')then
						imgaddr<=secthead+x"2";
						imgrd<='1';
						state<=st_readR;
					end if;
				when st_readR =>
					if(imgdone='1')then
						DRwdat<=imgrdat;
						DRwr<='1';
						drdat<=imgrdat;
						drq<='1';
						crcwdat<=imgrdat;
						crcwr<='1';
						S_DRQ<='1';
						state<=st_writeR;
					end if;
				when st_writeR =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						state<=st_crcR;
					end if;
				when st_crcR =>
					if(crcbusy='0')then
						imgaddr<=secthead+x"3";
						imgrd<='1';
						state<=st_readN;
					end if;
				when st_readN =>
					if(imgdone='1')then
						DRwdat<=imgrdat;
						DRwr<='1';
						drdat<=imgrdat;
						drq<='1';
						crcwdat<=imgrdat;
						crcwr<='1';
						S_DRQ<='1';
						state<=st_writeN;
					end if;
				when st_writeN =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						state<=st_crcN;
					end if;
				when st_crcN =>
					if(crcbusy='0')then
						DRwdat<=crcdat(15 downto 8);
						DRwr<='1';
						drdat<=crcdat(15 downto 8);
						drq<='1';
						S_DRQ<='1';
						state<=st_writecrcI0;
					end if;
				when st_writecrcI0 =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						state<=st_waitcrcI0;
					end if;
				when st_waitcrcI0 =>
					DRwdat<=crcdat(7 downto 0);
					DRwr<='1';
					drdat<=crcdat(7 downto 0);
					drq<='1';
					S_DRQ<='1';
					state<=st_writecrcI1;
				when st_writecrcI1 =>
					if(datrd='1')then
						drq<='0';
						S_DRQ<='0';
						proc_done<='1';
						state<=st_idle;
					end if;
				when st_seek =>
				when st_sync =>
					if(imgdone='1')then
						proc_done<='1';
						state<=st_idle;
					end if;
				when st_dati0 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_dati0w;
						else
							state<=st_dati0x;
						end if;
					end if;
				when st_dati0x =>
					drq<='1';
					S_DRQ<='1';
					state<=st_dati0;
				when st_dati0w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_dati1;
				when st_dati1 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_dati1w;
						else
							state<=st_dati0x;
						end if;
					end if;
				when st_dati1w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_dati2;
				when st_dati2 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_dati2w;
						else
							state<=st_dati0x;
						end if;
					end if;
				when st_dati2w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_dati3;
				when st_dati3 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"fe")then
							state<=st_dati3w;
						else
							state<=st_dati0x;
						end if;
					end if;
				when st_dati3w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_datic;
				when st_datic =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						imgaddr<=secthead+x"00";
						imgwdat<=datwdat;
						imgwr<='1';
						state<=st_daticw;
					end if;
				when st_daticw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						state<=st_datih;
					end if;
				when st_datih =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						imgaddr<=secthead+x"01";
						imgwdat<=datwdat;
						imgwr<='1';
						state<=st_datihw;
					end if;
				when st_datihw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						state<=st_datir;
					end if;
				when st_datir =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						imgaddr<=secthead+x"02";
						imgwdat<=datwdat;
						imgwr<='1';
						datn<=datwdat;
						state<=st_datirw;
					end if;
				when st_datirw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						state<=st_datin;
					end if;
				when st_datin =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						imgaddr<=secthead+x"03";
						imgwdat<=datwdat;
						imgwr<='1';
						state<=st_datinw;
					end if;
				when st_datinw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						state<=st_daticrc;
					end if;
				when st_daticrc =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+2;
						state<=st_daticrcw;
					end if;
				when st_daticrcw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						state<=st_datdi0;
					end if;
				when st_datdi0 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_datdi0w;
						else
							state<=st_datdi0x;
						end if;
					end if;
				when st_datdi0x =>
					drq<='1';
					S_DRQ<='1';
					state<=st_datdi0;
				when st_datdi0w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_datdi1;
				when st_datdi1 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_datdi1w;
						else
							state<=st_datdi0x;
						end if;
					end if;
				when st_datdi1w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_datdi2;
				when st_datdi2 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"f5")then
							state<=st_datdi2w;
						else
							state<=st_datdi0x;
						end if;
					end if;
				when st_datdi2w =>
					drq<='1';
					S_DRQ<='1';
					state<=st_datdi3;
				when st_datdi3 =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						if(datwdat=x"fb")then
							imgaddr<=secthead+x"07";
							imgwdat<=x"00";
							imgwr<='1';
							state<=st_datdi3w;
						elsif(datwdat=x"f8")then
							imgaddr<=secthead+x"07";
							imgwdat<=x"10";
							imgwr<='1';
							state<=st_datdi3w;
						else
							state<=st_datdi0x;
						end if;
					end if;
				when st_datdi3w =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						imgaddr<=secthead+x"10";
						datcount<=x"0001";
						state<=st_datdat;
					end if;
				when st_datdat =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+1;
						imgwdat<=datwdat;
						imgwr<='1';
						state<=st_datdatw;
					end if;
				when st_datdatw =>
					if(imgdone='1')then
						drq<='1';
						S_DRQ<='1';
						imgaddr<=imgaddr+1;
						if(datcount=datlen)then
							state<=st_datdcrc;
						else
							datcount<=datcount+1;
							state<=st_datdat;
						end if;
					end if;
				when st_datdcrc =>
					if(datwr='1')then
						drq<='0';
						S_DRQ<='0';
						tlencount<=tlencount+2;
						state<=st_datdcrcw;
					end if;
				when st_datdcrcw =>
					drq<='1';
					S_DRQ<='1';
					state<=st_dati0;
				when others =>		
									
				end case;
			end if;
		end if;
	end process;

	S_TRK0<='1' when CURTRACK(selunit)=x"00" else '0';
	READY<='1' when indisk(selunit)='1' and motor(selunit)='1' else '0';
	S_NRDY<=not READY;
	S_BUSY<='0' when state=st_IDLE else '1';
	
	process(clk)begin
		if(clk' event and clk='1')then
			for i in 0 to drives-1 loop
				if(mist_mounted(i)='1')then
					if(mist_imgsize=size0)then
						indisk(i)<='0';
					else
						indisk(i)<='1';
					end if;
				end if;
			end loop;
		end if;
	end process;
	
	imgram	:mistram port map(
		address_a	=>ramaddr,
		address_b	=>mist_buffaddr,
		clock			=>clk,
		data_a		=>ramwdat,
		data_b		=>mist_buffdout,
		wren_a		=>ramwr,
		wren_b		=>mist_buffwr,
		q_a			=>ramrdat,
		q_b			=>mist_buffdin
	);

--	imgram	:dpssram generic map(9,8) port map(
--		addr1	=>ramaddr,
--		wdat1	=>ramwdat,
--		wr1	=>ramwr,
--		rdat1	=>ramrdat,
--		
--		addr2	=>mist_buffaddr,
--		wdat2	=>mist_buffdout,
--		wr2	=>mist_buffwr,
--		rdat2	=>mist_buffdin,
--		
--		clk	=>clk
--	);

	imgrdat<=ramrdat;
	ramaddr<=imgaddr(8 downto 0);
	ramwdat<=imgwdat;
	process(clk,rstn)begin
		if(rstn='0')then
			wrote<='0';
			curlba<=(others=>'1');
			curunit<=0;
			ramstate<=rs_idle;
			mist_lba<=(others=>'0');
			imgdone<='0';
			mist_busyout<='0';
			mist_rd<=(others=>'0');
			mist_wr<=(others=>'0');
			rampend<=rs_idle;
		elsif(clk' event and clk='1')then
			imgdone<='0';
			ramwr<='0';
			if(indisk(curunit)='0')then
				curlba<=(others=>'1');
			end if;
			case ramstate is
			when rs_idle =>
				if(imgrd='1')then
					if(imgaddr(31 downto 9)/=curlba(22 downto 0) or curunit/=imgunit)then
						if(wrote='1')then
							mist_lba<=curlba;
							ramstate<=rs_writechk;
							rampend<=rs_read;
						else
							mist_lba<=size0(31 downto 23) & imgaddr(31 downto 9);
							curunit<=imgunit;
							curlba<=size0(31 downto 23) & imgaddr(31 downto 9);
							ramstate<=rs_readchk;
							rampend<=rs_read;
						end if;
					else
						ramstate<=rs_done;
					end if;
				elsif(imgwr='1')then
					if(imgaddr(31 downto 9)/=curlba(22 downto 0) or curunit/=imgunit)then
						if(wrote='1')then
							mist_lba<=curlba;
							ramstate<=rs_writechk;
							rampend<=rs_write;
						else
							mist_lba<=size0(31 downto 23) & imgaddr(31 downto 9);
							curunit<=imgunit;
							curlba<=size0(31 downto 23) & imgaddr(31 downto 9);
							ramstate<=rs_readchk;
							rampend<=rs_write;
						end if;
					else
						wrote<='1';
						ramwr<='1';
						ramstate<=rs_done;
					end if;
				elsif(imgsync='1')then
					if(wrote='1')then
						mist_lba<=curlba;
						ramstate<=rs_writechk;
						rampend<=rs_done;
					else
						ramstate<=rs_done;
					end if;
				end if;
			when rs_readchk =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_rd(imgunit)<='1';
					ramstate<=rs_read;
				end if;
			when rs_writechk =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_wr(curunit)<='1';
					ramstate<=rs_write;
				end if;
			when rs_read =>
				if(mist_ack='1')then
					mist_rd(imgunit)<='0';
					ramstate<=rs_read2;
				end if;
			when rs_read2 =>
				if(mist_ack='0')then
					if(rampend=rs_write)then
						rampend<=rs_idle;
						ramwr<='1';
						wrote<='1';
						ramstate<=rs_done;
					else
						rampend<=rs_idle;
						ramstate<=rs_done;
					end if;
				end if;
			when rs_write =>
				if(mist_ack='1')then
					mist_wr(curunit)<='0';
					ramstate<=rs_write2;
				end if;
			when rs_write2 =>
				if(mist_ack='0')then
					if(rampend=rs_done)then
						wrote<='0';
						ramstate<=rs_done;
					else
						mist_lba<=size0(31 downto 23) & imgaddr(31 downto 9);
						mist_rd(imgunit)<='1';
						curunit<=imgunit;
						curlba<=size0(31 downto 23) & imgaddr(31 downto 9);
						ramstate<=rs_read;
					end if;
				end if;
			when rs_done =>
				mist_busyout<='0';
				imgdone<='1';
				ramstate<=rs_idle;
			when others =>
				ramstate<=rs_idle;
			end case;
		end if;
	end process;
					
	dready<=READY;

	CRCG	:CRCGENN generic map(8,16) port map(
		POLY	=>"10000100000010001",
		DATA	=>crcwdat,
		DIR		=>'0',
		WRITE	=>crcwr,
		BITIN	=>'0',
		BITWR	=>'0',
		CLR		=>crcclr,
		CLRDAT	=>x"ffff",
		CRC		=>crcdat,
		BUSY	=>crcbusy,
		DONE	=>open,
		CRCZERO	=>open,

		clk		=>clk,
		rstn	=>rstn
	);
	
	
end rtl;
