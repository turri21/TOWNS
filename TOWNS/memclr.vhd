LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memclr	is
generic(
	ADDRWIDTH	:integer	:=25;
	COLSIZE		:integer	:=9
);
port(
	ADDR			:out std_logic_Vector(ADDRWIDTH-1 downto 0);
	WR				:out std_logic;
	WRDONE		:in std_logic;
	DONE			:out std_logic;
	
	clk			:in std_logic;
	rstn			:in std_logic
);
end memclr;

architecture rtl of memclr is
signal	curaddr	:std_logic_vector(ADDRWIDTH-1 downto 0);
signal	coladd	:std_logic_Vector(ADDRWIDTH-1 downto 0);
constant allzero	:std_logic_vector(ADDRWIDTH-1 downto 0)	:=(others=>'0');

type state_t is(
	st_init,
	st_busy,
	st_done
);
signal	state	:state_t;

begin
	coladd(ADDRWIDTH-1 downto COLSIZE+1)<=(others=>'0');
	coladd(COLSIZE)<='1';
	coladd(COLSIZE-1 downto 0)<=(others=>'0');
	
	process(clk,rstn)begin
		if(rstn='0')then
			DONE<='0';
			curaddr<=(others=>'0');
			WR<='0';
			state<=st_init;
		elsif(clk' event and clk='1')then
			WR<='0';
			case state is
			when st_init =>
				ADDR<=(others=>'0');
				curaddr<=coladd;
				WR<='1';
				state<=st_busy;
			when st_busy =>
				if(WRDONE='1')then
					if(curaddr=allzero)then
						DONE<='1';
						state<=st_done;
					else
						ADDR<=curaddr;
						curaddr<=curaddr+coladd;
						WR<='1';
					end if;
				end if;
			when others =>
			end case;
		end if;
	end process;
	
end rtl;

					