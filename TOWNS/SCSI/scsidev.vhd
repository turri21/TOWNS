library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity scsidev is
generic(
	clkfreq	:integer	:=10000;	--kHz
	toutlen	:integer	:=100;	--msec
	sectwid	:integer	:=9		--2**n byte/sect
);
port(
	IDAT		:in std_logic_vector(7 downto 0);
	ODAT		:out std_logic_vector(7 downto 0);
	SEL		:in std_logic;
	BSYI		:in std_logic;
	BSYO		:out std_logic;
	REQ		:out std_logic;
	ACK		:in std_logic;
	IO			:out std_logic;
	CD			:out std_logic;
	MSG		:out std_logic;
	ATN		:in std_logic;
	RST		:in std_logic;
	
	idsel		:in integer range 0 to 7;
	
	unit		:out std_logic_vector(2 downto 0);
	capacity	:in std_logic_vector(63 downto 0);
	lba		:out std_logic_vector(31 downto 0);
	rdreq		:out std_logic;
	wrreq		:out std_logic;
	syncreq	:out std_logic;
	sectaddr	:out std_logic_vector(sectwid-1 downto 0);
	rddat		:in std_logic_vector(7 downto 0);
	wrdat		:out std_logic_vector(7 downto 0);
	sectbusy	:in std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end scsidev;

architecture rtl of scsidev is
type state_t is(
	st_idle,
	st_arbc,
	st_sel,
	st_msgco,
	st_msgcow,
	st_msgcow2,
	st_cmd,
	st_cmdn,
	st_cmdnw,
	st_msgci,
	st_msgciw,
	st_msgciw2,
	st_prepar,
	st_arbd,
	st_arbd2,
	st_bwait,
	st_resel,
	st_msgdi,
	st_msgdiw,
	st_msgdiw2,
	st_data,
	st_dataw,
	st_dataw2,
	st_status,
	st_statusw,
	st_statusw2,
	st_msgdo,
	st_msgdow,
	st_msgdow2,
	st_end,
	st_free
);
signal	state	:state_t;

signal	command	:std_logic_vector(7 downto 0);
signal	ssel	:std_logic;
signal	sack	:std_logic;
signal	sbusy	:std_logic;
signal	bytecount	:std_logic_vector(sectwid-1 downto 0);
signal	sectcount	:std_logic_vector(31 downto 0);
signal	sectnum		:std_logic_vector(31 downto 0);
signal	status	:std_logic_vector(7 downto 0);
signal	control	:std_logic_vector(7 downto 0);
signal	message	:std_logic_vector(7 downto 0);
signal	lbac	:std_logic_vector(31 downto 0);
signal	lbab	:std_logic_vector(31 downto 0);
signal	inid	:integer range 0 to 7;
signal	watn	:std_logic;
signal	msgco	:std_logic_vector(7 downto 0);
signal	cmdlen	:integer range 0 to 15;
signal	cmdnum	:integer range 0 to 15;
subtype DAT_LAT_TYPE is std_logic_vector(7 downto 0); 
type DAT_LAT_ARRAY is array (natural range <>) of DAT_LAT_TYPE; 
signal	PARAM	:DAT_LAT_ARRAY(0 to 15);
signal	sectsize	:std_logic_vector(31 downto 0);
signal	sects		:std_logic_vector(63 downto 0);
constant toutval	:integer	:=(clkfreq*toutlen);
signal	toutcnt	:integer range 0 to toutval;
signal	sect0		:std_logic_Vector(sectwid-1 downto 0);
signal	sect1		:std_logic_Vector(sectwid-1 downto 0);
signal	sectf		:std_logic_Vector(sectwid-1 downto 0);
signal	inqaddr	:std_logic_vector(7 downto 0);
signal	inqdata	:std_logic_vector(7 downto 0);

component INQUIRYDATA
port(
	addr	:in std_logic_vector(7 downto 0);
	data	:out std_logic_vector(7 downto 0);
	
	clk	:in std_logic
);
end component;

begin

	process(clk,rstn)begin
		if(rstn='0')then
			ssel<='0';
			sack<='0';
			sbusy<='0';
		elsif(clk' event and clk='1')then
			ssel<=SEL;
			sack<=ACK;
			sbusy<=BSYI;
		end if;
	end process;
	sects(63 downto (63-sectwid+1))<=(others=>'0');
	sects((63-sectwid) downto 0)<=capacity(63 downto sectwid);
	sectsize(31 downto sectwid+1)<=(others=>'0');
	sectsize(sectwid)<='1';
	sectsize(sectwid-1 downto 0)<=(others=>'0');
	
	sect0<=(others=>'0');
	sectf<=(others=>'1');
	sect1(sectwid-1 downto 1)<=(others=>'0');
	sect1(0)<='1';
	
	command<=PARAM(0);
	
	cmdlen<=
		 5 when command(7 downto 5)="000" else
		 9 when command(7 downto 5)="001" else
		 9 when command(7 downto 5)="010" else
		15 when command(7 downto 5)="100" else
		11 when command(7 downto 5)="101" else
		 5 when command=x"c2" else
		 0;
	unit<=	PARAM(1)(7 downto 5);
	lbac<=		
		x"00" & "000" & PARAM(1)(4 downto 0) & PARAM(2) & PARAM(3) when cmdlen=5 else
		PARAM(2) & PARAM(3) & PARAM(4) & PARAM(5) when cmdlen=9 else
		PARAM(2) & PARAM(3) & PARAM(4) & PARAM(5) when cmdlen=11 else
		PARAM(6) & PARAM(7) & PARAM(8) & PARAM(9) when cmdlen=15 else
		(others=>'0');
	sectnum<=
		x"000000" & PARAM(4) when cmdlen=5 else
		x"0000" & PARAM(7) & PARAM(8) when cmdlen=9 else
		PARAM(6) & PARAM(7) & PARAM(8) & PARAM(9) when cmdlen=11 else
		PARAM(10) & PARAM(11) & PARAM(12) & PARAM(13) when cmdlen=15 else
		(others=>'0');
	control<=
		PARAM(5) when cmdlen=5 else
		PARAM(9) when cmdlen=9 else
		PARAM(11) when cmdlen=11 else
		PARAM(15) when cmdlen=15 else
		(others=>'0');
	
	process(clk,rstn)
	variable selid	:integer range 0 to 8;
	variable swait	:integer range 0 to 3;
	variable vid	:integer range 0 to 7;
	begin
		if(rstn='0')then
			state<=st_idle;
			bytecount<=(others=>'0');
			ODAT<=(others=>'0');
			BSYO<='0';
			REQ<='0';
			IO<='0';
			CD<='0';
			MSG<='0';
			sectcount<=(others=>'0');
			message<=(others=>'0');
			status<=(others=>'0');
			lbab<=(others=>'0');
			wrreq<='0';
			rdreq<='0';
			syncreq<='0';
			swait:=0;
			inid<=0;
			watn<='0';
			cmdnum<=0;
		elsif(clk' event and clk='1')then
			wrreq<='0';
			rdreq<='0';
			syncreq<='0';
			if(RST='1')then
				bytecount<=(others=>'0');
				ODAT<=(others=>'0');
				BSYO<='0';
				REQ<='0';
				IO<='0';
				CD<='0';
				MSG<='0';
				sectcount<=(others=>'0');
				message<=(others=>'0');
				status<=(others=>'0');
				lbab<=(others=>'0');
				wrreq<='0';
				rdreq<='0';
				syncreq<='0';
				swait:=0;
				inid<=0;
				watn<='0';
				cmdnum<=0;
			elsif(swait>0)then
				swait:=swait-1;
			else
				if(toutcnt=0 and (state/=st_idle and state/=st_prepar) and toutlen>0)then
					state<=st_idle;
					BSYO<='0';
					REQ<='0';
					IO<='0';
					CD<='0';
					MSG<='0';
					ODAT<=(others=>'0');
					PARAM<=(others=>x"00");
				else
					if(toutlen>0)then
						toutcnt<=toutcnt-1;
					end if;
				end if;
				case state is
				when st_idle =>
					if(ssel='1')then
						selid:=8;
						for i in 7 downto 0 loop
							if(IDAT(i)='1' and idsel=i)then
								selid:=i;
							end if;
							if(IDAT(i)='1' and idsel/=i)then
								inid<=i;
							end if;
						end loop;
						if(selid/=8)then
							BSYO<='1';
							watn<=ATN;
							state<=st_sel;
							toutcnt<=toutval;
						else
							BSYO<='0';
						end if;
					end if;
				when st_sel =>
					if(ssel='0')then
						CD<='1';
						msgco<=(others=>'0');
						if(watn='1')then
							state<=st_msgco;
							toutcnt<=toutval;
						else
							state<=st_cmd;
							toutcnt<=toutval;
						end if;
					end if;
				when st_msgco =>
					MSG<='1';						
					REQ<='1';
					state<=st_msgcow;
					toutcnt<=toutval;
				when st_msgcow =>
					if(sack='1')then
						msgco<=IDAT;
						REQ<='0';
						MSG<='0';
						state<=st_msgcow2;
						toutcnt<=toutval;
					end if;
				when st_msgcow2 =>
					if(sack='0')then
						state<=st_cmd;
						toutcnt<=toutval;
					end if;
				when st_cmd =>
					REQ<='1';
					cmdnum<=0;
					PARAM<=(others=>x"00");
					state<=st_cmdn;
					toutcnt<=toutval;
				when st_cmdn =>
					if(sack='1')then
						PARAM(cmdnum)<=IDAT;
						REQ<='0';
						state<=st_cmdnw;
						toutcnt<=toutval;
					end if;
				when st_cmdnw =>
					if(sack='0')then
						if(cmdnum=cmdlen)then
							sectcount<=sectnum;
							lbab<=lbac;
							CD<='0';
							case command is
							when x"00" =>	--test drive ready
								if(capacity=x"00000000")then
									status<=x"ff";
								else
									status<=x"00";
								end if;
								state<=st_status;
								toutcnt<=toutval;
							when x"01" =>	--recaribrate
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							when x"03" =>	--request sense status
								IO<='1';
								bytecount(sectwid-1 downto 4)<=(others=>'0');
								bytecount(3 downto 0)<="0100";
								state<=st_data;
								toutcnt<=toutval;
							when x"04" =>	--format drive
								if(capacity(63 downto 9)>lbab)then
									status<=x"00";
								else
									status<=x"ff";
								end if;
								state<=st_status;
								toutcnt<=toutval;
							when x"08" | x"28" | x"88" =>	--read
								if(sectnum=x"00000000")then
									status<=x"00";
									state<=st_status;
									toutcnt<=toutval;
								else
									IO<='1';
									bytecount<=(others=>'0');
									rdreq<='1';
									if(msgco(7 downto 6)="11")then
										MSG<='1';
										IO<='1';
										ODAT<=x"04";	--disconnect
										state<=st_msgci;
										toutcnt<=toutval;
									else
										swait:=2;
										state<=st_data;
										toutcnt<=toutval;
									end if;
								end if;
							when x"0a" | x"2a" | x"8a" =>	--write
								if(sectnum=x"00000000")then
									status<=x"00";
									state<=st_status;
									toutcnt<=toutval;
								else
									ODAT<=(others=>'0');
									IO<='0';
									bytecount<=(others=>'0');
									swait:=2;
									state<=st_data;
									toutcnt<=toutval;
								end if;
							when x"12" =>	--inquiry
								IO<='1';
								bytecount<=(others=>'0');
								swait:=2;
								state<=st_data;
								toutcnt<=toutval;
							when x"c2" =>	--read config
								ODAT<=(others=>'0');
								IO<='0';
								bytecount(sectwid-1 downto 4)<=(others=>'0');
								bytecount(3 downto 0)<="1010";
								state<=st_data;
								toutcnt<=toutval;
							when x"25" =>	--read capacity(10)
								IO<='1';
								bytecount(sectwid-1 downto 4)<=(others=>'0');
								bytecount(3 downto 0)<="1000";
								state<=st_data;
								toutcnt<=toutval;
							when x"9e" =>	--read capacity(16)
								IO<='1';
								bytecount(sectwid-1 downto 6)<=(others=>'0');
								bytecount(5 downto 0)<="100000";
								state<=st_data;
								toutcnt<=toutval;
							when others =>
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							end case;
						else
							REQ<='1';
							cmdnum<=cmdnum+1;
							state<=st_cmdn;
						end if;
					end if;
				when st_msgci =>
					REQ<='1';
					state<=st_msgciw;
					toutcnt<=toutval;
				when st_msgciw=>
					if(sack='1')then
						REQ<='0';
						state<=st_msgciw2;
						toutcnt<=toutval;
					end if;
				when st_msgciw2 =>
					if(sack='0')then
						BSYO<='0';
						IO<='0';
						CD<='0';
						MSG<='0';
						ODAT<=(others=>'0');
						state<=st_prepar;
					end if;
				when st_prepar =>
					if(sectbusy='0')then
						BSYO<='1';
						swait:=3;
						ODAT(idsel)<='1';
						state<=st_arbd;
						toutcnt<=toutval;
					end if;
				when st_arbd =>
					if(ssel='1')then
						BSYO<='0';
						selid:=8;
						for i in 0 to 7 loop
							if(IDAT(i)='1')then
								selid:=i;
							end if;
						end loop;
						if(selid=idsel)then
							state<=st_arbd2;
							toutcnt<=toutval;
							IO<='1';
							ODAT<=(others=>'0');
							ODAT(inid)<='1';
							swait:=3;
						else
							state<=st_bwait;
							toutcnt<=toutval;
						end if;
					end if;
				when st_bwait =>
					if(ssel='0' and sbusy='0')then
						BSYO<='1';
						swait:=3;
						ODAT(idsel)<='1';
						state<=st_arbd;
						toutcnt<=toutval;
					end if;
				when st_arbd2 =>
					BSYO<='1';
					state<=st_resel;
					toutcnt<=toutval;
				when st_resel =>
					if(ssel='0')then
						CD<='1';
						MSG<='1';
						ODAT<=x"00";
						REQ<='1';
						state<=st_msgdi;
						toutcnt<=toutval;
					end if;
				when st_msgdi =>
					if(sack='1')then
						REQ<='0';
						CD<='0';
						MSG<='0';
						state<=st_data;
						toutcnt<=toutval;
					end if;
				when st_data =>
					if(sack='0')then
						case command is
						when x"03" =>
							ODAT<=(others=>'0');
							REQ<='1';
							state<=st_dataw;
							toutcnt<=toutval;
						when x"08" | x"28" | x"88" =>
							if(sectbusy='0')then
								ODAT<=rddat;
								REQ<='1';
								state<=st_dataw;
								toutcnt<=toutval;
							end if;
						when x"0a" | x"2a" | x"8a" =>
							REQ<='1';
							state<=st_dataw;
							toutcnt<=toutval;
						when x"12" =>
							ODAT<=inqdata;
							REQ<='1';
							state<=st_dataw;
							toutcnt<=toutval;
						when x"25" =>
							case bytecount(3 downto 0) is
							when x"8" =>
								ODAT<=sects(31 downto 24);
							when x"7" =>
								ODAT<=sects(23 downto 16);
							when x"6" =>
								ODAT<=sects(15 downto 8);
							when x"5" =>
								ODAT<=sects(7 downto 0);
							when x"4" =>
								ODAT<=sectsize(31 downto 24);
							when x"3" =>
								ODAT<=sectsize(23 downto 16);
							when x"2" =>
								ODAT<=sectsize(15 downto 8);
							when x"1" =>
								ODAT<=sectsize(7 downto 0);
							when others =>
								ODAT<=(others=>'0');
							end case;
							REQ<='1';
							state<=st_dataw;
							toutcnt<=toutval;
						when x"9e" =>
							case bytecount(7 downto 0) is
							when x"20" =>
								ODAT<=sects(63 downto 56);
							when x"1f" =>
								ODAT<=sects(55 downto 48);
							when x"1e" =>
								ODAT<=sects(47 downto 40);
							when x"1d" =>
								ODAT<=sects(31 downto 24);
							when x"1c" =>
								ODAT<=sects(23 downto 16);
							when x"1b" =>
								ODAT<=sects(15 downto 8);
							when x"1a" =>
								ODAT<=sects(7 downto 0);
							when x"19" =>
								ODAT<=sectsize(31 downto 24);
							when x"18" =>
								ODAT<=sectsize(23 downto 16);
							when x"17" =>
								ODAT<=sectsize(15 downto 8);
							when x"16" =>
								ODAT<=sectsize(7 downto 0);
							when others =>
								ODAT<=(others=>'0');
							end case;
							REQ<='1';
							state<=st_dataw;
							toutcnt<=toutval;
						when x"c2" =>
							REQ<='1';
							state<=st_dataw;
						when others =>
							state<=st_idle;
						end case;
					end if;
				when st_dataw =>
					if(sack='1')then
						REQ<='0';
						case command is
						when x"03" | x"25" | x"9e" =>
							if(bytecount>sect1)then
								bytecount<=bytecount-1;
								state<=st_data;
								toutcnt<=toutval;
							else
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							end if;
						when x"08" | x"28" | x"88" =>
							if(bytecount/=sectf)then
								bytecount<=bytecount+1;
								rdreq<='1';
								swait:=2;
								state<=st_data;
								toutcnt<=toutval;
							else
								if(sectcount>x"00000001")then
									sectcount<=sectcount-1;
									lbab<=lbab+1;
									bytecount<=(others=>'0');
									rdreq<='1';
									swait:=2;
									state<=st_data;
								else
									status<=x"00";
									state<=st_status;
									toutcnt<=toutval;
								end if;
							end if;
						when x"0a" | x"2a" | x"8a" =>
							wrdat<=IDAT;
							wrreq<='1';
							swait:=2;
							state<=st_dataw2;
							toutcnt<=toutval;
						when x"12" =>
							if(bytecount(8 downto 0)/=sectnum(8 downto 0))then
								bytecount<=bytecount+1;
								swait:=2;
								state<=st_data;
								toutcnt<=toutval;
							else
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							end if;
						when x"c2" =>
							if(bytecount>sect1)then
								bytecount<=bytecount-1;
								state<=st_data;
								toutcnt<=toutval;
							else
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							end if;
						when others =>
							state<=st_idle;
						end case;
					end if;
				when st_dataw2 =>
					if(sectbusy='0')then
						if(bytecount/=sectf)then
							bytecount<=bytecount+1;
							state<=st_data;
							toutcnt<=toutval;
						else
							if(sectcount>x"00000001")then
								sectcount<=sectcount-1;
								lbab<=lbab+1;
								bytecount<=(others=>'0');
								state<=st_data;
								toutcnt<=toutval;
							else
								status<=x"00";
								state<=st_status;
								toutcnt<=toutval;
							end if;
						end if;
					end if;
				when st_status =>
					if(sack='0')then
						IO<='1';
						CD<='1';
						ODAT<=status;
						state<=st_statusw;
						toutcnt<=toutval;
					end if;
				when st_statusw =>
					REQ<='1';
					state<=st_statusw2;
					toutcnt<=toutval;
				when st_statusw2 =>
					if(sack='1')then
						REQ<='0';
						message<=x"00";
						state<=st_msgdo;
						toutcnt<=toutval;
					end if;
				when st_msgdo =>
					if(sack='0')then
						ODAT<=message;
						MSG<='1';
						state<=st_msgdow;
						toutcnt<=toutval;
					end if;
				when st_msgdow =>
					REQ<='1';
					state<=st_msgdow2;
					toutcnt<=toutval;
				when st_msgdow2 =>
					if(sack='1')then
						REQ<='0';
						state<=st_end;
						toutcnt<=toutval;
					end if;
				when st_end =>
					if(sack='0')then
					ODAT<=(others=>'0');
						IO<='0';
						CD<='0';
						MSG<='0';
						state<=st_free;
						toutcnt<=toutval;
						syncreq<='1';
						swait:=2;
					end if;
				when st_free =>
					BSYO<='0';
					state<=st_idle;
				when others =>
					state<=st_idle;
				end case;
			end if;
		end if;
	end process;
	
	lba<=lbab;
	sectaddr<=bytecount;
	
	inq	:INQUIRYDATA port map(bytecount(7 downto 0),inqdata,clk);
						
end rtl;	