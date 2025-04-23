LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	USE	IEEE.std_logic_arith.all;

entity anapal is
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(1 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	plt	:in std_logic_vector(1 downto 0);
	
	c8in	:in std_logic_vector(7 downto 0);
	c8red	:out std_logic_vector(7 downto 0);
	c8grn	:out std_logic_vector(7 downto 0);
	c8blu	:out std_logic_vector(7 downto 0);
	
	c41in		:in std_logic_vector(3 downto 0);
	c41red	:out std_logic_vector(3 downto 0);
	c41grn	:out std_logic_vector(3 downto 0);
	c41blu	:out std_logic_vector(3 downto 0);

	c42in		:in std_logic_vector(3 downto 0);
	c42red	:out std_logic_vector(3 downto 0);
	c42grn	:out std_logic_vector(3 downto 0);
	c42blu	:out std_logic_vector(3 downto 0);

	sclk		:in std_logic;
	vclk		:in std_logic;
	rstn		:in std_logic
);
end anapal;

architecture rtl of anapal is
subtype C8PAL_LAT_TYPE is std_logic_vector(7 downto 0); 
type C8PAL_LAT_ARRAY is array (natural range <>) of C8PAL_LAT_TYPE;
signal	C8RPAL,C8GPAL,C8BPAL	:C8PAL_LAT_ARRAY(0 to 255);

subtype C4PAL_LAT_TYPE is std_logic_vector(3 downto 0); 
type C4PAL_LAT_ARRAY is array (natural range <>) of C4PAL_LAT_TYPE;
signal	C41RPAL,C41GPAL,C41BPAL	:C4PAL_LAT_ARRAY(0 to 15);
signal	C42RPAL,C42GPAL,C42BPAL	:C4PAL_LAT_ARRAY(0 to 15);

signal	regaddr8	:integer range 0 to 255;
signal	regaddr4	:integer range 0 to 15;
signal	r0dat		:std_logic_vector(7 downto 0);
signal	r1dat		:std_logic_vector(7 downto 0);
signal	r2dat		:std_logic_vector(7 downto 0);
signal	r3dat		:std_logic_vector(7 downto 0);

signal	vidaddr8	:integer range 0 to 255;
signal	vidaddr41:integer range 0 to 15;
signal	vidaddr42:integer range 0 to 15;

begin


	process(sclk,rstn)begin
		if(rstn='0')then
			regaddr8<=0;
			regaddr4<=0;
		elsif(sclk' event and sclk='1')then
			if(cs='1' and wr='1')then
				case addr is
				when "00" =>
					regaddr8<=conv_integer(wdat);
					regaddr4<=conv_integer(wdat(3 downto 0));
				when "01" =>
					case plt is
					when "00" =>
						C41BPAL(regaddr4)<=wdat(7 downto 4);
					when "01" =>
						C42BPAL(regaddr4)<=wdat(7 downto 4);
					when others =>
						C8BPAL(regaddr8)<=wdat;
					end case;
				when "10" =>
					case plt is
					when "00" =>
						C41RPAL(regaddr4)<=wdat(7 downto 4);
					when "01" =>
						C42RPAL(regaddr4)<=wdat(7 downto 4);
					when others =>
						C8RPAL(regaddr8)<=wdat;
					end case;
				when "11" =>
					case plt is
					when "00" =>
						C41GPAL(regaddr4)<=wdat(7 downto 4);
					when "01" =>
						C42GPAL(regaddr4)<=wdat(7 downto 4);
					when others =>
						C8GPAL(regaddr8)<=wdat;
					end case;
				when others =>
				end case;
			end if;
		end if;
	end process;
	r0dat<=	"0000" & conv_std_logic_vector(regaddr4,4) when plt="00" or plt="01" else
				conv_std_logic_vector(regaddr8,8);
	r1dat<=	C41BPAL(regaddr4) & "0000" when plt="00" else
				C42BPAL(regaddr4) & "0000" when plt="01" else
				C8BPAL(regaddr8);	
	r2dat<=	C41RPAL(regaddr4) & "0000" when plt="00" else
				C42RPAL(regaddr4) & "0000" when plt="01" else
				C8RPAL(regaddr8);
	r3dat<=	C41GPAL(regaddr4) & "0000" when plt="00" else
				C42GPAL(regaddr4) & "0000" when plt="01" else
				C8GPAL(regaddr8);
	rdat<=	r0dat when addr="00" else
				r1dat when addr="01" else
				r2dat when addr="10" else
				r3dat when addr="11" else
				(others=>'0');
	
	doe<=cs and rd;
	
	process(vclk,rstn)begin
		if(rstn='0')then
			vidaddr8<=0;
			vidaddr41<=0;
			vidaddr42<=0;
		elsif(vclk' event and vclk='1')then
			vidaddr8<=conv_integer(c8in);
			vidaddr41<=conv_integer(c41in);
			vidaddr42<=conv_integer(c42in);
		end if;
	end process;
	
	c8red<=C8RPAL(vidaddr8);
	c8grn<=C8GPAL(vidaddr8);
	c8blu<=C8BPAL(vidaddr8);

	c41red<=C41RPAL(vidaddr41);
	c41grn<=C41GPAL(vidaddr41);
	c41blu<=C41BPAL(vidaddr41);

	c42red<=C42RPAL(vidaddr42);
	c42grn<=C42GPAL(vidaddr42);
	c42blu<=C42BPAL(vidaddr42);

end rtl;