LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity kcgmemcont is
generic(
	addrlen	:integer	:=23
);
port(
	bus_rd	:in std_logic;
	bus_wr	:in std_logic;
	bus_done	:out std_logic;
	busclk	:in std_logic;
	
	mem_rd	:out std_logic;
	mem_wr	:out std_logic;
	mem_done	:in std_logic;
	memclk	:in std_logic;
	
	rstn		:in std_logic
);
end kcgmemcont;

architecture rtl of kcgmemcont is
type mstate_t is(
	mst_idle,
	mst_read,
	mst_write,
	mst_done
);
signal	mstate	:mstate_t;

type bstate_t is(
	bst_idle,
	bst_rwait,
	bst_read,
	bst_write,
	bst_ack
);
signal	bstate	:bstate_t;
signal	bdone,back		:std_logic;

signal	rx_wr		:std_logic;

begin
	
	process(memclk,rstn)
	variable	lrd,lwr	:std_logic;
	begin
		if(rstn='0')then
			mstate<=mst_idle;
			lrd:='0';
			lwr:='0';
			mem_rd<='0';
			mem_wr<='0';
			bdone<='0';
		elsif(memclk' event and memclk='1')then
			mem_rd<='0';
			mem_wr<='0';
			case mstate is
			when mst_idle =>
				if(lwr='1' and rx_wr='1')then
					mem_wr<='1';
					mstate<=mst_write;
				elsif(lrd='1' and bus_rd='1')then
					mem_rd<='1';
					mstate<=mst_read;
				end if;
			when mst_read =>
				if(mem_done='1')then
					bdone<='1';
					mstate<=mst_done;
				end if;
			when mst_write =>
				if(mem_done='1')then
					bdone<='1';
					mstate<=mst_done;
				end if;
			when mst_done =>
				if(back='1')then
					bdone<='0';
					mstate<=mst_idle;
				end if;
			when others =>
				mstate<=mst_idle;
			end case;
			lrd:=bus_rd;
			lwr:=rx_wr;
		end if;
	end process;
	
	process(busclk,rstn)begin
		if(rstn='0')then
			bstate<=bst_idle;
			back<='0';
			rx_wr<='0';
			bus_done<='0';
		elsif(busclk' event and busclk='1')then
			bus_done<='0';
			case bstate is
			when bst_idle =>
				if(bus_rd='1')then
					bstate<=bst_rwait;
				elsif(bus_wr='1')then
					rx_wr<='1';
					bstate<=bst_write;
				end if;
			when bst_rwait =>
				if(bdone='1')then
					back<='1';
					bstate<=bst_read;
				end if;
			when bst_read =>
				if(bdone='0')then
					back<='0';
					bus_done<='1';
					bstate<=bst_idle;
				end if;
			when bst_write =>
				if(bdone='1')then
					rx_wr<='0';
					back<='1';
					bstate<=bst_ack;
				end if;
			when bst_ack =>
				if(bdone='0')then
					back<='0';
					bus_done<='1';
					bstate<=bst_idle;
				end if;
			when others=>
				bstate<=bst_idle;
			end case;
		end if;
	end process;
	
end rtl;
