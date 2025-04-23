LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use	work.MEM_ADDR_pkg.all;

entity rkanjcg	is
generic(
	awidth	:integer	:=25
);
port(
	mcs	:in std_logic;
	mbsel	:in std_logic_vector(3 downto 0);
	mrd	:in std_logic;
	mwr	:in std_logic;
	mrdat	:out std_logic_vector(31 downto 0);
	mwdat	:in std_logic_vector(31 downto 0);
	mrval	:out std_logic;
	mwait	:out std_logic;
	
	iocs	:in std_logic;
	iobsel:in std_logic_vector(3 downto 0);
	iord	:in std_logic;
	iowr	:in std_logic;
	iordat	:out std_logic_vector(31 downto 0);
	iowdat	:in std_logic_vector(31 downto 0);
	iodoe		:out std_logic;
	iowait	:out std_logic;
	
	ramaddr	:out std_logic_vector(awidth-1 downto 0);
	ramrd		:out std_logic;
	ramwr		:out std_logic;
	rambsel	:out std_logic_vector(1 downto 0);
	ramrdat	:in std_logic_vector(15 downto 0);
	ramwdat	:out std_logic_vector(15 downto 0);
	ramdone	:in std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end rkanjcg;

architecture rtl of rkanjcg is
signal	jiscode	:std_logic_vector(15 downto 0);
signal	romcode	:std_logic_vector(12 downto 0);
signal	linenum	:std_logic_vector(3 downto 0);
signal	currdaddr:std_logic_vector(16 downto 0);

type state_t is(
	st_idle,
	st_read_mem,
	st_read_io,
	st_write_mem,
	st_write_io
);
signal	state	:state_t;

component knjjis2rom
port(
	jiscode	:in std_logic_vector(15 downto 0);
	
	romcode	:out std_logic_vector(12 downto 0);
	clk		:in std_logic
);
end component;

begin
	process(clk,rstn)
	begin
		if(rstn='0')then
			mwait<='0';
			iowait<='0';
			mrval<='0';
			jiscode<=(others=>'0');
			linenum<=(others=>'0');
			state<=st_idle;
			rambsel<=(others=>'0');
			ramwr<='0';
			ramrd<='0';
			mrdat<=(others=>'0');
			iordat<=(others=>'0');
			ramwdat<=(others=>'0');
			currdaddr<=(others=>'0');
		elsif(clk' event and clk='1')then
			ramwr<='0';
			ramrd<='0';
			mrval<='0';
			case state is
			when st_idle =>
				if(mcs='1' and mwr='1')then
					if(mbsel(0)='1')then
						jiscode(15 downto 8)<=mwdat(7 downto 0);
					end if;
					if(mbsel(1)='1')then
						jiscode(7 downto 0)<=mwdat(15 downto 8);
						linenum<=(others=>'0');
					end if;
					if(mbsel(2)='1' or mbsel(3)='1')then
						rambsel<=mbsel(3 downto 2);
						ramwdat<=mwdat(31 downto 16);
						ramwr<='1';
						mwait<='1';
						iowait<='1';
						state<=st_write_mem;
					end if;
				elsif(mcs='1' and mrd='1')then
					if(mbsel(0)='1')then
						mrdat(7 downto 0)<=x"80";
					end if;
					if(mbsel(2)='1' or mbsel(3)='1')then
						if(currdaddr=(romcode & linenum))then
							if(mbsel(3)='1')then
								linenum<=linenum+1;
							end if;
							mrval<='1';
						else
							mrval<='0';
							mwait<='1';
							iowait<='1';
							ramrd<='1';
							state<=st_read_mem;
						end if;
					end if;
				end if;
				if(iocs='1' and iowr='1')then
					if(iobsel(0)='1')then
						jiscode(15 downto 8)<=iowdat(7 downto 0);
					end if;
					if(iobsel(1)='1')then
						jiscode(7 downto 0)<=iowdat(15 downto 8);
						linenum<=(others=>'0');
					end if;
					if(iobsel(2)='1' or iobsel(3)='1')then
						rambsel<=iobsel(3 downto 2);
						ramwdat<=iowdat(31 downto 16);
						ramwr<='1';
						mwait<='1';
						iowait<='1';
						state<=st_write_io;
					end if;
				elsif(iocs='1' and iord='1')then
					if(iobsel(0)='1')then
						iordat(7 downto 0)<=x"80";
					end if;
					if(iobsel(2)='1' or iobsel(3)='1')then
						if(currdaddr=(romcode & linenum))then
							if(iobsel(3)='1')then
								linenum<=linenum+1;
							end if;
							state<=st_idle;
						else
							mwait<='1';
							iowait<='1';
							ramrd<='1';
							state<=st_read_io;
						end if;
					end if;
				end if;
			when st_read_mem =>
				if(ramdone='1')then
					mrdat(31 downto 16)<=ramrdat;
					iordat(31 downto 16)<=ramrdat;
					mrval<='1';
					mwait<='0';
					iowait<='0';
					currdaddr<=romcode & linenum;
					if(mbsel(3)='1')then
						linenum<=linenum+1;
					end if;
					state<=st_idle;
				end if;
			when st_read_io =>
				if(ramdone='1')then
					mrdat(31 downto 16)<=ramrdat;
					iordat(31 downto 16)<=ramrdat;
					mwait<='0';
					iowait<='0';
					currdaddr<=romcode & linenum;
					if(iobsel(3)='1')then
						linenum<=linenum+1;
					end if;
					state<=st_idle;
				end if;
			when st_write_mem =>
				if(ramdone='1')then
					mwait<='0';
					iowait<='0';
					if(mbsel(3)='1')then
						linenum<=linenum+1;
					end if;
					state<=st_idle;
				end if;
			when st_write_io =>
				if(ramdone='1')then
					mwait<='0';
					iowait<='0';
					if(iobsel(3)='1')then
						linenum<=linenum+1;
					end if;
					state<=st_idle;
				end if;
			when others =>
				state<=st_idle;
			end case;
		end if;
	end process;
					
	ramaddr<=RAM_FNT(awidth-1 downto 17) & romcode & linenum;
	iodoe<='1' when iocs='1' and iord='1' else '0';
	
	tbl	:knjjis2rom port map(jiscode,romcode,clk);
	
end rtl;
						