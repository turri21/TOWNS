LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memcont is
generic(
	addrlen	:integer	:=23;
	colsize	:integer	:=9
);
port(
	bus_addr	:in std_logic_Vector(addrlen-2 downto 0);
	bus_rd	:in std_logic;
	bus_wr	:in std_logic;
	bus_rvrd		:in std_logic;
	bus_rvwr		:in std_logic;
	bus_rvrsel	:in std_logic_vector(1 downto 0);
	bus_rvwsel	:in std_logic_vector(3 downto 0);
	bus_blen	:in std_logic_Vector(2 downto 0);
	bus_byteen	:in std_logic_vector(3 downto 0);
	bus_rdat	:out std_logic_vector(31 downto 0);
	bus_wdat	:in std_logic_vector(31 downto 0);
	bus_rdval	:out std_logic;
	bus_wait	:out std_logic;
	busclk	:in std_logic;
	
	mem_addr	:out std_logic_Vector(addrlen-1 downto 0);
	mem_rd	:out std_logic;
	mem_wr	:out std_logic;
	mem_blen	:out std_logic_Vector(COLSIZE-1 downto 0);
	mem_byteen	:out std_logic_vector(1 downto 0);
	mem_rdval:in std_logic;
	mem_num	:in std_logic_vector(COLSIZE-1 downto 0);
	mem_wdata:out std_logic_vector(15 downto 0);
	mem_rdata:in std_logic_vector(15 downto 0);
	mem_done	:in std_logic;
	memclk	:in std_logic;
	
	rstn		:in std_logic
);
end memcont;

architecture rtl of memcont is
signal	wdat0l	:std_logic_vector(15 downto 0);
signal	wdat0h	:std_logic_vector(15 downto 0);
signal	wdat1l	:std_logic_vector(15 downto 0);
signal	wdat1h	:std_logic_vector(15 downto 0);
signal	wdat2l	:std_logic_vector(15 downto 0);
signal	wdat2h	:std_logic_vector(15 downto 0);
signal	wdat3l	:std_logic_vector(15 downto 0);
signal	wdat3h	:std_logic_vector(15 downto 0);
signal	wdat4l	:std_logic_vector(15 downto 0);
signal	wdat4h	:std_logic_vector(15 downto 0);
signal	wdat5l	:std_logic_vector(15 downto 0);
signal	wdat5h	:std_logic_vector(15 downto 0);
signal	wdat6l	:std_logic_vector(15 downto 0);
signal	wdat6h	:std_logic_vector(15 downto 0);
signal	wdat7l	:std_logic_vector(15 downto 0);
signal	wdat7h	:std_logic_vector(15 downto 0);

signal	wrben0l	:std_logic_vector(1 downto 0);
signal	wrben0h	:std_logic_vector(1 downto 0);
signal	wrben1l	:std_logic_vector(1 downto 0);
signal	wrben1h	:std_logic_vector(1 downto 0);
signal	wrben2l	:std_logic_vector(1 downto 0);
signal	wrben2h	:std_logic_vector(1 downto 0);
signal	wrben3l	:std_logic_vector(1 downto 0);
signal	wrben3h	:std_logic_vector(1 downto 0);
signal	wrben4l	:std_logic_vector(1 downto 0);
signal	wrben4h	:std_logic_vector(1 downto 0);
signal	wrben5l	:std_logic_vector(1 downto 0);
signal	wrben5h	:std_logic_vector(1 downto 0);
signal	wrben6l	:std_logic_vector(1 downto 0);
signal	wrben6h	:std_logic_vector(1 downto 0);
signal	wrben7l	:std_logic_vector(1 downto 0);
signal	wrben7h	:std_logic_vector(1 downto 0);

signal	rdat0l	:std_logic_vector(15 downto 0);
signal	rdat0h	:std_logic_vector(15 downto 0);
signal	rdat1l	:std_logic_vector(15 downto 0);
signal	rdat1h	:std_logic_vector(15 downto 0);
signal	rdat2l	:std_logic_vector(15 downto 0);
signal	rdat2h	:std_logic_vector(15 downto 0);
signal	rdat3l	:std_logic_vector(15 downto 0);
signal	rdat3h	:std_logic_vector(15 downto 0);
signal	rdat4l	:std_logic_vector(15 downto 0);
signal	rdat4h	:std_logic_vector(15 downto 0);
signal	rdat5l	:std_logic_vector(15 downto 0);
signal	rdat5h	:std_logic_vector(15 downto 0);
signal	rdat6l	:std_logic_vector(15 downto 0);
signal	rdat6h	:std_logic_vector(15 downto 0);
signal	rdat7l	:std_logic_vector(15 downto 0);
signal	rdat7h	:std_logic_vector(15 downto 0);

signal	bdone	:std_logic;
signal	back	:std_logic;
signal	blen1,blen2	:std_logic_vector(COLSIZE-1 downto 0);
signal	bcount	:std_logic_Vector(2 downto 0);
signal	inum	:std_logic_vector(COLSIZE-1 downto 0);

signal	iaddr	:std_logic_vector(COLSIZE-1 downto 0);
type mstate_t is(
	mst_idle,
	mst_read1,
	mst_read2,
	mst_write1,
	mst_write2,
	mst_done
);
signal	mstate	:mstate_t;

type bstate_t is(
	bst_idle,
	bst_rwait,
	bst_read,
	bst_wrecv,
	bst_rvwrecv,
	bst_write,
	bst_ack
);
signal	bstate	:bstate_t;
signal	rx_wr		:std_logic;
signal	rx_rvwr	:std_logic;
signal	wrnum		:std_logic_vector(COLSIZE-1 downto 0);
signal	wr_blen	:std_logic_vector(3 downto 0);
signal	wr_addr	:std_logic_Vector(addrlen-2 downto 0);
signal	wr_byteen:std_logic_vector(1 downto 0);
signal	wr_rvsel	:std_logic_vector(3 downto 0);
signal	wrinum	:integer range 0 to 3;
constant allzero	:std_logic_vector(COLSIZE-1 downto 0)	:=(others=>'0');
signal	rvmode	:std_logic;
signal	HLsel		:std_logic;
signal	bus_blenx	:std_logic_vector(3 downto 0);

begin
	
	bus_blenx<="1000" when bus_blen="000" else '0' & bus_blen;
	
	process(memclk,rstn)
	variable	lrd,lwr	:std_logic;
	variable vaddr	:std_logic_vector(colsize downto 0);
	begin
		if(rstn='0')then
			mstate<=mst_idle;
			lrd:='0';
			lwr:='0';
			mem_blen<=(others=>'0');
			blen1<=(others=>'0');
			blen2<=(others=>'0');
			mem_rd<='0';
			mem_wr<='0';
			bdone<='0';
			rvmode<='0';
			mem_addr<=(others=>'0');
		elsif(memclk' event and memclk='1')then
			mem_rd<='0';
			mem_wr<='0';
			case mstate is
			when mst_idle =>
				if(lwr='1' and rx_wr='1')then
					rvmode<='0';
					vaddr:=('0' & wr_addr(colsize-2 downto 0) & '0')+(wr_blen & '0');
					mem_addr<=wr_addr & '0';
					if(vaddr(colsize)='1')then
						blen2<=vaddr(COLSIZE-1 downto 0);
						blen1<=(ALLZERO(COLSIZE-1 downto 5) & wr_blen & '0')-vaddr(COLSIZE-1 downto 0);
						mem_blen<=(ALLZERO(COLSIZE-1 downto 5) & wr_blen & '0')-vaddr(COLSIZE-1 downto 0);
					else
						blen2<=(others=>'0');
						blen1<=ALLZERO(COLSIZE-1 downto 5) & wr_blen & '0';
						mem_blen<=ALLZERO(COLSIZE-1 downto 5) & wr_blen & '0';
					end if;
					mem_wr<='1';
					mstate<=mst_write1;
				elsif(lwr='1' and rx_rvwr='1')then
					rvmode<='1';
					vaddr:=('0' & wr_addr(colsize-2 downto 0) & '0')+(wr_blen & "000");
					mem_addr<=wr_addr & '0';
					if(vaddr(colsize)='1')then
						blen2<=vaddr(COLSIZE-1 downto 0);
						blen1<=(ALLZERO(COLSIZE-1 downto 7) & wr_blen & "000")-vaddr(COLSIZE-1 downto 0);
						mem_blen<=(ALLZERO(COLSIZE-1 downto 7) & wr_blen & "000")-vaddr(COLSIZE-1 downto 0);
					else
						blen2<=(others=>'0');
						blen1<=ALLZERO(COLSIZE-1 downto 7) & wr_blen & "000";
						mem_blen<=ALLZERO(COLSIZE-1 downto 7) & wr_blen & "000";
					end if;
					mem_wr<='1';
					mstate<=mst_write1;
				elsif(lrd='1' and bus_rd='1')then
					rvmode<='0';
					vaddr:=('0' & bus_addr(colsize-2 downto 0) & '0')+(bus_blenx & '0');
					mem_addr<=bus_addr & '0';
					if(vaddr(colsize)='1')then
						blen2<=vaddr(COLSIZE-1 downto 0);
						blen1<=(ALLZERO(COLSIZE-1 downto 5) & bus_blenx & '0')-vaddr(COLSIZE-1 downto 0);
						mem_blen<=(ALLZERO(COLSIZE-1 downto 5) & bus_blenx & '0')-vaddr(COLSIZE-1 downto 0);
					else
						blen2<=(others=>'0');
						blen1<=ALLZERO(COLSIZE-1 downto 5) & bus_blenx & '0';
						mem_blen<=ALLZERO(COLSIZE-1 downto 5) & bus_blenx & '0';
					end if;
					mem_rd<='1';
					mstate<=mst_read1;
				elsif(lrd='1' and bus_rvrd='1')then
					rvmode<='1';
					vaddr:=('0' & bus_addr(colsize-2 downto 0) & '0')+(bus_blenx & "000");
					mem_addr<=bus_addr & '0';
					if(vaddr(colsize)='1')then
						blen2<=vaddr(COLSIZE-1 downto 0);
						blen1<=(ALLZERO(COLSIZE-1 downto 7) & bus_blenx & "000")-vaddr(COLSIZE-1 downto 0);
						mem_blen<=(ALLZERO(COLSIZE-1 downto 7) & bus_blenx & "000")-vaddr(COLSIZE-1 downto 0);
					else
						blen2<=(others=>'0');
						blen1<=ALLZERO(COLSIZE-1 downto 7) & bus_blenx & "000";
						mem_blen<=ALLZERO(COLSIZE-1 downto 7) & bus_blenx & "000";
					end if;
					mem_rd<='1';
					mstate<=mst_read1;
				end if;
			when mst_read1 =>
				if(mem_done='1')then
					case blen2(7 downto 0) is
					when x"00" | x"01" =>
						bdone<='1';
						mstate<=mst_done;
					when others =>
						mem_blen<=blen2;
						mem_rd<='1';
						mstate<=mst_read2;
						mem_addr(addrlen-1 downto colsize)<=(bus_addr(addrlen-2 downto colsize-1))+1;
						mem_addr(colsize-1 downto 0)<=(others=>'0');
					end case;
				end if;
			when mst_read2 =>
				if(mem_done='1')then
					bdone<='1';
					mstate<=mst_done;
				end if;
			when mst_write1 =>
				if(mem_done='1')then
					case blen2(7 downto 0) is
					when x"00" | x"01" =>
						bdone<='1';
						mstate<=mst_done;
					when others =>
						mem_blen<=blen2;
						mem_wr<='1';
						mstate<=mst_write2;
						mem_addr(addrlen-1 downto colsize)<=(wr_addr(addrlen-2 downto colsize-1))+1;
						mem_addr(colsize-1 downto 0)<=(others=>'0');
					end case;
				end if;
			when mst_write2 =>
				if(mem_done='1')then
					bdone<='1';
					mstate<=mst_done;
				end if;
			when mst_done =>
				if(back='1')then
					bdone<='0';
					mstate<=mst_idle;
				end if;
			when others =>
				mstate<=mst_idle;
			end case;
			lrd:=bus_rd or bus_rvrd;
			lwr:=rx_wr or rx_rvwr;
		end if;
	end process;
	
	inum<=blen1+mem_num when mstate=mst_read2 else mem_num;
	
	
	process(memclk,rstn)begin
		if(rstn='0')then
			rdat0l<=(others=>'0');
			rdat0h<=(others=>'0');
			rdat1l<=(others=>'0');
			rdat1h<=(others=>'0');
			rdat2l<=(others=>'0');
			rdat2h<=(others=>'0');
			rdat3l<=(others=>'0');
			rdat3h<=(others=>'0');
			rdat4l<=(others=>'0');
			rdat4h<=(others=>'0');
			rdat5l<=(others=>'0');
			rdat5h<=(others=>'0');
			rdat6l<=(others=>'0');
			rdat6h<=(others=>'0');
			rdat7l<=(others=>'0');
			rdat7h<=(others=>'0');
		elsif(memclk' event and memclk='1')then
			if(mem_rdval='1')then
				if(rvmode='0')then
					case inum(3 downto 0) is
					when x"0" =>
						rdat0l<=mem_rdata;
					when x"1" =>
						rdat0h<=mem_rdata;
					when x"2" =>
						rdat1l<=mem_rdata;
					when x"3" =>
						rdat1h<=mem_rdata;
					when x"4" =>
						rdat2l<=mem_rdata;
					when x"5" =>
						rdat2h<=mem_rdata;
					when x"6" =>
						rdat3l<=mem_rdata;
					when x"7" =>
						rdat3h<=mem_rdata;
					when x"8" =>
						rdat4l<=mem_rdata;
					when x"9" =>
						rdat4h<=mem_rdata;
					when x"a" =>
						rdat5l<=mem_rdata;
					when x"b" =>
						rdat5h<=mem_rdata;
					when x"c" =>
						rdat6l<=mem_rdata;
					when x"d" =>
						rdat6h<=mem_rdata;
					when x"e" =>
						rdat7l<=mem_rdata;
					when x"f" =>
						rdat7h<=mem_rdata;
					when others =>
					end case;
				else
					if(inum(1 downto 0)=bus_rvrsel)then
						case inum(5 downto 2) is
						when x"0" =>
							rdat0l<=mem_rdata;
						when x"1" =>
							rdat0h<=mem_rdata;
						when x"2" =>
							rdat1l<=mem_rdata;
						when x"3" =>
							rdat1h<=mem_rdata;
						when x"4" =>
							rdat2l<=mem_rdata;
						when x"5" =>
							rdat2h<=mem_rdata;
						when x"6" =>
							rdat3l<=mem_rdata;
						when x"7" =>
							rdat3h<=mem_rdata;
						when x"8" =>
							rdat4l<=mem_rdata;
						when x"9" =>
							rdat4h<=mem_rdata;
						when x"a" =>
							rdat5l<=mem_rdata;
						when x"b" =>
							rdat5h<=mem_rdata;
						when x"c" =>
							rdat6l<=mem_rdata;
						when x"d" =>
							rdat6h<=mem_rdata;
						when x"e" =>
							rdat7l<=mem_rdata;
						when x"f" =>
							rdat7h<=mem_rdata;
						when others =>
						end case;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	wrnum<=blen1+mem_num when mstate=mst_write2 else mem_num;
	
	mem_wdata<=
					wdat0l	when rvmode='0' and wrnum(3 downto 0)=x"0" else
					wdat0h	when rvmode='0' and wrnum(3 downto 0)=x"1" else
					wdat1l	when rvmode='0' and wrnum(3 downto 0)=x"2" else
					wdat1h	when rvmode='0' and wrnum(3 downto 0)=x"3" else
					wdat2l	when rvmode='0' and wrnum(3 downto 0)=x"4" else
					wdat2h	when rvmode='0' and wrnum(3 downto 0)=x"5" else
					wdat3l	when rvmode='0' and wrnum(3 downto 0)=x"6" else
					wdat3h	when rvmode='0' and wrnum(3 downto 0)=x"7" else
					wdat4l	when rvmode='0' and wrnum(3 downto 0)=x"8" else
					wdat4h	when rvmode='0' and wrnum(3 downto 0)=x"9" else
					wdat5l	when rvmode='0' and wrnum(3 downto 0)=x"a" else
					wdat5h	when rvmode='0' and wrnum(3 downto 0)=x"b" else
					wdat6l	when rvmode='0' and wrnum(3 downto 0)=x"c" else
					wdat6h	when rvmode='0' and wrnum(3 downto 0)=x"d" else
					wdat7l	when rvmode='0' and wrnum(3 downto 0)=x"e" else
					wdat7h	when rvmode='0' and wrnum(3 downto 0)=x"f" else
					wdat0l	when rvmode='1' and wrnum(5 downto 2)=x"0" else
					wdat0h	when rvmode='1' and wrnum(5 downto 2)=x"1" else
					wdat1l	when rvmode='1' and wrnum(5 downto 2)=x"2" else
					wdat1h	when rvmode='1' and wrnum(5 downto 2)=x"3" else
					wdat2l	when rvmode='1' and wrnum(5 downto 2)=x"4" else
					wdat2h	when rvmode='1' and wrnum(5 downto 2)=x"5" else
					wdat3l	when rvmode='1' and wrnum(5 downto 2)=x"6" else
					wdat3h	when rvmode='1' and wrnum(5 downto 2)=x"7" else
					wdat4l	when rvmode='1' and wrnum(5 downto 2)=x"8" else
					wdat4h	when rvmode='1' and wrnum(5 downto 2)=x"9" else
					wdat5l	when rvmode='1' and wrnum(5 downto 2)=x"a" else
					wdat5h	when rvmode='1' and wrnum(5 downto 2)=x"b" else
					wdat6l	when rvmode='1' and wrnum(5 downto 2)=x"c" else
					wdat6h	when rvmode='1' and wrnum(5 downto 2)=x"d" else
					wdat7l	when rvmode='1' and wrnum(5 downto 2)=x"e" else
					wdat7h	when rvmode='1' and wrnum(5 downto 2)=x"f" else
					(others=>'0');
	wr_byteen<=
					wrben0l	when rvmode='0' and wrnum(3 downto 0)=x"0" else
					wrben0h	when rvmode='0' and wrnum(3 downto 0)=x"1" else
					wrben1l	when rvmode='0' and wrnum(3 downto 0)=x"2" else
					wrben1h	when rvmode='0' and wrnum(3 downto 0)=x"3" else
					wrben2l	when rvmode='0' and wrnum(3 downto 0)=x"4" else
					wrben2h	when rvmode='0' and wrnum(3 downto 0)=x"5" else
					wrben3l	when rvmode='0' and wrnum(3 downto 0)=x"6" else
					wrben3h	when rvmode='0' and wrnum(3 downto 0)=x"7" else
					wrben4l	when rvmode='0' and wrnum(3 downto 0)=x"8" else
					wrben4h	when rvmode='0' and wrnum(3 downto 0)=x"9" else
					wrben5l	when rvmode='0' and wrnum(3 downto 0)=x"a" else
					wrben5h	when rvmode='0' and wrnum(3 downto 0)=x"b" else
					wrben6l	when rvmode='0' and wrnum(3 downto 0)=x"c" else
					wrben6h	when rvmode='0' and wrnum(3 downto 0)=x"d" else
					wrben7l	when rvmode='0' and wrnum(3 downto 0)=x"e" else
					wrben7h	when rvmode='0' and wrnum(3 downto 0)=x"f" else
					wrben0l	when rvmode='1' and wrnum(5 downto 2)=x"0" else
					wrben0h	when rvmode='1' and wrnum(5 downto 2)=x"1" else
					wrben1l	when rvmode='1' and wrnum(5 downto 2)=x"2" else
					wrben1h	when rvmode='1' and wrnum(5 downto 2)=x"3" else
					wrben2l	when rvmode='1' and wrnum(5 downto 2)=x"4" else
					wrben2h	when rvmode='1' and wrnum(5 downto 2)=x"5" else
					wrben3l	when rvmode='1' and wrnum(5 downto 2)=x"6" else
					wrben3h	when rvmode='1' and wrnum(5 downto 2)=x"7" else
					wrben4l	when rvmode='1' and wrnum(5 downto 2)=x"8" else
					wrben4h	when rvmode='1' and wrnum(5 downto 2)=x"9" else
					wrben5l	when rvmode='1' and wrnum(5 downto 2)=x"a" else
					wrben5h	when rvmode='1' and wrnum(5 downto 2)=x"b" else
					wrben6l	when rvmode='1' and wrnum(5 downto 2)=x"c" else
					wrben6h	when rvmode='1' and wrnum(5 downto 2)=x"d" else
					wrben7l	when rvmode='1' and wrnum(5 downto 2)=x"e" else
					wrben7h	when rvmode='1' and wrnum(5 downto 2)=x"f" else
					"00";
	
	process(busclk,rstn)begin
		if(rstn='0')then
			bstate<=bst_idle;
			bcount<="000";
			back<='0';
			bus_rdval<='0';
			bus_rdat<=(others=>'0');
			bus_Wait<='0';
			wr_blen<=(others=>'0');
			wr_addr<=(others=>'0');
			wr_rvsel<=(others=>'0');
			rx_wr<='0';
			rx_rvwr<='0';
		elsif(busclk' event and busclk='1')then
			case bstate is
			when bst_idle =>
				if(bus_rd='1' or bus_rvrd='1')then
					bcount<="000";
					bstate<=bst_rwait;
				elsif(bus_wr='1')then
					bcount<="000";
					bstate<=bst_wrecv;
					wdat0l<=bus_wdat(15 downto 0);
					wdat0h<=bus_wdat(31 downto 16);
					wr_addr<=bus_addr;
					wr_blen<="0001";
					wrben0l<=bus_byteen(1 downto 0);
					wrben0h<=bus_byteen(3 downto 2);
					wr_rvsel<=(others=>'1');
				elsif(bus_rvwr='1')then
					bcount<="000";
					bstate<=bst_rvwrecv;
					wdat0l<=bus_wdat(15 downto 0);
					wdat0h<=bus_wdat(31 downto 16);
					wr_addr<=bus_addr;
					wr_blen<="0001";
					wrben0l<=bus_byteen(1 downto 0);
					wrben0h<=bus_byteen(3 downto 2);
					wr_rvsel<=bus_rvwsel;
				end if;
			when bst_rwait =>
				if(bdone='1')then
					back<='1';
					bus_rdat<=rdat0h & rdat0l;
					bus_rdval<='1';
					bstate<=bst_read;
				end if;
			when bst_read =>
				if(bdone='0')then
					back<='0';
				end if;
				if(bus_blen=(BCOUNT+"001"))then
					bus_rdval<='0';
					bstate<=bst_idle;
				else
					bcount<=bcount+"001";
					case bcount is
					when "000" =>
						bus_rdat<=rdat1h & rdat1l;
					when "001" =>
						bus_rdat<=rdat2h & rdat2l;
					when "010" =>
						bus_rdat<=rdat3h & rdat3l;
					when "011" =>
						bus_rdat<=rdat4h & rdat4l;
					when "100" =>
						bus_rdat<=rdat5h & rdat5l;
					when "101" =>
						bus_rdat<=rdat6h & rdat6l;
					when "110" =>
						bus_rdat<=rdat7h & rdat7l;
					when others =>
						bus_rdat<=(others=>'0');
					end case;
				end if;
			when bst_wrecv | bst_rvwrecv =>
				if(bus_wr='0' and bus_rvwr='0')then
					if(bstate=bst_rvwrecv)then
						rx_rvwr<='1';
					else
						rx_wr<='1';
					end if;
					bstate<=bst_write;
					bus_wait<='1';
				else
					wr_blen<=wr_blen+"0001";
					case bcount is
					when "000" =>
						wdat1l<=bus_wdat(15 downto 0);
						wdat1h<=bus_wdat(31 downto 16);
						wrben1l<=bus_byteen(1 downto 0);
						wrben1h<=bus_byteen(3 downto 2);
					when "001" =>
						wdat2l<=bus_wdat(15 downto 0);
						wdat2h<=bus_wdat(31 downto 16);
						wrben2l<=bus_byteen(1 downto 0);
						wrben2h<=bus_byteen(3 downto 2);
					when "010" =>
						wdat3l<=bus_wdat(15 downto 0);
						wdat3h<=bus_wdat(31 downto 16);
						wrben3l<=bus_byteen(1 downto 0);
						wrben3h<=bus_byteen(3 downto 2);
					when "011" =>
						wdat4l<=bus_wdat(15 downto 0);
						wdat4h<=bus_wdat(31 downto 16);
						wrben4l<=bus_byteen(1 downto 0);
						wrben4h<=bus_byteen(3 downto 2);
					when "100" =>
						wdat5l<=bus_wdat(15 downto 0);
						wdat5h<=bus_wdat(31 downto 16);
						wrben5l<=bus_byteen(1 downto 0);
						wrben5h<=bus_byteen(3 downto 2);
					when "101" =>
						wdat6l<=bus_wdat(15 downto 0);
						wdat6h<=bus_wdat(31 downto 16);
						wrben6l<=bus_byteen(1 downto 0);
						wrben6h<=bus_byteen(3 downto 2);
					when "110" =>
						wdat7l<=bus_wdat(15 downto 0);
						wdat7h<=bus_wdat(31 downto 16);
						wrben7l<=bus_byteen(1 downto 0);
						wrben7h<=bus_byteen(3 downto 2);
					when others =>
					end case;
					bcount<=bcount+"001";
				end if;
			when bst_write =>
				if(bdone='1')then
					rx_wr<='0';
					rx_rvwr<='0';
					back<='1';
					bstate<=bst_ack;
				end if;
			when bst_ack =>
				if(bdone='0')then
					back<='0';
					bus_wait<='0';

					bstate<=bst_idle;
				end if;
			when others=>
				bstate<=bst_idle;
			end case;
		end if;
	end process;
	
	wrinum<=conv_integer(wrnum(1 downto 0));
	
	HLsel<=wrnum(0) when rvmode='0' else wrnum(2);
	
	mem_byteen<=	"11" when (mstate=mst_read1 or mstate=mst_read2) else "00" when wr_rvsel(wrinum)='0' else wr_byteen;

end rtl;
