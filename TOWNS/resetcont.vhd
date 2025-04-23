library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity resetcont is
port(
	cs		:in std_logic;
	addr	:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	shutdown	:in std_logic;
	wrprot	:out std_logic;
	poff0		:out std_logic;
	poff2		:out std_logic;
	rst		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end resetcont;


architecture rtl of resetcont is
signal	soft	:std_logic;
signal	sdown	:std_logic;
begin

	process(clk,rstn)
	variable lrd,vrd	:std_logic;
	begin
		if(rstn='0')then
			soft<='0';
			sdown<='0';
			wrprot<='0';
			poff0<='0';
			poff2<='0';
			rst<='0';
		elsif(clk' event and clk='1')then
			poff0<='0';
			poff2<='0';
			rst<='0';
			if(cs='1' and rd='1' and addr='0')then
				vrd:='1';
			else
				vrd:='0';
			end if;
			if(shutdown='1')then
				sdown<='1';
			end if;
			if(cs='1' and wr='1')then
				case addr is
				when '0' =>
					if(wdat(0)='1')then
						soft<='1';
					end if;
					rst<=wdat(0);
					poff0<=wdat(6);
					wrprot<=wdat(7);
				when '1' =>
					poff2<=wdat(6);
				end case;
			end if;
			if(lrd='1' and vrd='0')then
				soft<='0';
				sdown<='0';
			end if;
			lrd:=vrd;
		end if;
	end process;
	
	rdat<="000000" & sdown & soft;
	doe<='1' when cs='1' and rd='1' and addr='0' else '0';

end rtl;

	
	