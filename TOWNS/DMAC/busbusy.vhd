LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity busbusy is
port(
	rdreq	:in std_logic;
	wrreq	:in std_logic;
	rdval	:in std_logic;
	ramwait	:in std_logic;
	
	busy	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end busbusy;

architecture rtl of busbusy is
type state_t is(
	st_idle,
	st_read1,
	st_read2,
	st_write1,
	st_write2
);
signal	state	:state_t;
begin
	process(clk,rstn)begin
		if(rstn='0')then
			state<=st_idle;
		elsif(clk' event and clk='1')then
			if(rdreq='1')then
				state<=st_read1;
			elsif(wrreq='1')then
				state<=st_write1;
			else
				case state is
				when st_read1 =>
					if(rdval='1')then
						state<=st_read2;
					end if;
				when st_read2 =>
					if(rdval='0')then
						state<=st_idle;
					end if;
				when st_write1 =>
					state<=st_write2;
				when st_write2 =>
					if(ramwait='0')then
						state<=st_idle;
					end if;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	busy<=
		'1' when rdreq='1' else
		'1' when wrreq='1' else
		rdval when state=st_read2 else
		ramwait when state=st_write2 else
		'0' when state=st_idle else
		'1';

end rtl;
