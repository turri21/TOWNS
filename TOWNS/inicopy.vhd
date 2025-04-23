library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity inicopy is
generic(
	AWIDTH	:integer	:=20
);
port(
	ini_en	:in std_logic;
	ini_addr	:in std_logic_Vector(AWIDTH-1 downto 0);
	ini_oe	:in std_logic;
	ini_wdat	:in std_logic_vector(7 downto 0);
	ini_wr	:in std_logic;
	ini_ack	:out std_logic;
	ini_done	:in std_logic;

	wraddr	:out std_logic_vector(AWIDTH-1 downto 2);
	wdat		:out std_logic_vector(31 downto 0);
	aen		:out std_logic;
	wr			:out std_logic;
	ack		:in std_logic;
	done		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end inicopy;

architecture rtl of inicopy is
type state_t is(
	st_read,
	st_write,
	st_wait
);
signal	state	:state_t;

begin

	aen<=ini_oe;
	wraddr<=ini_addr(AWIDTH-1 downto 2);
	process(clk,rstn)begin
		if(rstn='0')then
			wdat<=(others=>'0');
			state<=st_read;
		elsif(clk' event and clk='1')then
			wr<='0';
			ini_ack<='0';
			case state is
			when st_read =>
				if(ini_en='1' and ini_wr='1')then
					case ini_addr(1 downto 0) is
					when "00" =>
						wdat(7 downto 0)<=ini_wdat;
						ini_ack<='1';
					when "01" =>
						wdat(15 downto 8)<=ini_wdat;
						ini_ack<='1';
					when "10" =>
						wdat(23 downto 16)<=ini_wdat;
						ini_ack<='1';
					when "11" =>
						wdat(31 downto 24)<=ini_wdat;
						wr<='1';
						state<=st_write;
					end case;
				end if;
			when st_write =>
				if(ack='1')then
					ini_ack<='1';
					state<=st_wait;
				end if;
			when st_wait =>
				if(ini_wr='0')then
					state<=st_read;
				end if;
			end case;
		end if;
	end process;
	done<=ini_done;

end rtl;

			