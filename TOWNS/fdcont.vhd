LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fdcont is
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(2 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	ready	:in std_logic;
	irqmsk:out std_logic;
	dden	:out std_logic;
	hdsel	:out std_logic;
	motor	:out std_logic;
	clksel:out std_logic;
	dsel	:out std_logic_vector(3 downto 0);
	inuse	:out std_logic;
	speed	:out std_logic;
	drvchg:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end fdcont;

architecture rtl of fdcont is
signal	rdrvchg	:std_logic;
begin
	process(clk,rstn)begin
		if(rstn='0')then
			irqmsk<='0';
			dden<='0';
			motor<='0';
			clksel<='0';
			dsel<=(others=>'0');
			inuse<='0';
			speed<='0';
			rdrvchg<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				case addr is
				when "000" =>
					clksel<=wdat(5);
					motor<=wdat(4);
					hdsel<=wdat(2);
					dden<=wdat(1);
					irqmsk<=wdat(0);
				when "100" =>
					speed<=wdat(6);
					inuse<=wdat(4);
					dsel<=wdat(3 downto 0);
				when "110" =>
					rdrvchg<=wdat(0);
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	rdat<=	"000001" & ready & '1' when addr="000" else
				"0000000" & rdrvchg when addr="110" else
				(others=>'0');
	doe<='1' when cs='1' and rd='1' else '0';
	drvchg<=rdrvchg;
end rtl;

	
