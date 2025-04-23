LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity scsiif is
port(
	cs		:in std_logic;
	addr	:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	drq	:out std_logic;
	dack	:in std_logic;
	drdat	:out std_logic_vector(15 downto 0);
	dwdat	:in std_logic_vector(15 downto 0);
	
	SEL	:out std_logic;
	RST	:out std_logic;
	ATN	:out std_logic;
	ACK	:out std_logic;
	
	REQ	:in std_logic;
	IO		:in std_logic;
	MSG	:in std_logic;
	CD		:in std_logic;
	BUSY	:in std_logic;
	
	DATOUT:out std_logic_vector(7 downto 0);
	DATIN	:in std_logic_vector(7 downto 0);
	DOUTEN:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end scsiif;

architecture rtl of scsiif is
type state_t is(
	st_idle,
	st_read2,
	st_read,
	st_write,
	st_write2,
	st_ackrw,
	st_ackww,
	st_ack
);
signal	state	:state_t;
signal	status	:std_logic_vector(7 downto 0);
signal	ireq		:std_logic;
signal	INTb		:std_logic;
signal	DMAE		:std_logic;
signal	IMSK		:std_logic;
signal	WEN		:std_logic;
signal	RMSK		:std_logic;
signal	WB			:std_logic;
signal	txdat		:std_logic_Vector(7 downto 0);
signal	sreq		:std_logic;
signal	sdatin	:std_logic_vector(7 downto 0);
signal	indat		:std_logic;
signal	datrd		:std_logic;
signal	datrded	:std_logic;
signal	udat		:std_logic_vector(7 downto 0);
signal	drqb		:std_logic;
signal	dirq		:std_logic;

begin

	process(clk,rstn)begin
		if(rstn='0')then
			sreq<='0';
			sdatin<=(others=>'0');
		elsif(clk' event and clk='1')then
			sreq<=REQ;
			sdatin<=DATIN;
		end if;
	end process;

	process(clk,rstn)begin
		if(rstn='0')then
			SEL<='0';
			RST<='0';
			ATN<='0';
			ACK<='0';
			DMAE<='0';
			IMSK<='0';
			WEN<='0';
			RMSK<='0';
			WB<='0';
			txdat<=(others=>'0');
			DATOUT<=(others=>'0');
			state<=st_idle;
			ACK<='0';
			drqb<='0';
			ireq<='0';
			indat<='0';
			udat<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				case addr is
				when '0' =>
					txdat<=wdat;
					indat<='1';
				when '1' =>
					RST<=wdat(0);
					DMAE<=wdat(1);
					SEL<=wdat(2);
					WB<=wdat(3);
					ATN<=wdat(4);
					RMSK<=wdat(5);
					IMSK<=wdat(6);
					WEN<=wdat(7);
					if(wdat(2)='1')then
						DATOUT<=txdat;
						indat<='0';
					end if;
				when others =>
				end case;
			end if;
			
			case state is
			when st_idle =>
				if(sreq='1')then
					if(IO='0')then
						if(DMAE='1' and CD='0')then
							drqb<='1';
--						elsif(DMAE='1' and CD='1' and IMASK='1')then
--							drqb<='1';
						else
							ireq<='1';
						end if;
						state<=st_write;
					else
						if(DMAE='1' and CD='0')then
							drdat(7 downto 0)<=DATIN;
							if(WB='1')then
								ACK<='1';
								state<=st_read2;
							else
								state<=st_read;
								drqb<='1';
							end if;
						else
							txdat<=DATIN;
							state<=st_read;
							ireq<='1';
						end if;
					end if;
				end if;
			when st_write =>
				if(indat='1')then
					DATOUT<=txdat;
					indat<='0';
					ACK<='1';
					state<=st_ack;
					ireq<='0';
					drqb<='0';
				elsif(dack='1')then
					DATOUT<=dwdat(7 downto 0);
					if(WB='1')then
						udat<=dwdat(15 downto 8);
						state<=st_ackww;
					else
						state<=st_ack;
					end if;
					ACK<='1';
					ireq<='0';
					drqb<='0';
				end if;
			when st_ackww =>
				if(sreq='0')then
					ACK<='0';
					ireq<='0';
					drqb<='0';
					state<=st_write2;
				end if;
			when st_write2 =>
				if(sreq='1')then
					DATOUT<=udat;
					ACK<='1';
					state<=st_ack;
				end if;
			when st_read2 =>
				if(sreq='0')then
					ACK<='0';
					state<=st_ackrw;
				end if;
			when st_ackrw =>
				if(sreq='1')then
					drdat(15 downto 8)<=DATIN;
					drqb<='1';
					state<=st_read;
				end if;
			when st_read =>
				if(datrded='1' or dack='1')then
					ACK<='1';
					ireq<='0';
					drqb<='0';
					state<=st_ack;
				end if;
			when st_ack =>
				if(sreq='0')then
					DATOUT<=(others=>'0');
					ACK<='0';
					ireq<='0';
					drqb<='0';
					state<=st_idle;
				end if;
			when others =>
				state<=st_idle;
			end case;
		end if;
	end process;
	
	datrd<='1' when cs='1' and rd='1' and addr='0' else '0';
	
	process(clk,rstn)
	variable lrd	:std_logic;
	begin
		if(rstn='0')then
			datrded<='0';
			lrd:='0';
		elsif(clk' event and clk='1')then
			if(datrd='0' and lrd='1')then
				datrded<='1';
			else
				datrded<='0';
			end if;
			lrd:=datrd;
		end if;
	end process;
	
	drq<=drqb;
	dirq<=drqb and RMSK;
	status<=REQ & IO & MSG & CD & BUSY & '0' & INTb & '0';
	DOUTEN<=WEN;
	rdat<= sdatin when addr='0' else status;
	doe<=cs and rd;
	intb<=ireq and IMSK;
	int<=intb or dirq;
end rtl;