LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity timerint is
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rddat	:out std_logic_vector(7 downto 0);
	wrdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	snden	:out std_logic;
	
	tout0	:in std_logic;
	tout1	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end timerint;

architecture rtl of timerint is
signal inten	:std_logic_vector(1 downto 0);
signal int0		:std_logic;
signal ltout0	:std_logic;
signal sndenb	:std_logic;

begin
	process(clk,rstn)begin
		if(rstn='0')then
			inten<=(others=>'0');
			sndenb<='0';
			int0<='0';
			ltout0<='0';
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				inten<=wrdat(1 downto 0);
				sndenb<=wrdat(2);
				if(wrdat(7)='1')then
					int0<='0';
				end if;
			end if;
			if(tout0='1' and ltout0='0')then
				int0<='1';
			end if;
			ltout0<=tout0;
		end if;
	end process;
	
	snden<=sndenb;
	
	int<=	'1' when tout1='1' and inten(1)='1' else
			'1' when int0='1' and inten(0)='1' else
			'0';
	rddat<=	"000" & sndenb & inten & tout1 & int0;
	doe<=cs and rd;

end rtl;