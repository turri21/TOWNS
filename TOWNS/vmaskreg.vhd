LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vmaskreg is
port(
	cs		:in std_logic;
	wr		:in std_logic;
	rd		:in std_logic;
	bsel	:in std_logic_Vector(3 downto 0);
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	mbsel	:out std_logic_vector(3 downto 0);
	mask	:out std_logic_vector(31 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end vmaskreg;

architecture rtl of vmaskreg is
signal	mbuf	:std_logic_vector(31 downto 0);
signal	asel	:std_logic_vector(1 downto 0);
begin

	process(clk,rstn)begin
		if(rstn='0')then
			mbuf<=(others=>'1');
			asel<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				if(bsel(0)='1')then
					asel<=wdat(1 downto 0);
				end if;
				if(bsel(2)='1')then
					case asel is
					when "00" =>
						mbuf(7 downto 0)<=wdat(23 downto 16);
					when "01" =>
						mbuf(23 downto 16)<=wdat(23 downto 16);
					when others =>
					end case;
				end if;
				if(bsel(3)='1')then
					case asel is
					when "00" =>
						mbuf(15 downto 8)<=wdat(31 downto 24);
					when "01" =>
						mbuf(31 downto 24)<=wdat(31 downto 24);
					when others=>
					end case;
				end if;
			end if;
		end if;
	end process;
	
	mbsel(0)<='0' when mbuf( 7 downto  0)=x"00" else '1';
	mbsel(1)<='0' when mbuf(15 downto  8)=x"00" else '1';
	mbsel(2)<='0' when mbuf(23 downto 16)=x"00" else '1';
	mbsel(3)<='0' when mbuf(31 downto 24)=x"00" else '1';
	
	mask<=mbuf;
	
	doe<='1' when cs='1' and rd='1' else '0';
	rdat(15 downto 0)<=x"00" & "000000" & asel;
	rdat(31 downto 16)<=	mbuf(15 downto 0) when asel="00" else
								mbuf(31 downto 16) when asel="01" else
								(others=>'0');
	
	
end rtl;
	