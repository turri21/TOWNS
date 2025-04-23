LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use	work.MEM_ADDR_pkg.all;

entity videocont	is
generic(
	ADDRWIDTH:integer	:=25;
	COLSIZE	:integer	:=9
);
port(
	
	HDS0	:in std_logic_vector(10 downto 0);
	HDE0	:in std_logic_vector(10 downto 0);
	ZH0	:in std_logic_vector(3 downto 0);
	ZV0	:in std_logic_vector(3 downto 0);
	FA0	:in std_logic_vector(15 downto 0);
	FO0	:in std_logic_vector(15 downto 0);
	LO0	:in std_logic_vector(15 downto 0);
	CL0	:in std_logic_vector(1 downto 0);
	V0EN	:in std_logic;
	PAGESEL0:in  std_logic;

	HDS1	:in std_logic_vector(10 downto 0);
	HDE1	:in std_logic_vector(10 downto 0);
	ZH1	:in std_logic_vector(3 downto 0);
	ZV1	:in std_logic_vector(3 downto 0);
	FA1	:in std_logic_vector(15 downto 0);
	FO1	:in std_logic_vector(15 downto 0);
	LO1	:in std_logic_vector(15 downto 0);
	CL1	:in std_logic_vector(1 downto 0);
	PMODE	:in std_logic;
	V1EN	:in std_logic;
	PAGESEL1:in  std_logic;
	
	HCOMP	:in std_logic;
	HHCOMP:in std_logic;
	VCOMP	:in std_logic;
	
	ram_addr	:out std_logic_vector(ADDRWIDTH-1 downto 0);
	ram_blen	:out std_logic_vector(COLSIZE-1 downto 0);
	ram_rd	:out std_logic;
	ram_rval	:in std_logic;
	ram_num	:in std_logic_vector(COLSIZE-1 downto 0);
	ram_rdat	:in std_logic_vector(15 downto 0);
	ram_done	:in std_logic;
	
	fram0_addr	:in std_logic_vector(10 downto 0);
	fram0_data	:out std_logic_vector(15 downto 0);
	fram0r_data	:out std_logic_vector(3 downto 0);

	fram1_addr	:in std_logic_vector(10 downto 0);
	fram1_data	:out std_logic_vector(15 downto 0);
	fram1r_data	:out std_logic_vector(3 downto 0);

	vclk	:in std_logic;
	rclk	:in std_logic;
	rstn	:in std_logic
);
end videocont;

architecture rtl of videocont is
signal	curVnum0	:std_logic_vector(10 downto 0);
signal	curVnum1	:std_logic_vector(10 downto 0);
signal	curH0addr:std_logic_vector(ADDRWIDTH-1 downto 0);
signal	curH1addr:std_logic_vector(ADDRWIDTH-1 downto 0);

signal	V0read,V1read	:std_logic;
signal	LINEADD1	:std_logic_vector(15 downto 0);
signal	LINEADD2	:std_logic_vector(15 downto 0);
signal	LINEADD1P0,LINEADD1P1	:std_logic_vector(15 downto 0);
signal	LINEADD2P0,LINEADD2P1	:std_logic_vector(15 downto 0);
signal	wraddr	:std_logic_vector(8 downto 0);
signal	wraddr2	:std_logic_vector(9 downto 0);
type state_t is(
	st_idle,
	st_read0,
	st_read0s,
	st_read1,
	st_read1s
);
signal	state	:state_t;
signal	ZHcount0	:std_logic_vector(3 downto 0);
signal	ZHcount1	:std_logic_vector(3 downto 0);

signal	v0pend,v1pend	:std_logic;
signal	wr00,wr01,wr10,wr11	:std_logic;
signal	rwr00,rwr01,rwr10,rwr11		:std_logic_vector(3 downto 0);
signal	ramsel0	:std_logic;
signal	ramsel1	:std_logic;
signal	fram0_data0	:std_logic_Vector(15 downto 0);
signal	fram0_data1	:std_logic_Vector(15 downto 0);
signal	fram1_data0	:std_logic_Vector(15 downto 0);
signal	fram1_data1	:std_logic_Vector(15 downto 0);
signal	fram0r_data0:std_logic_Vector(3 downto 0);
signal	fram0r_data1:std_logic_Vector(3 downto 0);
signal	fram1r_data0:std_logic_Vector(3 downto 0);
signal	fram1r_data1:std_logic_Vector(3 downto 0);
signal 	ram_rdatx	:std_logic_vector(15 downto 0);
signal	hwidfull0	:std_logic_vector(19 downto 0);
signal	hwidfull1	:std_logic_vector(19 downto 0);
signal	V1READQ		:std_logic;
signal	ram_blens	:std_logic_vector(COLSIZE-1 downto 0);
signal	blen1			:std_logic_vector(COLSIZE-1 downto 0);
signal	hblen			:std_logic_vector(COLSIZE downto 0);
constant allzero	:std_logic_vector(COLSIZE-1 downto 0)	:=(others=>'0');
component linebuf
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

component linebuf2
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

component rlinebuf
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
END component;

begin

	LINEADD1P1<=LO0 when FO0=x"0000" else FO0;
	LINEADD2P1<=LO1 when FO1=x"0000" else FO1;
	LINEADD1P0<=LO0(14 downto 0) & '0' when FO0=x"0000" else FO0(14 downto 0) & '0';
	LINEADD2P0<=LO1(14 downto 0) & '0' when FO1=x"0000" else FO1(14 downto 0) & '0';
	LINEADD1<=LINEADD1P1 when PMODE='1' else LINEADD1P0;
	LINEADD2<=LINEADD2P1 when PMODE='1' else LINEADD2P0;
	
	hwidfull0<="000000000" & (HDE0-HDS0);
	hwidfull1<="000000000" & (HDE1-HDS1);
	
	
	
	process(vclk,rstn)
	variable nxtaddr	:std_logic_vector(ADDRWIDTH-1 downto 0);
	begin
		if(rstn='0')then
			curH0addr<=(others=>'0');
			curH1addr<=(others=>'0');
			ZHcount0<="0000";
			ZHcount1<="0000";
			ramsel0<='0';
			ramsel1<='0';
			V1READQ<='0';
		elsif(vclk' event and vclk='1')then
			V0read<='0';
			V1read<='0';
			if(VCOMP='1')then
				if(PMODE='1')then
					if(PAGESEL0='0')then
						curH0addr<=RAM_VRAM0P0(ADDRWIDTH-1 downto 0)+(FA0 & '0')-(LINEADD1 & '0');
					else
						curH0addr<=RAM_VRAM0P1(ADDRWIDTH-1 downto 0)+(FA0 & '0')-(LINEADD1 & '0');
					end if;
					if(PAGESEL1='0')then
						curH1addr<=RAM_VRAM1P0(ADDRWIDTH-1 downto 0)+(FA1 & '0')-(LINEADD2 & '0');
					else
						curH1addr<=RAM_VRAM1P1(ADDRWIDTH-1 downto 0)+(FA1 & '0')-(LINEADD2 & '0');
					end if;
				else
					curH0addr<=RAM_VRAM0(ADDRWIDTH-1 downto 0)+(FA0 & '0')-(LINEADD1 & '0');
					curH1addr<=RAM_VRAM0(ADDRWIDTH-1 downto 0)+(FA0 & '0')-(LINEADD1 & '0')+hblen;
				end if;
				ZHcount0<="0000";
				ZHcount1<="0000";
			elsif(HCOMP='1')then
				if(V0en='1')then
					if(ZHcount0="0000")then
						ramsel0<=not ramsel0;
						ZHcount0<=ZV0;
						nxtaddr:=curH0addr+(LINEADD1 & '0');
						if(PMODE='1')then
							if(nxtaddr>=RAM_VRAM1)then
								curH0addr<=nxtaddr-x"20000";
							else
								curH0addr<=nxtaddr;
							end if;
						else
							if(nxtaddr>=RAM_VRAMEND)then
								curH0addr<=nxtaddr-x"40000";
							else
								curH0addr<=nxtaddr;
							end if;
						end if;
						V0read<='1';
					else
						ZHcount0<=ZHcount0-1;
					end if;
				end if;
				if(V1en='1')then
					if(ZHcount1="0000")then
						ramsel1<=not ramsel1;
						ZHcount1<=ZV1;
						nxtaddr:=curH1addr+(LINEADD2 & '0');
						if(nxtaddr>=RAM_VRAMEND)then
							curH1addr<=nxtaddr-x"20000";
						else
							curH1addr<=nxtaddr;
						end if;
						V1READQ<='1';
					else
						ZHcount1<=ZHcount1-1;
					end if;
				end if;
			elsif(HHCOMP='1')then
				if(V1READQ='1')then
					V1read<='1';
				end if;
				V1READQ<='0';
			end if;
		end if;
	end process;
				
	process(rclk,rstn)
	variable vblen	:std_logic_vector(colsize downto 0);
	variable vaddr	:std_logic_vector(colsize downto 0);
	variable bitsft	:integer range 0 to 8;
	begin
		if(rstn='0')then
			v0pend<='0';
			v1pend<='0';
			state<=st_idle;
			ram_addr<=(others=>'0');
			hblen<=(others=>'0');
		elsif(rclk' event and rclk='1')then
			ram_rd<='0';
			if(v0read='1')then
				v0pend<='1';
			end if;
			if(v1read='1')then
				v1pend<='1';
			end if;
			case state is
			when st_idle =>
				if(v0pend='1')then
					ram_addr<=curH0addr;
					case ZH0 is
					when "0000" =>
						bitsft:=2;
					when "0001" | "0010"=>
						bitsft:=3;
					when "0011" | "0100" | "0101" | "0110" =>
						bitsft:=4;
					when "0111" | "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110" =>
						bitsft:=5;
					when "1111" =>
						bitsft:=6;
					when others =>
						bitsft:=2;
					end case;
					case CL0 is		--CRTC 1c
					when "01" =>		--2screens,16bit
						vblen:=hwidfull0(COLSIZE+bitsft-2 downto bitsft-2);
					when "10" =>		--1screen,16bit(half)
						vblen:=hwidfull0(COLSIZE+bitsft-1 downto bitsft-1);
					when "11" =>		--1screen,8bit(half)/2screens,4bit
						vblen:=hwidfull0(COLSIZE+bitsft-0 downto bitsft-0);
					when others =>
						vblen:=hwidfull0(COLSIZE+bitsft-0 downto bitsft-0);
					end case;
					hblen<=vblen;
					vaddr:=('0' & curH0addr(COLSIZE-1 downto 0))+vblen;
					if(vaddr(COLSIZE)='1')then
						ram_blens<=vaddr(COLSIZE-1 downto 0);
						blen1<=vblen(COLSIZE-1 downto 0) -vaddr(COLSIZE-1 downto 0);
						ram_blen<=vblen(COLSIZE-1 downto 0)-vaddr(COLSIZE-1 downto 0);
					else
						ram_blens<=(others=>'0');
						blen1<=vblen(COLSIZE-1 downto 0);
						ram_blen<=vblen(COLSIZE-1 downto 0);
					end if;
					ram_rd<='1';
					state<=st_read0;
				elsif(v1pend='1')then
					if(PMODE='1')then
						ram_addr<=curH1addr;
					else
						ram_addr<=curH0addr+hblen;
					end if;
					case ZH1 is
					when "0000" =>
						bitsft:=2;
					when "0001" | "0010"=>
						bitsft:=3;
					when "0011" | "0100" | "0101" | "0110" =>
						bitsft:=4;
					when "0111" | "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110" =>
						bitsft:=5;
					when "1111" =>
						bitsft:=6;
					when others =>
						bitsft:=2;
					end case;
					case CL1 is
					when "01" =>
						vblen:=hwidfull1(COLSIZE+bitsft-2 downto bitsft-2);
					when "10" =>
						vblen:=hwidfull1(COLSIZE+bitsft-1 downto bitsft-1);
					when "11" =>
						vblen:=hwidfull1(COLSIZE+bitsft-0 downto bitsft-0);
					when others =>
						vblen:=hwidfull1(COLSIZE+bitsft-0 downto bitsft-0);
					end case;
					vaddr:=('0' & curH1addr(COLSIZE-1 downto 0))+vblen;
					if(vaddr(COLSIZE)='1')then
						ram_blens<=vaddr(COLSIZE-1 downto 0);
						blen1<=vblen(COLSIZE-1 downto 0) -vaddr(COLSIZE-1 downto 0);
						ram_blen<=vblen(COLSIZE-1 downto 0)-vaddr(COLSIZE-1 downto 0);
					else
						ram_blens<=(others=>'0');
						blen1<=vblen(COLSIZE-1 downto 0);
						ram_blen<=vblen(COLSIZE-1 downto 0);
					end if;
					ram_rd<='1';
					state<=st_read1;
				end if;
			when st_read0 =>
				if(ram_done='1')then
					if(ram_blens/=allzero)then
						ram_blen<=ram_blens;
						ram_addr(ADDRWIDTH-1 downto colsize)<=(curH0addr(ADDRWIDTH-1 downto colsize))+1;
						ram_addr(colsize-1 downto 0)<=(others=>'0');
						ram_rd<='1';
						state<=st_read0s;
					else
						v0pend<='0';
						state<=st_idle;
					end if;
				end if;
			when st_read1 =>
				if(ram_done='1')then
					if(ram_blens/=allzero)then
						ram_blen<=ram_blens;
						ram_addr(ADDRWIDTH-1 downto colsize)<=(curH1addr(ADDRWIDTH-1 downto colsize))+1;
						ram_addr(colsize-1 downto 0)<=(others=>'0');
						ram_rd<='1';
						state<=st_read1s;
					else
						v1pend<='0';
						state<=st_idle;
					end if;
				end if;
			when st_read0s =>
				if(ram_done='1')then
					v0pend<='0';
					state<=st_idle;
				end if;
			when st_read1s =>
				if(ram_done='1')then
					v1pend<='0';
					state<=st_idle;
				end if;
			when others =>
				state<=st_idle;
			end case;
		end if;
	end process;
	
	wr00<=	ram_rval when (state=st_read0 or state=st_read0s or (PMODE='0' and (state=st_read1 or state=st_read1s))) and ramsel0='0' else '0';
	wr01<=	ram_rval when (state=st_read1 or state=st_read1s) and ramsel1='0' else '0';
	wr10<=	ram_rval when (state=st_read0 or state=st_read0s or (PMODE='0' and (state=st_read1 or state=st_read1s))) and ramsel0='1' else '0';
	wr11<=	ram_rval when (state=st_read1 or state=st_read1s) and ramsel1='1' else '0';

	wraddr<=	ram_num(8 downto 0) when state=st_read0 or state=st_read1 else
				blen1+ram_num(8 downto 0);
	wraddr2<=('0' & ram_num(8 downto 0)) when state=st_read0 else
				('0' & ram_num(8 downto 0))+blen1 when state=st_read0s else
				hblen + ram_num(8 downto 0) when state=st_read1 else
				hblen + ram_num(8 downto 0) + blen1 when state=st_read1s else
				(others=>'0');
	
	buf00	:linebuf2 port map(
		data			=>ram_rdat,
		rdaddress	=>fram0_Addr(9 downto 0),
		rdclock		=>vclk,
		wraddress	=>wraddr2,
		wrclock		=>rclk,
		wren			=>wr00,
		q				=>fram0_data0
	);

	buf01	:linebuf port map(
		data			=>ram_rdat,
		rdaddress	=>fram1_Addr(8 downto 0),
		rdclock		=>vclk,
		wraddress	=>wraddr,
		wrclock		=>rclk,
		wren			=>wr01,
		q				=>fram1_data0
	);
	
	buf10	:linebuf2 port map(
		data			=>ram_rdat,
		rdaddress	=>fram0_Addr(9 downto 0),
		rdclock		=>vclk,
		wraddress	=>wraddr2,
		wrclock		=>rclk,
		wren			=>wr10,
		q				=>fram0_data1
	);

	buf11	:linebuf port map(
		data			=>ram_rdat,
		rdaddress	=>fram1_Addr(8 downto 0),
		rdclock		=>vclk,
		wraddress	=>wraddr,
		wrclock		=>rclk,
		wren			=>wr11,
		q				=>fram1_data1
	);
	
	fram0_data<=fram0_data1 when ramsel0='0' else fram0_data0;
	fram1_data<=fram1_data1 when ramsel1='0' else fram1_data0;
	
	process(ram_rdat)begin
		for i in 0 to 7 loop
			ram_rdatx(i)<=ram_rdat(7-i);
			ram_rdatx(i+8)<=ram_rdat(15-i);
		end loop;
	end process;
--	ram_rdatx<=ram_rdat;
	
	--screen0 ram0
	
	rwr00<=	"0000" when ram_rval='0' or (state/=st_read0 and state/=st_read0s) or ramsel0='1' else
				"0001" when wraddr(1 downto 0)="00" else
				"0010" when wraddr(1 downto 0)="01" else
				"0100" when wraddr(1 downto 0)="10" else
				"1000" when wraddr(1 downto 0)="11" else
				"0000";
	r0bufv0p0	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr00(0),
		q				=>fram0r_data0(0 downto 0)
	); 
	r0bufv0p1	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr00(1),
		q				=>fram0r_data0(1 downto 1)
	); 
	r0bufv0p2	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr00(2),
		q				=>fram0r_data0(2 downto 2)
	); 
	r0bufv0p3	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr00(3),
		q				=>fram0r_data0(3 downto 3)
	); 

	--screen1 ram0

	rwr01<=	"0000" when ram_rval='0' or (state/=st_read1 and state/=st_read1s) or ramsel1='1' else
				"0001" when wraddr(1 downto 0)="00" else
				"0010" when wraddr(1 downto 0)="01" else
				"0100" when wraddr(1 downto 0)="10" else
				"1000" when wraddr(1 downto 0)="11" else
				"0000";
	r0bufv1p0	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr01(0),
		q				=>fram1r_data0(0 downto 0)
	); 
	r0bufv1p1	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr01(1),
		q				=>fram1r_data0(1 downto 1)
	); 
	r0bufv1p2	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr01(2),
		q				=>fram1r_data0(2 downto 2)
	); 
	r0bufv1p3	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr01(3),
		q				=>fram1r_data0(3 downto 3)
	); 

	--screen0 ram1

	rwr10<=	"0000" when ram_rval='0' or (state/=st_read0 and state/=st_read0s) or ramsel0='0' else
				"0001" when wraddr(1 downto 0)="00" else
				"0010" when wraddr(1 downto 0)="01" else
				"0100" when wraddr(1 downto 0)="10" else
				"1000" when wraddr(1 downto 0)="11" else
				"0000";
	r1bufv0p0	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr10(0),
		q				=>fram0r_data1(0 downto 0)
	); 
	r1bufv0p1	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr10(1),
		q				=>fram0r_data1(1 downto 1)
	); 
	r1bufv0p2	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr10(2),
		q				=>fram0r_data1(2 downto 2)
	); 
	r1bufv0p3	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram0_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr10(3),
		q				=>fram0r_data1(3 downto 3)
	); 

	--screen1 ram1

	rwr11<=	"0000" when ram_rval='0' or (state/=st_read1 and state/=st_read1s) or ramsel1='0' else
				"0001" when wraddr(1 downto 0)="00" else
				"0010" when wraddr(1 downto 0)="01" else
				"0100" when wraddr(1 downto 0)="10" else
				"1000" when wraddr(1 downto 0)="11" else
				"0000";
	r1bufv1p0	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr11(0),
		q				=>fram1r_data1(0 downto 0)
	); 
	r1bufv1p1	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr11(1),
		q				=>fram1r_data1(1 downto 1)
	); 
	r1bufv1p2	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr11(2),
		q				=>fram1r_data1(2 downto 2)
	); 
	r1bufv1p3	:rlinebuf port map(
		data			=>ram_rdatx,
		rdaddress	=>fram1_addr,
		rdclock		=>vclk,
		wraddress	=>wraddr(8 downto 2),
		wrclock		=>rclk,
		wren			=>rwr11(3),
		q				=>fram1r_data1(3 downto 3)
	); 
	
	fram0r_data<=fram0r_data1 when ramsel0='0' else fram0r_data0;
	fram1r_data<=fram1r_data1 when ramsel1='0' else fram1r_data0;

end rtl;
