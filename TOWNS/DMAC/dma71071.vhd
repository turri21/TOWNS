LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dma71071 is
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(1 downto 0);
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	mbusyin	:in std_logic;
	museout	:out std_logic;
	maddr	:out std_logic_vector(31 downto 2);
	mbsel	:out std_logic_vector(3 downto 0);
	mrd	:out std_logic;
	mwr	:out std_logic;
	mwait	:in std_logic;
	mrval	:in std_logic;
	mrdat	:in std_logic_vector(31 downto 0);
	mwdat	:out std_logic_vector(31 downto 0);

	drq0		:in std_logic;
	dack0		:out std_logic;
	drdat0	:in std_logic_vector(15 downto 0);
	dwdat0	:out std_logic_vector(15 downto 0);
	
	drq1		:in std_logic;
	dack1		:out std_logic;
	drdat1	:in std_logic_vector(15 downto 0);
	dwdat1	:out std_logic_vector(15 downto 0);
	
	drq2		:in std_logic;
	dack2		:out std_logic;
	drdat2	:in std_logic_vector(15 downto 0);
	dwdat2	:out std_logic_vector(15 downto 0);
	
	drq3		:in std_logic;
	dack3		:out std_logic;
	drdat3	:in std_logic_vector(15 downto 0);
	dwdat3	:out std_logic_vector(15 downto 0);
	
	tcn		:out std_logic;
	endn		:in std_logic	:='1';
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end dma71071;

architecture rtl of dma71071 is
signal	chsel	:integer range 0 to 3;
signal	bchsel	:std_logic_vector(3 downto 0);
signal	actch	:integer range 0 to 4;
signal	reset	:std_logic;
signal	rbase	:std_logic;
signal	tci	:std_logic_vector(3 downto 0);
signal	tc		:std_logic_vector(3 downto 0);
signal	tcread,ltcread	:std_logic;
signal	cntsetval	:std_logic_vector(15 downto 0);
signal	addrsetval	:std_logic_vector(31 downto 0);
signal	akl	:std_logic;
signal	rql	:std_logic;
signal	exw	:std_logic;
signal	rot	:std_logic;
signal	cmp	:std_logic;
signal	ddma	:std_logic;
signal	ahld	:std_logic;
signal	mtm	:std_logic;
signal	wev	:std_logic;
signal	bhld	:std_logic;
signal	adir	:std_logic_vector(0 to 3);
signal	auti	:std_logic_vector(0 to 3);
signal	w_bn	:std_logic_vector(0 to 3);
signal	srq	:std_logic_vector(3 downto 0);
signal	msk	:std_logic_vector(3 downto 0);
signal	rq		:std_logic_vector(3 downto 0);
signal	mrq	:std_logic_vector(3 downto 0);
signal	drqs	:std_logic_vector(3 downto 0);
signal	dacks	:std_logic_vector(3 downto 0);
signal	busreq	:std_logic_vector(3 downto 0);
signal	busact	:std_logic_vector(3 downto 0);
signal	mrds	:std_logic_vector(3 downto 0);
signal	mwrs	:std_logic_vector(3 downto 0);
subtype countreg_type is std_logic_vector(15 downto 0); 
type countreg_array is array (natural range <>) of countreg_type;
signal	bcountdat	:countreg_array(0 to 3);
signal	ccountdat	:countreg_array(0 to 3);
subtype addrreg_type is std_logic_vector(31 downto 0);
type addrreg_array is array (natural range <>) of addrreg_type;
signal	baddrdat	:addrreg_array(0 to 3);
signal	caddrdat	:addrreg_array(0 to 3);

subtype addrbus_type is std_logic_vector(31 downto 2);
type addrbus_array is array (natural range <>) of addrbus_type;
signal	maddrs	:addrbus_array(0 to 3);

subtype mdatabus_type is std_logic_vector(31 downto 0);
type mdatabus_array is array (natural range <>) of mdatabus_type;
signal	mwdats	:mdatabus_array(0 to 3);

subtype ddatabus_type is std_logic_vector(15 downto 0);
type ddatabus_array is array (natural range <>) of ddatabus_type;
signal	drdat		:ddatabus_array(0 to 3);
signal	dwdat		:ddatabus_array(0 to 3);


subtype bsel_type is std_logic_vector(3 downto 0);
type bsel_array is array (natural range <>) of bsel_type;
signal	mbsels	:bsel_array(0 to 3);

subtype cntset_type is std_logic_vector(1 downto 0);
type cntset_array is array (natural range <>) of cntset_type;
signal	cntsets	:cntset_array(0 to 3);

subtype addrset_type is std_logic_vector(3 downto 0);
type addrset_array is array (natural range <>) of addrset_type;
signal	addrsets	:addrset_array(0 to 3);

subtype tmode_type is std_logic_Vector(1 downto 0);
type tmode_array is array (natural range <>) of tmode_type;
signal	tmodes	:tmode_array(0 to 3);

subtype tdir_type is std_logic_Vector(1 downto 0);
type tdir_array is array (natural range <>) of tdir_type;
signal	tdirs	:tdir_array(0 to 3);

subtype tmpreg_type is std_logic_Vector(15 downto 0);
type tmpreg_array is array (natural range <>) of tmpreg_type;
signal	tmpregs	:tmpreg_array(0 to 3);

signal	countdat	:std_logic_vector(15 downto 0);
signal	addrdat		:std_logic_vector(31 downto 0);

component dma1ch is
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
end component;
begin

	process(clk,rstn)
	variable vchsel	:integer range 0 to 3;
	begin
		if(rstn='0')then
			chsel<=0;
			rbase<='0';
			cntsetval<=(others=>'0');
			addrsetval<=(others=>'0');
			akl<='0';
			rql<='0';
			exw<='0';
			rot<='0';
			cmp<='0';
			ddma<='0';
			ahld<='0';
			mtm<='0';
			wev<='0';
			bhld<='0';
			adir<=(others=>'0');
			auti<=(others=>'0');
			w_bn<=(others=>'0');
			srq<=(others=>'0');
			tmodes<=(others=>"00");
			tdirs<=(others=>"00");
			msk<=(others=>'1');
			vchsel:=0;
		elsif(clk' event and clk='1')then
			cntsets<=(others=>"00");
			addrsets<=(others=>"0000");
			if(cs='1' and wr='1')then
				reset<='0';
				case addr is
				when "00" =>
					cntsetval<=wdat(31 downto 16);
					if(bsel(0)='1')then
						reset<=wdat(0);
					end if;
					if(bsel(1)='1')then
						chsel<=conv_integer(wdat(9 downto 8));
						vchsel:=conv_integer(wdat(9 downto 8));
						rbase<=wdat(10);
					end if;
					cntsets(vchsel)<=bsel(3 downto 2);
				when "01" =>
					addrsetval<=wdat;
					addrsets(chsel)<=bsel;
				when "10" =>
					if(bsel(0)='1')then
						akl<=wdat(7);
						rql<=wdat(6);
						exw<=wdat(5);
						rot<=wdat(4);
						cmp<=wdat(3);
						ddma<=wdat(2);
						ahld<=wdat(1);
						mtm<=wdat(0);
					end if;
					if(bsel(1)='1')then
						wev<=wdat(9);
						bhld<=wdat(8);
					end if;
					if(bsel(2)='1')then
						tmodes(chsel)<=wdat(23 downto 22);
						adir(chsel)<=wdat(21);
						auti(chsel)<=wdat(20);
						tdirs(chsel)<=wdat(19 downto 18);
						w_bn(chsel)<=wdat(16);
					end if;
				when "11" =>
					if(bsel(2)='1')then
						srq<=wdat(19 downto 16);
					end if;
					if(bsel(3)='1')then
						msk<=wdat(27 downto 24);
					end if;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	drqs<=drq3 & drq2 & drq1 & drq0;
	dack3<=dacks(3);
	dack2<=dacks(2);
	dack1<=dacks(1);
	dack0<=dacks(0);
	drdat(0)<=drdat0;
	drdat(1)<=drdat1;
	drdat(2)<=drdat2;
	drdat(3)<=drdat3;
	dwdat0<=dwdat(0);
	dwdat1<=dwdat(1);
	dwdat2<=dwdat(2);
	dwdat3<=dwdat(3);
	
	u1	:for i in 0 to 3 generate
		unit	:dma1ch port map(
			reset			=>reset,
			countwdat	=>cntsetval,
			countwr		=>cntsets(i),
			bcountdat	=>bcountdat(i),
			ccountdat	=>ccountdat(i),
			addrwdat		=>addrsetval,
			addrwr		=>addrsets(i),
			baddrdat		=>baddrdat(i),
			caddrdat		=>caddrdat(i),
			rbase			=>rbase,
			akl			=>akl,
			rql			=>rql,
			exw			=>exw,
			cmp			=>cmp,
			ddma			=>ddma,
			ahld			=>ahld,
			mtm			=>mtm,
			wev			=>wev,
			bhld			=>bhld,
			tmode			=>tmodes(i),
			adir			=>adir(i),
			auti			=>auti(i),
			tdir			=>tdirs(i),
			w_bn			=>w_bn(i),
			rq				=>rq(i),
			tc				=>tci(i),
			tmpreg		=>tmpregs(i),
			srq			=>srq(i),
			msk			=>msk(i),
			
			drq			=>drqs(i),
			dack			=>dacks(i),
			drdat			=>drdat(i),
			dwdat			=>dwdat(i),
			
			busreq		=>busreq(i),
			busact		=>busact(i),
			maddr			=>maddrs(i),
			mbsel			=>mbsels(i),
			mrd			=>mrds(i),
			mwr			=>mwrs(i),
			mrdat			=>mrdat,
			mwdat			=>mwdats(i),
			mrval			=>mrval,
			mwait			=>mwait,
			
			clk			=>clk,
			rstn			=>rstn
		);
	end generate;
	
	process(clk,rstn)
	variable sel	:integer range 0 to 4;
	begin
		if(rstn='0')then
			actch<=4;
			museout<='0';
			busact<=(others=>'0');
		elsif(clk' event and clk='1')then
			sel:=4;
			for i in 3 downto 0 loop
				if(busreq(i)='1')then
					sel:=i;
				end if;
			end loop;
			if(actch=4)then
				if(sel/=4 and mbusyin='0')then
					museout<='1';
					actch<=sel;
					busact(sel)<='1';
				end if;
			elsif(busreq(actch)='0')then
				busact(actch)<='0';
				museout<='0';
				actch<=4;
			end if;
		end if;
	end process;
	
	maddr<=	maddrs(0) when actch=0 else
			maddrs(1) when actch=1 else
			maddrs(2) when actch=2 else
			maddrs(3) when actch=3 else
			(others=>'0');
	mbsel<=	mbsels(0) when actch=0 else
			mbsels(1) when actch=1 else
			mbsels(2) when actch=2 else
			mbsels(3) when actch=3 else
			(others=>'0');
	mrd<=	mrds(0) when actch=0 else
			mrds(1) when actch=1 else
			mrds(2) when actch=2 else
			mrds(3) when actch=3 else
			'0';
	mwr<=	mwrs(0) when actch=0 else
			mwrs(1) when actch=1 else
			mwrs(2) when actch=2 else
			mwrs(3) when actch=3 else
			'0';
	mwdat<=	mwdats(0) when actch=0 else
			mwdats(1) when actch=1 else
			mwdats(2) when actch=2 else
			mwdats(3) when actch=3 else
			(others=>'0');
			
	process(chsel)begin
		bchsel<=(others=>'0');
		bchsel(chsel)<='1';
	end process;
	countdat<=bcountdat(chsel) when rbase='1' else ccountdat(chsel);
	addrdat<=baddrdat(chsel) when rbase='1' else caddrdat(chsel);
	
	tcread<='1' when rd='1' and addr="10" and bsel(3)='1' else '0';

	process(clk,rstn)begin
		if(rstn='0')then
			ltcread<='0';
		elsif(clk' event and clk='1')then
			ltcread<=tcread;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			tc<=(others=>'0');
		elsif(clk' event and clk='1')then
			for i in 0 to 3 loop
				if(tci(i)='1')then
					tc(i)<='1';
				end if;
			end loop;
			if(tcread='0' and ltcread='1')then
				tc<=(others=>'0');
			end if;
		end if;
	end process;
	
	process(drqs,rql)begin
		for i in 0 to 3 loop
			mrq(i)<=drqs(i) xor rql;
		end loop;
	end process;
	
	rdat<=	countdat & "000" & rbase & bchsel & x"00" when addr="00" else
			addrdat when addr="01" else
			mrq & tc & tmodes(chsel) & adir(chsel) & auti(chsel) & tdirs(chsel) & '0' & w_bn(chsel) & "000000" & wev & bhld & akl & rql & exw & rot & cmp & ddma & ahld & mtm when addr="10" else
			"0000" & msk & "0000" & srq & tmpregs(chsel);
			
	doe<='1' when cs='1' and rd='1' else '0';
	
	process(tci)
	variable tmp	:std_logic;
	begin
		tmp:='0';
		for i in 0 to 3 loop
			tmp:=tmp or tci(i);
		end loop;
		tcn<=not tmp;
	end process;
	
end rtl;
