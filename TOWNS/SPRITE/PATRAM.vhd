LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PATRAM is
port(
	addr	:in std_logic_vector(14 downto 0);
	blen	:in std_logic_vector(2 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rdat	:out std_logic_vector(31 downto 0);
	rval	:out std_logic;
	wdat	:in std_logic_vector(31 downto 0);
	
	index	:in std_logic_vector(9 downto 0);
	posX	:out std_logic_vector(15 downto 0);
	posY	:out std_logic_vector(15 downto 0);
	attr	:out std_logic_vector(15 downto 0);
	ctable	:out std_logic_vector(15 downto 0);
	
	ctno	:in std_logic_vector(7 downto 0);
	cno		:in std_logic_vector(3 downto 0);
	palout	:out std_logic_Vector(15 downto 0);
	
	paddr	:in std_logic_vector(14 downto 0);
	pdat	:out std_logic_vector(31 downto 0);
	
	clk	:in std_logic;
	vclk	:in std_logic;
	rstn	:in std_logic
);
end PATRAM;

architecture rtl of PATRAM is
subtype DAT_LAT_TYPE is std_logic_vector(7 downto 0); 
type DAT_LAT_ARRAY is array (natural range <>) of DAT_LAT_TYPE; 
signal	IRAM0,IRAM1,IRAM2,IRAM3,IRAM4,IRAM5,IRAM6,IRAM7	:DAT_LAT_ARRAY(0 to 1023);
signal	CRAM0,CRAM1,CRAM2,CRAM3	:DAT_LAT_ARRAY(0 to 2047);
signal	PRAM0,PRAM1,PRAM2,PRAM3	:DAT_LAT_ARRAY(0 to (2**15)-1);

signal	bcount	:integer range 0 to 7;
signal	ipaddr	:integer range 0 to (2**15)-1;
signal	iaddr		:integer range 0 to (2**15)-1;

signal	iiaddr	:integer range 0 to 1023;
signal	caddr	:std_logic_vector(11 downto 0);
signal	csel	:std_logic;
signal	icaddr	:integer range 0 to 2047;
type state_t is(
	st_idle,
	st_read,
	st_write
);
signal	state	:state_t;
begin
	caddr<=ctno & cno;
	process(vclk,rstn)begin
		if(rstn='0')then
			ipaddr<=0;
			iiaddr<=0;
			icaddr<=0;
		elsif(vclk' event and vclk='1')then
			ipaddr<=conv_integer(paddr);
			iiaddr<=conv_integer(index);
			icaddr<=conv_integer(caddr(11 downto 1));
			csel<=caddr(0);
		end if;
	end process;
	posX<=IRAM1(iiaddr) & IRAM0(iiaddr);
	posY<=IRAM3(iiaddr) & IRAM2(iiaddr);
	attr<=IRAM5(iiaddr) & IRAM4(iiaddr);
	ctable<=IRAM7(iiaddr) & IRAM6(iiaddr);
	
	palout<=CRAM1(icaddr) & CRAM0(icaddr)	when csel='0' else
			CRAM3(icaddr) & CRAM2(icaddr);
	pdat<=PRAM3(ipaddr) & PRAM2(ipaddr) & PRAM1(ipaddr) & PRAM0(ipaddr);
	
	process(clk,rstn)
	variable	waddr	:integer range 0 to (2**15)-1;
	variable	wiaddr	:integer range 0 to 1023;
	variable	wcaddr	:integer range 0 to 2047;
	variable	xaddr	:std_logic_vector(14 downto 0);
	begin
		if(rstn='0')then
			iaddr<=0;
			state<=st_idle;
		elsif(clk' event and clk='1')then
			if(rd='1')then
				state<=st_read;
				bcount<=conv_integer(blen);
				iaddr<=conv_integer(addr);
			elsif(wr='1')then
				state<=st_write;
				xaddr:=addr;
				bcount<=conv_integer(blen);
				iaddr<=conv_integer(addr);
				waddr:=conv_integer(addr);
				if(bsel(0)='1')then
					PRAM0(waddr)<=wdat(7 downto 0);
				end if;
				if(bsel(1)='1')then
					PRAM1(waddr)<=wdat(15 downto 8);
				end if;
				if(bsel(2)='1')then
					PRAM2(waddr)<=wdat(23 downto 16);
				end if;
				if(bsel(3)='1')then
					PRAM3(waddr)<=wdat(31 downto 24);
				end if;
				if(waddr<2048)then
					wiaddr:=conv_integer(addr(10 downto 1));
					if(addr(0)='0')then
						if(bsel(0)='1')then
							IRAM0(wiaddr)<=wdat(7 downto 0);
						end if;
						if(bsel(1)='1')then
							IRAM1(wiaddr)<=wdat(15 downto 8);
						end if;
						if(bsel(2)='1')then
							IRAM2(wiaddr)<=wdat(23 downto 16);
						end if;
						if(bsel(3)='1')then
							IRAM3(wiaddr)<=wdat(31 downto 24);
						end if;
					else
						if(bsel(0)='1')then
							IRAM4(wiaddr)<=wdat(7 downto 0);
						end if;
						if(bsel(1)='1')then
							IRAM5(wiaddr)<=wdat(15 downto 8);
						end if;
						if(bsel(2)='1')then
							IRAM6(wiaddr)<=wdat(23 downto 16);
						end if;
						if(bsel(3)='1')then
							IRAM7(wiaddr)<=wdat(31 downto 24);
						end if;
					end if;
				elsif(waddr<4096)then
					wcaddr:=conv_integer(addr(10 downto 0));
					if(bsel(0)='1')then
						CRAM0(wiaddr)<=wdat(7 downto 0);
					end if;
					if(bsel(1)='1')then
						CRAM1(wiaddr)<=wdat(15 downto 8);
					end if;
					if(bsel(2)='1')then
						CRAM2(wiaddr)<=wdat(23 downto 16);
					end if;
					if(bsel(3)='1')then
						CRAM3(wiaddr)<=wdat(31 downto 24);
					end if;
				end if;
			elsif(bcount>1)then
				bcount<=bcount-1;
				iaddr<=iaddr+1;
				if(state=st_write)then
					waddr:=iaddr+1;
					if(bsel(0)='1')then
						PRAM0(waddr)<=wdat(7 downto 0);
					end if;
					if(bsel(1)='1')then
						PRAM1(waddr)<=wdat(15 downto 8);
					end if;
					if(bsel(2)='1')then
						PRAM2(waddr)<=wdat(23 downto 16);
					end if;
					if(bsel(3)='1')then
						PRAM3(waddr)<=wdat(31 downto 24);
					end if;
					xaddr:=xaddr+1;
					if(waddr<2048)then
						wiaddr:=conv_integer(xaddr(10 downto 1));
						if(xaddr(0)='0')then
							if(bsel(0)='1')then
								IRAM0(wiaddr)<=wdat(7 downto 0);
							end if;
							if(bsel(1)='1')then
								IRAM1(wiaddr)<=wdat(15 downto 8);
							end if;
							if(bsel(2)='1')then
								IRAM2(wiaddr)<=wdat(23 downto 16);
							end if;
							if(bsel(3)='1')then
								IRAM3(wiaddr)<=wdat(31 downto 24);
							end if;
						else
							if(bsel(0)='1')then
								IRAM4(wiaddr)<=wdat(7 downto 0);
							end if;
							if(bsel(1)='1')then
								IRAM5(wiaddr)<=wdat(15 downto 8);
							end if;
							if(bsel(2)='1')then
								IRAM6(wiaddr)<=wdat(23 downto 16);
							end if;
							if(bsel(3)='1')then
								IRAM7(wiaddr)<=wdat(31 downto 24);
							end if;
						end if;
					elsif(waddr<4096)then
						wcaddr:=conv_integer(xaddr(10 downto 0));
						if(bsel(0)='1')then
							CRAM0(wiaddr)<=wdat(7 downto 0);
						end if;
						if(bsel(1)='1')then
							CRAM1(wiaddr)<=wdat(15 downto 8);
						end if;
						if(bsel(2)='1')then
							CRAM2(wiaddr)<=wdat(23 downto 16);
						end if;
						if(bsel(3)='1')then
							CRAM3(wiaddr)<=wdat(31 downto 24);
						end if;
					end if;
				end if;
			else
				state<=st_idle;
			end if;
		end if;
	end process;
	
	rdat<=PRAM3(iaddr) & PRAM2(iaddr) & PRAM1(iaddr) & PRAM0(iaddr);
	
	process(clk,rstn)begin
		if(rstn='0')then
			rval<='0';
		elsif(clk' event and clk='1')then
			if(state=st_read)then
				rval<='1';
			else
				rval<='0';
			end if;
		end if;
	end process;
	
end rtl;

	