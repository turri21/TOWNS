LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cmosram is
port(
	mcs	:in std_logic;
	maddr	:in std_logic_vector(10 downto 0);
	mbsel	:in std_logic_vector(3 downto 0);
	mrd	:in std_logic;
	mwr	:in std_logic;
	mrdat	:out std_logic_vector(31 downto 0);
	mwdat	:in std_logic_vector(31 downto 0);
	mrval	:out std_logic;
	mwait	:out std_logic;
	
	iocs	:in std_logic;
	ioaddr:in std_logic_vector(9 downto 0);
	iobsel:in std_logic_vector(3 downto 0);
	iord	:in std_logic;
	iowr	:in std_logic;
	iordat:out std_logic_vector(31 downto 0);
	iodoe	:out std_logic;
	iowdat:in std_logic_vector(31 downto 0);
	iowait:out std_logic;
	
	app	:in std_logic_vector(1 to 3);
	hma	:in std_logic;
	emsmode:in std_logic;
	ems	:in std_logic_vector(5 downto 0);
	ramdisk:in std_logic_vector(5 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end cmosram;

architecture rtl of cmosram is
type state_t is(
	st_init,
	st_i0ce,
	st_i0d0,
	st_i159,
	st_i162,
	st_i165,
	st_i167,
	st_i16b,
	st_i16d,
	st_i16e,
	st_i1e7,
	st_idle,
	st_read,
	st_write
);
signal	istate:state_t;
signal	mstate:state_t;

signal	iaddr	:std_logic_vector(11 downto 0);
signal	iwdat	:std_logic_vector(15 downto 0);
signal	iwr	:std_logic;
signal	ibsel	:std_logic_vector(1 downto 0);
signal	irdat	:std_logic_vector(15 downto 0);
signal	mwrb	:std_logic;

component CMOS
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		byteena_a		: IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
		byteena_b		: IN STD_LOGIC_VECTOR (1 DOWNTO 0) :=  (OTHERS => '1');
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

begin
	process(clk,rstn)begin
		if(rstn='0')then
			istate<=st_init;
			iaddr<=(others=>'0');
			iwdat<=(others=>'0');
			ibsel<=(others=>'0');
			iowait<='1';
		elsif(clk' event and clk='1')then
			iwr<='0';
			case istate is
			when st_init =>
				istate<=st_idle;
				iowait<='0';
			when st_idle =>
				if(iocs='1' and iord='1')then
					iowait<='1';
					iaddr<="00" & ioaddr;
					ibsel<=iobsel(2) & iobsel(0);
					istate<=st_read;
				elsif(iocs='1' and iowr='1')then
					iowait<='1';
					iaddr<="00" & ioaddr;
					ibsel<=iobsel(2) & iobsel(0);
					iwdat<=iowdat(23 downto 16) & iowdat(7 downto 0);
					iwr<='1';
					istate<=st_write;
				end if;
			when st_read =>
				iowait<='0';
				istate<=st_idle;
			when st_write =>
				iowait<='0';
				istate<=st_idle;
			when others =>
				istate<=st_idle;
			end case;
		end if;
	end process;
	
	
	process(clk,rstn)begin
		if(rstn='0')then
			mstate<=st_idle;
		elsif(clk' event and clk='1')then
			mrval<='0';
			mwait<='0';
			case mstate is
			when st_idle =>
				if(mcs='1' and mrd='1')then
					mstate<=st_read;
				elsif(mcs='1' and mwr='1')then
					mwait<='1';
					mstate<=st_write;
				end if;
			when st_read =>
				mrval<='1';
				mstate<=st_idle;
			when st_write =>
				mstate<=st_idle;
			when others =>
				mstate<=st_idle;
			end case;
		end if;
	end process;
	
	iodoe<='1' when iocs='1' and iord='1' else '0';
	
	mwrb<='1' when mcs='1' and mwr='1' else '0';
	ram	:CMOS port map(
		address_a		=>maddr,
		address_b		=>iaddr,
		byteena_a		=>mbsel,
		byteena_b		=>ibsel,
		clock				=>clk,
		data_a			=>mwdat,
		data_b			=>iwdat,
		wren_a			=>mwrb,
		wren_b			=>iwr,
		q_a				=>mrdat,
		q_b				=>irdat
	);

	iordat<=x"4d" & irdat(15 downto 8) & x"4d" & irdat(7 downto 0);
	
end rtl;
					
					
			