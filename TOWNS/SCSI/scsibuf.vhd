library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity scsibuf is
generic(
	sectwidth	:integer	:=512
);
port(
	indisk	:out std_logic;
	capacity	:out std_logic_vector(63 downto 0);
	lba		:in std_logic_vector(31 downto 0);
	rdreq		:in std_logic;
	wrreq		:in std_logic;
	syncreq	:in std_logic;
	sectaddr	:in std_logic_vector(sectwidth-1 downto 0);
	rddat		:out std_logic_vector(7 downto 0);
	wrdat		:in std_logic_vector(7 downto 0);
	sectbusy	:out std_logic;
	
	mist_mounted	:in std_logic;
	mist_readonly	:in std_logic;
	mist_imgsize	:in std_logic_vector(63 downto 0);
	mist_lba			:out std_logic_vector(31 downto 0);
	mist_rd			:out std_logic;
	mist_wr			:out std_logic;
	mist_ack			:in std_logic;
	mist_buffaddr	:in std_logic_vector(sectwidth-1 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffdin	:out std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;
	
	mist_busyout	:out std_logic;
	mist_busyin		:in std_logic;

	clk	:in std_logic;
	rstn	:in std_logic
);
end scsibuf;

architecture rtl of scsibuf is
constant sectsize	:integer	:=2**sectwidth;
signal	curlba	:std_logic_vector(31 downto 0);
signal	wrote		:std_logic;
signal	indiskb	:std_logic;
signal	sectwr	:std_logic;
signal	rdonly	:std_logic;
type state_t is(
	st_idle,
	st_rwritep,
	st_rwrite,
	st_rwrite1,
	st_readp,
	st_read,
	st_read1,
	st_writep,
	st_write,
	st_write1,
	st_syncp,
	st_sync,
	st_sync1
);
signal	state	:state_t;
subtype DAT_LAT_TYPE is std_logic_vector(7 downto 0); 
type DAT_LAT_ARRAY is array (natural range <>) of DAT_LAT_TYPE; 
signal	RAM	:DAT_LAT_ARRAY(0 to sectsize-1);
signal	mist_addr	:integer range 0 to sectsize-1;
signal	if_addr		:integer range 0 to sectsize-1;

begin

	process(clk,rstn)begin
		if(rstn='0')then
			sectbusy<='0';
			mist_lba<=(others=>'0');
			sectwr<='0';
			mist_busyout<='0';
			mist_rd<='0';
			mist_Wr<='0';
			state<=st_idle;
		elsif(clk' event and clk='1')then
			sectwr<='0';
			if(mist_mounted='1')then
				curlba<=(others=>'1');
				if(mist_imgsize=x"00000000")then
					indiskb<='0';
					capacity<=(others=>'0');
					rdonly<='1';
				else
					indiskb<='1';
					capacity<=mist_imgsize;
					rdonly<=mist_readonly;
				end if;
			end if;
			case state is
			when st_idle =>
				mist_rd<='0';
				mist_wr<='0';
				if(rdreq='1' and lba/=curlba and indiskb='1')then
					sectbusy<='1';
					if(wrote='1')then
						mist_lba<=curlba;
						if(mist_busyin='1')then
							state<=st_rwritep;
						else
							mist_wr<='1';
							mist_busyout<='1';
							state<=st_rwrite;
						end if;
					else
						mist_lba<=lba;
						curlba<=lba;
						if(mist_busyin='1')then
							state<=st_readp;
						else
							mist_rd<='1';
							mist_busyout<='1';
							state<=st_read;
						end if;
					end if;
				elsif(wrreq='1' and rdonly='0' and indiskb='1')then
					if(lba/=curlba and wrote='1')then
						sectbusy<='1';
						mist_lba<=curlba;
						if(mist_busyin='1')then
							state<=st_writep;
						else
							mist_wr<='1';
							mist_busyout<='1';
							state<=st_write;
						end if;
					else
						curlba<=lba;
						sectwr<='1';
						wrote<='1';
					end if;
				elsif(syncreq='1' and indiskb='1' and wrote='1')then
					sectbusy<='1';
					mist_lba<=curlba;
					if(mist_busyin='1')then
						state<=st_syncp;
					else
						mist_wr<='1';
						mist_busyout<='1';
						state<=st_sync;
					end if;
				end if;
			when st_rwritep =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_wr<='1';
					state<=st_rwrite;
				end if;
			when st_rwrite =>
				if(mist_ack='1')then
					mist_wr<='0';
					state<=st_rwrite1;
				end if;
			when st_rwrite1 =>
				if(mist_ack='0')then
					mist_lba<=lba;
					mist_rd<='1';
					state<=st_read;
				end if;
			when st_readp =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_rd<='1';
					state<=st_read;
				end if;
			when st_read =>
				if(mist_ack='1')then
					mist_rd<='0';
					state<=st_read1;
				end if;
			when st_read1 =>
				if(mist_ack='0')then
					sectbusy<='0';
					wrote<='0';
					mist_busyout<='0';
					curlba<=lba;
					state<=st_idle;
				end if;
			when st_writep =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_wr<='1';
					state<=st_write;
				end if;
			when st_write =>
				if(mist_ack='1')then
					mist_wr<='0';
					state<=st_write1;
				end if;
			when st_write1 =>
				if(mist_ack='0')then
					curlba<=lba;
					sectwr<='1';
					wrote<='1';
					sectbusy<='0';
					mist_busyout<='0';
					state<=st_idle;
				end if;
			when st_syncp =>
				if(mist_busyin='0')then
					mist_busyout<='1';
					mist_wr<='1';
					state<=st_sync;
				end if;
			when st_sync =>
				if(mist_ack='1')then
					mist_wr<='0';
					state<=st_sync1;
				end if;
			when st_sync1 =>
				if(mist_ack='0')then
					curlba<=lba;
					sectbusy<='0';
					mist_busyout<='0';
					wrote<='0';
					state<=st_idle;
				end if;
			when others =>
				state<=st_idle;
			end case;
		end if;
	end process;
	
	process(clk,rstn)
	variable vaddr	:integer range 0 to sectsize-1;
	begin
		if(rstn='0')then
			mist_addr<=0;
			if_addr<=0;
		elsif(clk' event and clk='1')then
			if(mist_buffwr='1')then
				vaddr:=conv_integer(mist_buffaddr);
				RAM(vaddr)<=mist_buffdout;
			elsif(sectwr='1')then
				vaddr:=conv_integer(sectaddr);
				RAM(vaddr)<=wrdat;
			end if;
			
			mist_addr<=conv_integer(mist_buffaddr);
			if_addr<=conv_integer(sectaddr);
		end if;
	end process;
	
	mist_buffdin<=RAM(mist_addr);
	rddat<=RAM(if_addr);
	indisk<=indiskb;

end rtl;					
				