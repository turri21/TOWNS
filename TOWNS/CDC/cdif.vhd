LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cdif is
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rddat	:out std_logic_vector(7 downto 0);
	wrdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	drq	:out std_logic;
	dack	:in std_logic;
	irq	:out std_logic;
	drdat	:out std_logic_vector(7 downto 0);
	
	mist_mounted	:in std_logic;
	mist_imgsize	:in std_logic_vector(63 downto 0);
	mist_lba	:out std_logic_vector(31 downto 0);
	mist_rd	:out std_logic;
	mist_ack	:in std_logic;
	mist_bufaddr	:in std_logic_vector(8 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;
	
	mist_busyout	:out std_logic;
	mist_busyin		:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end cdif;

architecture rtl of cdif is
signal	MSTATUS	:std_logic_vector(7 downto 0);
signal	STATUS	:std_logic_vector(7 downto 0);
signal	DATAREG	:std_logic_vector(7 downto 0);
signal	CDSCSTA	:std_logic_vector(7 downto 0);
signal	CDSCDAT	:std_logic_vector(7 downto 0);
subtype BYTE is std_logic_vector(7 downto 0);
type BYTE_ARRAY is array (natural range <>) of BYTE; 
signal	PARBUF	:BYTE_ARRAY(0 to 7);
signal	STABUF	:BYTE_ARRAY(0 to 3);
signal	STAsdat	:BYTE_ARRAY(0 to 3);
signal	STAset	:std_logic;
signal	CMD		:std_logic_Vector(5 downto 0);
signal	CMD_IRQ	:std_logic;
signal	CMD_STA	:std_logic;

constant CMD_SEEK		:std_logic_vector(5 downto 0)	:="000000";
constant CMD_MD2READ	:std_logic_vector(5 downto 0)	:="000001";
constant CMD_MD1READ	:std_logic_vector(5 downto 0)	:="000010";
constant CMD_RAWREAD	:std_logic_vector(5 downto 0)	:="000011";
constant	CMD_DAPLAY	:std_logic_vector(5 downto 0)	:="000100";
constant CMD_TOCREAD	:std_logic_vector(5 downto 0)	:="000101";
constant CMD_SUBQREAD:std_logic_vector(5 downto 0)	:="000110";
constant CMD_RESET	:std_logic_vector(5 downto 0)	:="011111";
constant CMD_STSTATE	:std_logic_vector(5 downto 0)	:="100000";
constant CMD_DASET	:std_logic_vector(5 downto 0)	:="100001";
constant CMD_DASTOP	:std_logic_vector(5 downto 0)	:="100100";
constant CMD_DAPAUSE	:std_logic_vector(5 downto 0)	:="100101";
constant CMD_UNKNWN2	:std_logic_vector(5 downto 0)	:="100110";
constant CMD_DARESUME:std_logic_vector(5 downto 0)	:="100111";

signal	cmd_bgn	:std_logic;
signal	SRQ		:std_logic;
signal	DRY		:std_logic;
signal	IRQb		:std_logic;
signal	DRQb		:std_logic;
signal	STSF		:std_logic;
signal	DEI		:std_logic;
signal	IRQst		:std_logic;
signal	iord,liord	:std_logic;
signal	iowr,liowr	:std_logic;

begin

	iord<='1' when cs='1' and rd='1' else '0';
	iowr<='1' when cs='1' and wr='1' else '0';
	process(clk,rstn)begin
		if(rstn='0')then
			liord<='0';
			liowr<='0';
		elsif(clk' event and clk='1')then
			liord<=iord;
			liowr<=iowr;
		end if;
	end process;
	

	MSTATUS<=IRQB & DEI & STSF & DRQb & "00" & SRQ & DRY;
	
	rddat<=	MSTATUS	when addr=x"0" else
				STATUS	when addr=x"2" else
				DATAREG	when addr=x"4" else
				CDSCSTA	when addr=x"c" else
				CDSCDAT	when addr=x"d" else
				(others=>'0');
	
	doe<=iord;
	drdat<=(others=>'0');
	
	mist_busyout<='0';
	mist_lba<=(others=>'0');
	mist_rd<='0';
	
	process(clk,rstn)begin
		if(rstn='0')then
			PARBUF<=(others=>x"00");
			CMD<=(others=>'0');
			CMD_IRQ<='0';
			CMD_STA<='0';
			cmd_bgn<='0';
		elsif(clk' event and clk='1')then
			cmd_bgn<='0';
			if(iowr='1' and liowr='0')then
				case addr is
				when x"2" =>
					CMD<=wrdat(7) & wrdat(4 downto 0);
					CMD_IRQ<=wrdat(6);
					CMD_STA<=wrdat(5);
					cmd_bgn<='1';
				when x"c" =>
					PARBUF(0 to 6)<=PARBUF(1 to 7);
					PARBUF(7)<=wrdat;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			STABUF<=(others=>x"00");
			STATUS<=(others=>'0');
			SRQ<='0';
		elsif(clk' event and clk='1')then
			if(STAset='1')then
				STABUF<=STAsdat;
				STATUS<=STAsdat(0);
				SRQ<='1';
			end if;
			if(liord='1' and iord='0')then
				if(addr=x"2")then
					STATUS<=STABUF(1);
					STABUF(0 to 2)<=STABUF(1 to 3);
					STABUF(3)<=x"00";
					SRQ<='0';
				end if;
			end if;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			STAsdat<=(others=>x"00");
			STAset<='0';
			IRQst<='0';
			DRY<='1';
			DRQb<='0';
			DATAREG<=x"00";
			CDSCSTA<="00000000";
			CDSCDAT<=x"00";
		elsif(clk' event and clk='1')then
			STAset<='0';
			IRQst<='0';
			if(cmd_bgn='1')then
				case CMD is
				when CMD_STSTATE =>
					if(CMD_IRQ='1')then
						IRQst<='1';
					end if;
					if(CMD_STA='1')then
						STAsdat(0)<=x"00";
						STAsdat(1)<=x"09";	--not ready
						STAsdat(2)<=x"00";
						STAsdat(3)<=x"00";
						STAset<='1';
					end if;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			IRQb<='0';
		elsif(clk' event and clk='1')then
			if(IRQst='1')then
				IRQb<='1';
			elsif(iord='1' or iowr='1')then
				IRQb<='0';
			end if;
		end if;
	end process;
	
	irq<=IRQb;
	drq<=DRQB;
	STSF<='0';
	DEI<='0';
	
end rtl;

	
	
	