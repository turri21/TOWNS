library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity atarimouse is
generic(
	CLKFREQ	:integer	:=20000;	--kHz
	TOUTLEN	:integer	:=150		--usec
);
port(
	PADOUT	:out std_logic_vector(5 downto 0);
	STROBE	:in std_logic;
	
	Xdat		:in std_logic_vector(9 downto 0);
	Ydat		:in std_logic_vector(9 downto 0);
	SWdat		:in std_logic_Vector(1 downto 0);
	clear		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end atarimouse;

architecture rtl of atarimouse is
signal	Xlat	:std_logic_vector(7 downto 0);
signal	Ylat	:std_logic_vector(7 downto 0);
type state_t is(
	st_IDLE,
	st_T1,
	st_T2,
	st_T3,
	st_T4,
	st_T5
);
signal	state	:state_t;
constant TOlen	:integer	:=TOUTLEN*CLKFREQ/1000;
signal	TOcount	:integer range 0 to TOlen-1;
signal	sSTROBE	:std_logic;

begin

	process(clk)begin
		if(clk' event and clk='1')then
			sSTROBE<=STROBE;
		end if;
	end process;

	process(clk,rstn)begin
		if(rstn='0')then
			state<=st_IDLE;
			Xlat<=(others=>'0');
			Ylat<=(others=>'0');
			TOcount<=0;
			clear<='0';
		elsif(clk' event and clk='1')then
			clear<='0';
			case state is
			when st_IDLE =>
				if(sSTROBE='1')then
					case Xdat(9 downto 7)is
					when "000" =>
						if(Xdat="0000000000")then
							Xlat<=x"00";
						elsif(Xdat="0001111111")then
							Xlat<=x"81";
						else
							Xlat<=x"00"-Xdat(7 downto 0);
						end if;
					when "001" | "010" | "011"=>
						Xlat<=x"80";
					when "111" =>
						if(Xdat="1110000001")then
							Xlat<=x"7f";
						elsif(Xdat="1110000000")then
							Xlat<=x"7f";
						else
							Xlat<=x"00"-Xdat(7 downto 0);
						end if;
					when "110" | "101" | "100" =>
						Xlat<=x"7f";
					when others =>
						Xlat<=x"00";
					end case;
					
					case Ydat(9 downto 7)is
					when "000" =>
						if(Ydat="0000000000")then
							Ylat<=x"00";
						elsif(Ydat="0001111111")then
							Ylat<=x"81";
						else
							Ylat<=x"00"-Ydat(7 downto 0);
						end if;
					when "001" | "010" | "011"=>
						Xlat<=x"80";
					when "111" =>
						if(Ydat="1110000001")then
							Ylat<=x"7f";
						elsif(Ydat="1110000000")then
							Ylat<=x"7f";
						else
							Ylat<=x"00"-Ydat(7 downto 0);
						end if;
					when "110" | "101" | "100" =>
						Ylat<=x"7f";
					when others =>
						Ylat<=x"00";
					end case;
					clear<='1';
					state<=st_T1;
				end if;
			when st_T1 =>
				PADOUT(3 downto 0)<=Xlat(7 downto 4);
				if(sSTROBE='0')then
					PADOUT(3 downto 0)<=Xlat(3 downto 0);
					state<=st_T2;
					TOcount<=TOlen-1;
				end if;
			when st_T2 =>
				if(TOcount=0)then
					state<=st_IDLE;
				else
					TOcount<=TOcount-1;
					if(sSTROBE='1')then
						PADOUT(3 downto 0)<=Ylat(7 downto 4);
						state<=st_T3;
					end if;
				end if;
			when st_T3 =>
				if(sSTROBE='0')then
					PADOUT(3 downto 0)<=Ylat(3 downto 0);
					TOcount<=TOlen-1;
					state<=st_T4;
				end if;
			when st_T4 =>
				if(TOcount=0)then
					state<=st_IDLE;
				else
					TOCount<=TOCount-1;
					if(sSTROBE='1')then
						PADOUT(3 downto 0)<=(others=>'0');
						state<=st_T5;
					end if;
				end if;
			when st_T5 =>
				if(sSTROBE='0')then
					TOcount<=TOlen-1;
					state<=st_T4;
				end if;
			when others =>
				state<=st_IDLE;
			end case;
		end if;
	end process;
	
	PADOUT(5 downto 4)<=not swdat;
end rtl;

					
					