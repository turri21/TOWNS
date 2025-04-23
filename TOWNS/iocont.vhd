LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity iocont is
port(
	cpuaddr	:in std_logic_vector(15 downto 2);
	cpurd		:in std_logic;
	cpuwr		:in std_logic;
	cpubyteen	:in std_logic_vector(3 downto 0);
	cpuwdat	:in std_logic_vector(31 downto 0);

	dwaddr	:out std_logic_vector(15 downto 0);
	swaddr	:out std_logic_vector(15 downto 0);
	baddr		:out std_logic_vector(15 downto 0);
	iobyteen	:out std_logic_vector(3 downto 0);
	
	iord		:out std_logic;
	iowr		:out std_logic;
	iowdat	:out std_logic_Vector(31 downto 0);
	ioswdat	:out std_logic_vector(15 downto 0);
	iobwdat	:out std_logic_vector(7 downto 0);
	iowait	:in std_logic;
	
	rdval		:out std_logic;
	waitreq	:out std_logic;
	iobusy	:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end iocont;

architecture rtl of iocont is

type state_t is(
	st_idle,
	st_read,
	st_write,
	st_done
);
signal	state	:state_t;
signal	addr	:std_logic_vector(15 downto 2);
signal	iobyteenb	:std_logic_vector(3 downto 0);
signal	iowdatb		:std_logic_vector(31 downto 0);

begin

	process(clk,rstn)
	variable nwait	:integer range 0 to 2;
	begin
		if(rstn='0')then
			state<=st_idle;
			rdval<='0';
			iord<='0';
			iowr<='0';
			iobyteenb<=(others=>'0');
			iowdatb<=(others=>'0');
			addr<=(others=>'0');
			iobusy<='0';
		elsif(clk' event and clk='1')then
			rdval<='0';
			case state is
			when st_idle =>
				if(cpurd='1')then
					state<=st_read;
					addr<=cpuaddr;
					iobyteenb<=cpubyteen;
					iord<='1';
					nwait:=1;
				elsif(cpuwr='1')then
					state<=st_write;
					addr<=cpuaddr;
					iobyteenb<=cpubyteen;
					iowdatb<=cpuwdat;
					iowr<='1';
					iobusy<='1';
				end if;
			when st_read =>
				if(nwait>0)then
					nwait:=nwait-1;
				elsif(iowait='0')then
					rdval<='1';
					iobusy<='1';
					state<=st_done;
				end if;
			when st_write =>
				if(nwait>0)then
					nwait:=nwait-1;
				elsif(iowait='0')then
					iowr<='0';
					iobusy<='0';
					state<=st_idle;
				end if;
			when st_done =>
				iord<='0';
				iowr<='0';
				iobusy<='0';
				state<=st_idle;
			when others =>
				state<=st_idle;
			end case;
		end if;
	end process;
	
	iobyteen<=iobyteenb;
	iowdat<=iowdatb;
	
	baddr(15 downto 2)<=addr(15 downto 2);
	baddr(1 downto 0)<=	"00" when iobyteenb="0001" else
								"01" when iobyteenb="0010" else
								"10" when iobyteenb="0100" else
								"11" when iobyteenb="1000" else
								"00" when iobyteenb="0011" else
								"00" when iobyteenb="0111" else
								"00" when iobyteenb="1111" else
								"10" when iobyteenb="1100" else
								"11";
	swaddr(15 downto 2)<=addr(15 downto 2);
	swaddr(1 downto 0)<=	"00" when iobyteenb="0011" else
								"00" when iobyteenb="0001" else
								"00" when iobyteenb="0010" else
								"10" when iobyteenb="1100" else
								"10" when iobyteenb="0100" else
								"10" when iobyteenb="1000" else
								"00" when iobyteenb="1111" else
								"01";
	
	dwaddr<=addr&"00";
	
	ioswdat<=	iowdatb(15 downto 0) when iobyteenb(1 downto 0)/="00" else
					iowdatb(31 downto 16) when iobyteenb(3 downto 2)/="00" else
					(others=>'0');
	
	iobwdat<=	iowdatb(7 downto 0) when iobyteenb="0001" else
					iowdatb(15 downto 8) when iobyteenb="0010" else
					iowdatb(23 downto 16) when iobyteenb="0100" else
					iowdatb(31 downto 24) when iobyteenb="1000" else
					(others=>'0');
	
	waitreq<=iowait;
	
end rtl;