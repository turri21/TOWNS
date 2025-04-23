LIBRARY	IEEE,work;
USE	IEEE.STD_LOGIC_1164.ALL;
USE	IEEE.STD_LOGIC_ARITH.ALL;
USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PCMREG is
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	
	chsel	:in std_logic_vector(2 downto 0);
	env	:out std_logic_vector(7 downto 0);
	panL	:out std_logic_vector(3 downto 0);
	panR	:out std_logic_vector(3 downto 0);
	FD		:out std_logic_vector(15 downto 0);
	LS		:out std_logic_vector(15 downto 0);
	ST		:out std_logic_vector(7 downto 0);
	WB		:out std_logic_vector(3 downto 0);
	ONOFF	:out std_logic;
	CHON	:out std_logic_vector(7 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end PCMREG;

architecture rtl of PCMREG is
signal	ichsel	:integer range 0 to 7;
subtype byte_type is std_logic_vector(7 downto 0);
type byte_array is array(natural range <>)of byte_type;
signal	env_array	:byte_array(0 to 7);
signal	pan_array	:byte_array(0 to 7);
signal	FDH_array,FDL_array	:byte_array(0 to 7);
signal	LSH_array,LSL_array	:byte_array(0 to 7);
signal	ST_array		:byte_array(0 to 7);
signal	regsel	:integer range 0 to 7;
begin

	process(clk,rstn)begin
		if(rstn='0')then
			ichsel<=0;
			regsel<=0;
			WB<=(others=>'0');
			ONOFF<='0';
			CHON<=(others=>'0');
		elsif(clk' event and clk='1')then
			ichsel<=conv_integer(chsel);
			if(cs='1' and wr='1')then
				case addr is
				when x"0" =>
					env_array(regsel)<=wdat;
				when x"1" =>
					pan_array(regsel)<=wdat;
				when x"2" =>
					FDL_array(regsel)<=wdat;
				when x"3" =>
					FDH_array(regsel)<=wdat;
				when x"4" =>
					LSL_array(regsel)<=wdat;
				when x"5"=>
					LSH_array(regsel)<=wdat;
				when x"6" =>
					ST_array(regsel)<=wdat;
				when x"7" =>
					if(wdat(6)='0')then
						WB<=wdat(3 downto 0);
					else
						regsel<=conv_integer(wdat(2 downto 0));
					end if;
					ONOFF<=wdat(7);
				when x"8" =>
					CHON<=wdat;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	env<=env_array(ichsel);
	panR<=pan_array(ichsel)(7 downto 4);
	panL<=pan_array(ichsel)(3 downto 0);
	FD<=FDH_array(ichsel) & FDL_array(ichsel);
	LS<=LSH_array(ichsel) & LSL_array(ichsel);
	ST<=ST_array(ichsel);
end rtl;
