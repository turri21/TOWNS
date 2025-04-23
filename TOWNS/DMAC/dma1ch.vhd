LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dma1ch is
port(
	reset			:in std_logic;
	countwdat	:in std_logic_vector(15 downto 0);
	countwr		:in std_logic_vector(1 downto 0);
	bcountdat	:out std_logic_vector(15 downto 0);
	ccountdat	:out std_logic_vector(15 downto 0);
	addrwdat		:in std_logic_vector(31 downto 0);
	addrwr		:in std_logic_vector(3 downto 0);
	baddrdat		:out std_logic_vector(31 downto 0);
	caddrdat		:out std_logic_vector(31 downto 0);
	rbase			:in std_logic;
	akl			:in std_logic;
	rql			:in std_logic;
	exw			:in std_logic;
	cmp			:in std_logic;
	ddma			:in std_logic;
	ahld			:in std_logic;
	mtm			:in std_logic;
	wev			:in std_logic;
	bhld			:in std_logic;
	tmode			:in std_logic_vector(1 downto 0);
	adir			:in std_logic;
	auti			:in std_logic;
	tdir			:in std_logic_vector(1 downto 0);
	w_bn			:in std_logic;
	rq				:out std_logic;
	tc				:out std_logic;
	tmpreg		:out std_logic_vector(15 downto 0);
	srq			:in std_logic;
	msk			:in std_logic;
	
	drq			:in std_logic;
	dack			:out std_logic;
	drdat			:in std_logic_Vector(15 downto 0);
	dwdat			:out std_logic_Vector(15 downto 0);
	
	busreq		:out std_logic;
	busact		:in std_logic;
	maddr			:out std_logic_vector(31 downto 2);
	mbsel			:out std_logic_vector(3 downto 0);
	mrd			:out std_logic;
	mwr			:out std_logic;
	mrdat			:in std_logic_vector(31 downto 0);
	mwdat			:out std_logic_vector(31 downto 0);
	mrval			:in std_logic;
	mwait			:in std_logic;
	
	clk			:in std_logic;
	rstn			:in std_logic
);
end dma1ch;

architecture rtl of dma1ch is
type state_t is(
	st_idle,
	st_waitbus,
	st_read,
	st_write,
	st_next,
	st_next2
);
signal	state	:state_t;
signal	bcount	:std_logic_vector(15 downto 0);
signal	ccount	:std_logic_vector(16 downto 0);
signal	baddr		:std_logic_vector(31 downto 0);
signal	caddr		:std_logic_vector(31 downto 0);

signal	rqsum	:std_logic;
signal	rqmsk	:std_logic;

signal	addrnxt	:std_logic;
signal	dackx	:std_logic;

begin
	rqsum<=	srq or (drq xor rql);
	rqmsk<=rqsum and (not msk);
	rq<=rqsum;
	
	process(clk,rstn)
	variable conf	:std_logic_vector(1 downto 0);
	begin
		if(rstn='0')then
			bcount<=(others=>'0');
			ccount<=(others=>'0');
			baddr<=(others=>'0');
			caddr<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(countwr(0)='1')then
				bcount(7 downto 0)<=countwdat(7 downto 0);
				ccount(7 downto 0)<=countwdat(7 downto 0);
				ccount(16)<='0';
			end if;
			if(countwr(1)='1')then
				bcount(15 downto 8)<=countwdat(15 downto 8);
				ccount(15 downto 8)<=countwdat(15 downto 8);
				ccount(16)<='0';
			end if;
			if(addrwr(0)='1')then
				baddr(7 downto 0)<=addrwdat(7 downto 0);
				if(rbase='0')then
					caddr(7 downto 0)<=addrwdat(7 downto 0);
				end if;
			end if;
			if(addrwr(1)='1')then
				baddr(15 downto 8)<=addrwdat(15 downto 8);
				if(rbase='0')then
					caddr(15 downto 8)<=addrwdat(15 downto 8);
				end if;
			end if;
			if(addrwr(2)='1')then
				baddr(23 downto 16)<=addrwdat(23 downto 16);
				if(rbase='0')then
					caddr(23 downto 16)<=addrwdat(23 downto 16);
				end if;
			end if;
			if(addrwr(3)='1')then
				baddr(31 downto 24)<=addrwdat(31 downto 24);
				if(rbase='0')then
					caddr(31 downto 24)<=addrwdat(31 downto 24);
				end if;
			end if;
			if(addrnxt='1')then
				if(ccount(16)='1')then
					if(auti='1')then
						ccount<='0' & bcount;
						caddr<=baddr;
					end if;
				else
					ccount<=ccount-1;
					conf:=adir & w_bn;
					case conf is
					when "00" =>
						caddr<=caddr+x"1";
					when "01" =>
						caddr<=caddr+x"2";
					when "10" =>
						caddr<=caddr-x"1";
					when "11" =>
						caddr<=caddr-x"2";
					end case;
				end if;
			end if;
		end if;
	end process;
	
	process(clk,rstn)
	variable rqe	:std_logic;
	variable lrq	:std_logic;
	variable cwait	:integer range 0 to 3;
	begin
		if(rstn='0')then
			state<=st_idle;
			lrq:='0';
			busreq<='0';
			maddr<=(others=>'0');
			mbsel<=(others=>'0');
			mwdat<=(others=>'0');
			cwait:=0;
		elsif(clk' event and clk='1')then
			if(reset='1')then
				state<=st_idle;
				lrq:='0';
				busreq<='0';
				maddr<=(others=>'0');
				mbsel<=(others=>'0');
				mwdat<=(others=>'0');
			else
				mrd<='0';
				mwr<='0';
				dackx<='0';
				addrnxt<='0';
				tc<='0';
				if(lrq='0' and rqmsk='1')then
					rqe:='1';
				end if;
				lrq:=rqmsk;
				if(cwait>0)then
					cwait:=cwait-1;
				else
					case state is
					when st_idle =>
						if(((TMODE="00" and rqmsk='1') or (TMODE="01" and rqe='1')) and ccount(16)='0' and ddma='0')then
--						if(((TMODE="00" and rqmsk='1') or (TMODE="01" and rqe='1')) and ddma='0')then
							rqe:='0';
							busreq<='1';
							state<=st_waitbus;
						end if;
					when st_waitbus =>
						if(busact='1')then
							case TDIR is
							when "01" =>
								maddr<=caddr(31 downto 2);
								if(W_Bn='1')then
									if(caddr(1)='1')then
										mbsel<="1100";
									else
										mbsel<="0011";
									end if;
									mwdat<=drdat & drdat;
								else
									case caddr(1 downto 0) is
									when "00" =>
										mbsel<="0001";
									when "01" =>
										mbsel<="0010";
									when "10" =>
										mbsel<="0100";
									when "11" =>
										mbsel<="1000";
									end case;
									mwdat<=drdat(7 downto 0) & drdat(7 downto 0) & drdat(7 downto 0) & drdat(7 downto 0);
								end if;
								dackx<='1';
								if(ccount(16)='0')then
									mwr<='1';
									cwait:=2;
								end if;
								state<=st_write;
							when "10" =>
								maddr<=caddr(31 downto 2);
								mbsel<=(others=>'1');
								mrd<='1';
								state<=st_read;
							when others =>
								state<=st_idle;
							end case;
						end if;
					when st_read =>
						if(mrval='1')then
							if(W_Bn='1')then
								if(caddr(1)='1')then
									dwdat<=mrdat(31 downto 16);
								else
									dwdat<=mrdat(15 downto 0);
								end if;
							else
								case caddr(1 downto 0) is
								when "00" =>
									dwdat<=mrdat(7 downto 0) & mrdat(7 downto 0);
								when "01" =>
									dwdat<=mrdat(15 downto 8) & mrdat(15 downto 8);
								when "10" =>
									dwdat<=mrdat(23 downto 16) & mrdat(23 downto 16);
								when "11" =>
									dwdat<=mrdat(31 downto 24) & mrdat(31 downto 24);
								end case;
							end if;
							dackx<='1';
							state<=st_next;
						end if;
					when st_write =>
						if(mwait='0')then
							state<=st_next;
						end if;
					when st_next =>
						busreq<='0';
						addrnxt<='1';
						if(ccount=('0' & x"0000"))then
							tc<='1';
						end if;
						state<=st_next2;
					when st_next2 =>
						state<=st_idle;
					when others =>
					end case;
				end if;
			end if;
		end if;
	end process;
	
	bcountdat<=bcount;
	ccountdat<=ccount(15 downto 0);
	baddrdat<=baddr;
	caddrdat<=caddr;
	

	dack<=not (dackx xor akl);
	tmpreg<=(others=>'0');

end rtl;
	