LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use	work.MEM_ADDR_pkg.all;

entity memorymap is
generic(
	addrwidth	:integer	:=23
);
port(
	cpuaddr		:in std_logic_vector(31 downto 2);
	cpublen		:in std_logic_vector(2 downto 0);
	cpubyteen	:in std_logic_vector(3 downto 0);
	cpurd			:in std_logic;
	cpuwr			:in std_logic;
	cpuwdat		:in std_logic_vector(31 downto 0);
	cpurdat		:out std_logic_vector(31 downto 0);
	cpurval		:out std_logic;
	cpuwait		:out std_logic;
	
	a20en			:in std_logic;
	rbooten		:in std_logic;
	rviden		:in std_logic;
	rdicen		:in std_logic;
	rdicsel		:in std_logic_vector(3 downto 0);
	wpagesel		:in std_logic;
	wplanesel	:in std_logic_vector(3 downto 0);
	rpagesel		:in std_logic;
	rplanesel	:in std_logic_vector(1 downto 0);
	ankcgsel		:in std_logic;
	vrammsel		:in std_logic_vector(3 downto 0);
	vrammsk		:in std_logic_vector(31 downto 0);
	pcmbank		:in std_logic_vector(3 downto 0);
	
	sdraddr		:out std_logic_vector(addrwidth-1 downto 0);
	sdrblen		:out std_logic_vector(2 downto 0);
	sdrbyteen	:out std_logic_vector(3 downto 0);
	sdrrd			:out std_logic;
	sdrwr			:out std_logic;
	sdrrvrd		:out std_logic;
	sdrrvwr		:out std_logic;
	sdrrvrsel	:out std_logic_vector(1 downto 0);
	sdrrvwsel	:out std_logic_vector(3 downto 0);
	sdrrdat		:in std_logic_vector(31 downto 0);
	sdrwdat		:out std_logic_vector(31 downto 0);
	sdrrval		:in std_logic;
	sdrwait		:in std_logic;
	
	spraddr		:out std_logic_vector(14 downto 0);
	sprblen		:out std_logic_vector(2 downto 0);
	sprbyteen	:out std_logic_vector(3 downto 0);
	sprrd			:out std_logic;
	sprwr			:out std_logic;
	sprrdat		:in std_logic_vector(31 downto 0);
	sprwdat		:out std_logic_vector(31 downto 0);
	sprrval		:in std_logic;
	sprwait		:in std_logic;
	
	cmosaddr		:out std_logic_vector(10 downto 0);
	cmosblen		:out std_logic_vector(2 downto 0);
	cmosbyteen	:out std_logic_vector(3 downto 0);
	cmosrd		:out std_logic;
	cmoswr		:out std_logic;
	cmosrdat		:in std_logic_vector(31 downto 0);
	cmoswdat		:out std_logic_vector(31 downto 0);
	cmosrval		:in std_logic;
	cmoswait		:in std_logic;
	
	iocvraddr	:out std_logic_vector(4 downto 0);
	iocvrblen	:out std_logic_vector(2 downto 0);
	iocvrbyteen	:out std_logic_vector(3 downto 0);
	iocvrrd		:out std_logic;
	iocvrwr		:out std_logic;
	iocvrrdat	:in std_logic_vector(31 downto 0);
	iocvrwdat	:out std_logic_vector(31 downto 0);
	iocvrrval		:in std_logic;
	iocvrwait		:in std_logic;
	
	cvwrote		:out std_logic;
	
	vidPmode		:in std_logic;
	vidrmode		:out std_logic;
	cacheen		:out std_logic;
	
	clk			:in std_logic;
	rstn			:in std_logic
);
end memorymap;

architecture rtl of memorymap is

type memsel_t is(
	sel_MRAM,
	sel_RVRAM,
	sel_CVRAM,
	sel_KVRAM,
	sel_CVRAMres,
	sel_IOCVRAM,
	sel_RDIC,
	sel_RGAIJ,
	sel_BOOT,
	sel_XRAM,
	sel_VRAM0,
	sel_VRAM1,
	sel_VRAM2,
	sel_SPRITE,
	sel_ANK8,
	sel_ANK16,
	sel_DOS,
	sel_DIC,
	sel_FNT,
	sel_CMOS,
	sel_F20,
	sel_SYS,
	sel_PCM,
	sel_OTHER
);
signal	memsel	:memsel_t;
signal	cpuaddrf	:std_logic_vector(31 downto 0);
signal	rvwr_rdn	:std_logic;
signal	a20reset	:std_logic;
signal	a20emod	:std_logic;
signal	other_rval	:std_logic;
signal	other_blen	:std_logic_vector(2 downto 0);

begin
	cpuaddrf<=	cpuaddr & "00" when a20emod='1' else
					cpuaddr(31 downto 21) & '0' & cpuaddr(19 downto 2) & "00";
					
	process(clk,rstn)begin
		if(rstn='0')then
			a20reset<='1';
		elsif(clk' event and clk='1')then
			if(memsel=sel_BOOT)then
				a20reset<='0';
			end if;
		end if;
	end process;
	
	a20emod<=a20reset or a20en;
	
	memsel<=
			sel_RVRAM	when cpuaddrf>=ADDR_RVRAM and cpuaddrf<(ADDR_RVRAM+WIDTH_RVRAM) and rviden='1' else
			sel_IOCVRAM when cpuaddrf>=ADDR_IOCVRAM and cpuaddrf<(ADDR_IOCVRAM+WIDTH_IOCVRAM) and rviden='1' else
			sel_ANK8		when cpuaddrf>=ADDR_ANKCG8 and cpuaddrf<(ADDR_ANKCG8+WIDTH_ANKCG8) and rviden='1' and ankcgsel='1' else
			sel_ANK16	when cpuaddrf>=ADDR_ANKCG16 and cpuaddrf<(ADDR_ANKCG16+WIDTH_ANKCG16) and rviden='1' and ankcgsel='1' else
			sel_CVRAM	when cpuaddrf>=ADDR_CVRAM and cpuaddrf<(ADDR_CVRAM+WIDTH_CVRAM) and rviden='1' else
			sel_KVRAM	when cpuaddrf>=ADDR_KVRAM and cpuaddrf<(ADDR_KVRAM+WIDTH_KVRAM) and rviden='1' else
			sel_CVRAMres when cpuaddrf>=ADDR_CVRAM and cpuaddrf<(ADDR_CVRAM+WIDTH_CVRAMres) and rviden='1' else
			sel_RDIC		when cpuaddrf>=ADDR_RDIC and cpuaddrf<(ADDR_RDIC+WIDTH_RDIC) and rdicen='1' and rviden='1' else
			sel_RGAIJ	when cpuaddrf>=ADDR_RGAIJ and cpuaddrf<(ADDR_RGAIJ+WIDTH_RGAIJ) and rdicen='1' and rviden='1' else
			sel_BOOT		when cpuaddrf>=ADDR_BOOT and cpuaddrf<(ADDR_BOOT+WIDTH_BOOT) and rbooten='1' else
			sel_MRAM		when cpuaddrf>=ADDR_MRAM and cpuaddrf<(ADDR_MRAM+WIDTH_RAM) else
			sel_XRAM		when cpuaddrf>=ADDR_XRAM and cpuaddrf<(ADDR_XRAM+WIDTH_XRAM) else
			sel_VRAM0	when cpuaddrf>=ADDR_VRAM0 and cpuaddrf<(ADDR_VRAM0+WIDTH_VRAM0) else
			sel_VRAM1	when cpuaddrf>=ADDR_VRAM1 and cpuaddrf<(ADDR_VRAM1+WIDTH_VRAM1) else
			sel_VRAM2	when cpuaddrf>=ADDR_VRAM2 and cpuaddrf<(ADDR_VRAM2+WIDTH_VRAM2) else
			sel_SPRITE	when cpuaddrf>=ADDR_SPRITE and cpuaddrf<(ADDR_SPRITE+WIDTH_SPRITE) else
			sel_DOS		when cpuaddrf>=ADDR_DOS and cpuaddrf<(ADDR_DOS+WIDTH_DOS) else
			sel_DIC		when cpuaddrf>=ADDR_DIC and cpuaddrf<(ADDR_DIC+WIDTH_DIC) else
			sel_FNT		when cpuaddrf>=ADDR_FNT and cpuaddrf<(ADDR_FNT+WIDTH_FNT) else
			sel_CMOS		when cpuaddrf>=ADDR_CMOS and cpuaddrf<(ADDR_CMOS+WIDTH_CMOS) else
			sel_F20		when cpuaddrf>=ADDR_F20 and cpuaddrf<(ADDR_F20+WIDTH_F20) else
			sel_PCM		when cpuaddrf>=ADDR_PCMWIN and cpuaddrf<(ADDR_PCMWIN+WIDTH_PCMWIN) else
			sel_SYS		when cpuaddrf>=ADDR_SYS else
			sel_OTHER;

	cacheen<=	'1' when memsel=sel_MRAM else
					'1' when memsel=sel_BOOT else
					'1' when memsel=sel_DOS else
					'1' when memsel=sel_DIC else
					'1' when memsel=sel_FNT else
					'1' when memsel=sel_SYS else
					'0';
	
	sdraddr<=
			RAM_DIC(addrwidth downto 18) & rdicsel & cpuaddrf(14 downto 2) when memsel=sel_RDIC else
			RAM_GAIJ(addrwidth downto 12) & cpuaddrf(12 downto 2) when memsel=sel_RGAIJ else
			RAM_BOOT(addrwidth downto 14) & cpuaddrf(14 downto 2) when memsel=sel_BOOT else
			RAM_MAIN(addrwidth downto addrwidth-1) & cpuaddrf(addrwidth-1 downto 2) when memsel=sel_MRAM else
			RAM_MAIN(addrwidth downto addrwidth-1) & cpuaddrf(addrwidth-1 downto 2) when memsel=sel_XRAM else
			RAM_VRAM0(addrwidth downto  17) & wpagesel & cpuaddrf(14 downto 2) & "00" when memsel=sel_RVRAM and cpuwr='1' else
			RAM_VRAM0(addrwidth downto  17) & rpagesel & cpuaddrf(14 downto 2) & "00" when memsel=sel_RVRAM else
			RAM_VRAM0(addrwidth downto 17) & cpuaddrf(17 downto 2)when memsel=sel_VRAM0 else
			RAM_VRAM1(addrwidth downto 17) & cpuaddrf(17 downto 2)when memsel=sel_VRAM1 else
			RAM_VRAM0(addrwidth downto 18) & cpuaddrf(18 downto 2)when memsel=sel_VRAM2 else
			RAM_ANK8(addrwidth downto 10) & cpuaddrf(10 downto 2) when memsel=sel_ANK8 else
			RAM_ANK16(addrwidth downto 10) & cpuaddrf(10 downto 2) when memsel=sel_ANK16 else
--			RAM_CVRAM(addrwidth downto 11) & cpuaddrf(11 downto 2) when memsel=sel_CVRAM else
--			RAM_KVRAM(addrwidth downto 11) & cpuaddrf(11 downto 2) when memsel=sel_KVRAM else
--			RAM_CVRAM(addrwidth downto 14) & cpuaddrf(14 downto 2) when memsel=sel_CVRAMres else
			RAM_DOS(addrwidth downto 18) & cpuaddrf(18 downto 2) when memsel=sel_DOS else
			RAM_DIC(addrwidth downto 18) & cpuaddrf(18 downto 2) when memsel=sel_DIC else
			RAM_FNT(addrwidth downto 17) & cpuaddrf(17 downto 2) when memsel=sel_FNT else
			RAM_F20(addrwidth downto 18) & cpuaddrf(18 downto 2) when memsel=sel_F20 else
			RAM_SYS(addrwidth downto 17) & cpuaddrf(17 downto 2) when memsel=sel_SYS else
			RAM_SND(addrwidth downto 15) & pcmbank & cpuaddrf(11 downto 2) when memsel=sel_PCM else
			(others=>'1');
	
	sdrblen<=
			cpublen when memsel=sel_RDIC else
			cpublen when memsel=sel_RGAIJ else
			cpublen when memsel=sel_BOOT else
			cpublen when memsel=sel_MRAM else
			cpublen when memsel=sel_RVRAM else
			cpublen when memsel=sel_XRAM else
			cpublen when memsel=sel_VRAM0 else
			cpublen when memsel=sel_VRAM1 else
			cpublen when memsel=sel_VRAM2 else
			cpublen when memsel=sel_ANK8 else
			cpublen when memsel=sel_ANK16 else
--			cpublen when memsel=sel_CVRAM else
--			cpublen when memsel=sel_KVRAM else
--			cpublen when memsel=sel_CVRAMres else
			cpublen when memsel=sel_DOS else
			cpublen when memsel=sel_DIC else
			cpublen when memsel=sel_FNT else
			cpublen when memsel=sel_F20 else
			cpublen when memsel=sel_PCM else
			cpublen when memsel=sel_SYS else
			(others=>'0');
			
	sdrbyteen<=
			cpubyteen when memsel=sel_RDIC else
			cpubyteen when memsel=sel_RGAIJ else
			cpubyteen when memsel=sel_BOOT else
			cpubyteen when memsel=sel_MRAM else
			cpubyteen when memsel=sel_RVRAM else
			cpubyteen when memsel=sel_XRAM else
			cpubyteen and vrammsel when memsel=sel_VRAM0 else
			cpubyteen and vrammsel when memsel=sel_VRAM1 else
			cpubyteen and vrammsel when memsel=sel_VRAM2 else
			cpubyteen when memsel=sel_ANK8 else
			cpubyteen when memsel=sel_ANK16 else
--			cpubyteen when memsel=sel_CVRAM else
--			cpubyteen when memsel=sel_KVRAM else
--			cpubyteen when memsel=sel_CVRAMres else
			cpubyteen when memsel=sel_DOS else
			cpubyteen when memsel=sel_DIC else
			cpubyteen when memsel=sel_FNT else
			cpubyteen when memsel=sel_F20 else
			cpubyteen when memsel=sel_PCM else
			cpubyteen when memsel=sel_SYS else
			(others=>'0');
	
	sdrrd<=
			cpurd when memsel=sel_RDIC else
			cpurd when memsel=sel_RGAIJ else
			cpurd when memsel=sel_BOOT else
			cpurd when memsel=sel_MRAM else
			cpurd when memsel=sel_XRAM else
			cpurd when memsel=sel_VRAM0 else
			cpurd when memsel=sel_VRAM1 else
			cpurd when memsel=sel_VRAM2 else
			cpurd when memsel=sel_ANK8 else
			cpurd when memsel=sel_ANK16 else
--			cpurd when memsel=sel_CVRAM else
--			cpurd when memsel=sel_KVRAM else
--			cpurd when memsel=sel_CVRAMres else
			cpurd when memsel=sel_DOS else
			cpurd when memsel=sel_DIC else
			cpurd when memsel=sel_FNT else
			cpurd when memsel=sel_F20 else
			cpurd when memsel=sel_PCM else
			cpurd when memsel=sel_SYS else
			'0';

	sdrwr<=
--			cpuwr when memsel=sel_RDIC else
			cpuwr when memsel=sel_RGAIJ else
--			cpuwr when memsel=sel_BOOT else
			cpuwr when memsel=sel_MRAM else
			cpuwr when memsel=sel_XRAM else
			cpuwr when memsel=sel_VRAM0 else
			cpuwr when memsel=sel_VRAM1 else
			cpuwr when memsel=sel_VRAM2 else
--			cpuwr	when memsel=sel_ANK8 else
--			cpuwr	when memsel=sel_ANK16 else
--			cpuwr when memsel=sel_CVRAM else
--			cpuwr when memsel=sel_KVRAM else
--			cpuwr when memsel=sel_CVRAMres else
--			cpuwr when memsel=sel_DOS else
--			cpuwr when memsel=sel_DIC else
			cpuwr when memsel=sel_FNT else
			cpuwr when memsel=sel_F20 else
			cpuwr when memsel=sel_PCM else
--			cpuwr when memsel=sel_SYS else
			'0';

	sdrwdat<=
			cpuwdat and vrammsk when memsel=sel_VRAM0 else
			cpuwdat and vrammsk when memsel=sel_VRAM1 else
			cpuwdat and vrammsk when memsel=sel_VRAM2 else
			cpuwdat;
	
	sdrrvwr<=cpuwr when memsel=sel_RVRAM else '0';
	sdrrvrd<=cpurd when memsel=sel_RVRAM else '0';
	sdrrvrsel<=rplanesel;
	sdrrvwsel<=wplanesel;
	
	
	spraddr<="00" & cpuaddrf(14 downto 2) when memsel=sel_CVRAM else
				"00" & cpuaddrf(14 downto 2) when memsel=sel_KVRAM else
				"00" & cpuaddrf(14 downto 2) when memsel=sel_CVRAMres else
				cpuaddrf(16 downto 2);
	sprblen<=cpublen when memsel=sel_SPRITE else
				cpublen when memsel=sel_CVRAM else
				cpublen when memsel=sel_KVRAM else
				cpublen when memsel=sel_CVRAMres else
				(others=>'0');
	sprbyteen<=	cpubyteen when memsel=sel_SPRITE else
					cpubyteen when memsel=sel_CVRAM else
					cpubyteen when memsel=sel_KVRAM else
					cpubyteen when memsel=sel_CVRAMres else
					(others=>'0');
	sprrd<=	cpurd when memsel=sel_SPRITE else
				cpurd when memsel=sel_CVRAM else
				cpurd when memsel=sel_KVRAM else
				cpurd when memsel=sel_CVRAMres else
				'0';
	sprwr<=	cpuwr when memsel=sel_SPRITE else
				cpuwr when memsel=sel_CVRAM else
				cpuwr when memsel=sel_KVRAM else
				cpuwr when memsel=sel_CVRAMres else
				'0';
	sprwdat<=cpuwdat;
	
	iocvraddr<=cpuaddrf(6 downto 2);
	iocvrblen<=cpublen when memsel=sel_IOCVRAM else (others=>'0');
	iocvrbyteen<=cpubyteen when memsel=sel_IOCVRAM else (others=>'0');
	iocvrrd<=cpurd when memsel=sel_IOCVRAM else '0';
	iocvrwr<=cpuwr when memsel=sel_IOCVRAM else '0';
	iocvrwdat<=cpuwdat;
	
	cmosaddr<=cpuaddrf(12 downto 2);
	cmosblen<=cpublen when memsel=sel_CMOS else (others=>'0');
	cmosbyteen<=cpubyteen when memsel=sel_CMOS else (others=>'0');
	cmosrd<=cpurd when memsel=sel_CMOS else '0';
	cmoswr<=cpuwr when memsel=sel_CMOS else '0';
	cmoswdat<=cpuwdat;
	
	cpurdat<=
		sprrdat when memsel=sel_SPRITE else
		sprrdat when memsel=sel_CVRAM else
		sprrdat when memsel=sel_KVRAM else
		sprrdat when memsel=sel_CVRAMres else
		iocvrrdat when memsel=sel_IOCVRAM else
		cmosrdat when memsel=sel_CMOS else
		(others=>'1') when memsel=sel_OTHER else
		sdrrdat;
	
	cpurval<=
		sprrval when memsel=sel_SPRITE else
		sprrval when memsel=sel_CVRAM else
		sprrval when memsel=sel_KVRAM else
		sprrval when memsel=sel_CVRAMres else
		iocvrrval when memsel=sel_IOCVRAM else
		cmosrval when memsel=sel_CMOS else
		other_rval when memsel=sel_OTHER else
		sdrrval;
		
	cpuwait<=sprwait or iocvrwait or sdrwait or cmoswait;
	
	process(clk,rstn)begin
		if(rstn='0')then
			other_rval<='0';
			other_blen<="001";
		elsif(clk' event and clk='1')then
			other_rval<='0';
			if(memsel=sel_OTHER and cpurd='1')then
				other_blen<=cpublen;
				other_rval<='1';
			elsif(other_blen/="001")then
				other_blen<=other_blen-1;
				other_rval<='1';
			end if;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			vidrmode<='1';
		elsif(clk' event and clk='1')then
			if(vidPmode='0')then
				vidrmode<='0';
			elsif(memsel=sel_RVRAM and (cpurd='1' or cpuwr='1'))then
				vidrmode<='1';
			elsif(memsel=sel_VRAM0 and (cpurd='1' or cpuwr='1'))then
				vidrmode<='0';
			end if;
		end if;
	end process;
	
	cvwrote<='1' when memsel=sel_CVRAM and cpuwr='1' else
				'1' when memsel=sel_KVRAM and cpuwr='1' else
				'0';

end rtl;