LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use	work.MEM_ADDR_pkg.all;

entity TOWNSMiSTer is
generic(
	CPUID			:std_logic_Vector(2 downto 0)	:="001";
	MACHINEID	:std_logic_vector(15 downto 3)	:="0000000100000";
	MEMSIZE		:std_logic_vector(7 downto 0)	:=x"08";
	RCFREQ		:integer	:=75;			--SDRAM clock MHz
	SCFREQ		:integer	:=25000;		--System clock kHz
	RAMAWIDTH	:integer	:=24;
	ACFREQ		:integer	:=32000		--Audio clock
);
port(
	sysclk	:in std_logic;
	ramclk	:in std_logic;
	vidclk	:in std_logic;
	plllock	:in std_logic;	

	sysrtc	:in std_logic_vector(64 downto 0);

	-- SD-RAM ports
--	pMemClk     : out std_logic;                        -- SD-RAM Clock
	pMemCke     : out std_logic;                 		-- SD-RAM Clock enable
	pMemCs_n    : out std_logic;                        -- SD-RAM Chip select
	pMemRas_n   : out std_logic;                        -- SD-RAM Row/RAS
	pMemCas_n   : out std_logic;                        -- SD-RAM /CAS
	pMemWe_n    : out std_logic;                        -- SD-RAM /WE
	pMemUdq     : out std_logic;                        -- SD-RAM UDQM
	pMemLdq     : out std_logic;                        -- SD-RAM LDQM
	pMemBa1     : out std_logic;                        -- SD-RAM Bank select address 1
	pMemBa0     : out std_logic;                        -- SD-RAM Bank select address 0
	pMemAdr     : out std_logic_vector(12 downto 0);    -- SD-RAM Address
	pMemDat     : inout std_logic_vector(15 downto 0);  -- SD-RAM Data

	-- ROM image loader
	INI_INDEX	:in std_logic_Vector(15 downto 0);
	INI_ADDR		:in std_logic_vector(20 downto 0);
	INI_OE		:in std_logic;
	INI_WDAT		:in std_logic_vector(7 downto 0);
	INI_RDAT		:out std_logic_vector(7 downto 0);
	INI_WR		:in std_logic;
	INI_RD		:in std_logic;
	INI_ULREQ	:out std_logic;
	INI_UL		:in std_logic;
	INI_ACK		:out std_logic;
	INI_DONE		:in std_logic;

	-- PS/2 keyboard ports
	pPs2Clkin	: in std_logic;
	pPs2Clkout	: out std_logic;
	pPs2Datin	: in std_logic;
	pPs2Datout	: out std_logic;
	pPmsClkin	: in std_logic;
	pPmsClkout	: out std_logic;
	pPmsDatin	: in std_logic;
	pPmsDatout	: out std_logic;

	-- Joystick ports (Port_A, Port_B)
	pJoyA       : in std_logic_vector(11 downto 0);
	pJoyB       : in std_logic_vector(11 downto 0);
	pStrA			: out std_logic;
	pStrB			: out std_logic;

	--MiSTer diskimage
	mist_mounted	:in std_logic_vector(3 downto 0);	--SRAM & HDD & FDD1 &FDD0
	mist_readonly	:in std_logic_vector(3 downto 0);
	mist_imgsize	:in std_logic_vector(63 downto 0);

	mist_lba0		:out std_logic_vector(31 downto 0);
	mist_lba1		:out std_logic_vector(31 downto 0);
	mist_lba2		:out std_logic_vector(31 downto 0);
	mist_lba3		:out std_logic_vector(31 downto 0);
	mist_rd			:out std_logic_vector(3 downto 0);
	mist_wr			:out std_logic_vector(3 downto 0);
	mist_ack			:in std_logic_vector(3 downto 0);

	mist_buffaddr	:in std_logic_vector(8 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffdin0	:out std_logic_vector(7 downto 0);
	mist_buffdin1	:out std_logic_vector(7 downto 0);
	mist_buffdin2	:out std_logic_vector(7 downto 0);
	mist_buffdin3	:out std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;

	-- DIP switch, Lamp ports
	pLed        : out std_logic;
	cmosstore	: in std_logic;
--	cmos_hma		: in std_logic;
--	cmos_ems		: in std_logic_vector(5 downto 0);
--	cmos_ramdisk: in std_logic_vector(5 downto 0);
	debclk		: in std_logic_vector(2 downto 0);
	fdd_seekwait: in std_logic;
	fdd_txwait	: in std_logic;
	mousecon		: in std_logic_vector(1 downto 0);
	cxio			:out std_logic;
	fint			:in std_logic_vector(15 downto 0);

	-- Video, Audio/CMT ports
	pVid_R     : out std_logic_vector(7 downto 0);  -- RGB_Red / Svideo_C
	pVid_G     : out std_logic_vector(7 downto 0);  -- RGB_Grn / Svideo_Y
	pVid_B     : out std_logic_vector(7 downto 0);  -- RGB_Blu / CompositeVideodpa
	pSnd_L     : out	std_logic_vector(15 downto 0);	-- Sound-L
	pSnd_R     : out	std_logic_vector(15 downto 0);  	-- Sound-R

	pVid_HS		: out std_logic;                        -- HSync(VGA31K)
	pVid_VS		: out std_logic;                        -- VSync(VGA31K)
	pVid_En		: out std_logic;
	pVid_Clk		: out std_logic;

	
	rstn		:in std_logic
);
end TOWNSMiSTer;

architecture rtl of TOWNSMiSTer is

function townspad(pad :std_logic_vector(7 downto 0))return std_logic_vector is
variable RUNn	:std_logic;
variable SELn	:std_logic;
variable tpad	:std_logic_vector(5 downto 0);
begin
	RUNn:=pad(6);
	SELn:=pad(7);
	tpad(5 downto 0):=pad(5 downto 0);
	if(RUNn='0')then
		tpad(3 downto 2):="00";
	end if;
	if(SELn='0')then
		tpad(1 downto 0):="00";
	end if;
	return tpad;
end townspad;

--signal	vidclk	:std_logic;
signal	dotclk	:std_logic;
signal	deprstn	:std_logic;
signal	vidrstn	:std_logic;
signal	cpurstn	:std_logic;

signal	sysrstn	:std_logic;
signal	ramrstn	:std_logic;


--memory bus
signal	mem_addr			:std_logic_vector(31 downto 2);
signal	mem_blen			:std_logic_vector(2 downto 0);
signal	mem_byteen		:std_logic_Vector(3 downto 0);
signal	mem_rd			:std_logic;
signal	mem_wr			:std_logic;
signal	mem_rdata		:std_logic_vector(31 downto 0);
signal	mem_wdata		:std_logic_vector(31 downto 0);
signal	mem_rdval		:std_logic;
signal	mem_wait			:std_logic;

--SDRAM bus
signal	sdr_cpuaddr		:std_logic_vector(RAMAWIDTH-1 downto 0);
signal	sdr_cpurddata	:std_logic_vector(15 downto 0);
signal	sdr_cpuwrdata	:std_logic_vector(15 downto 0);
signal	sdr_cpurd		:std_logic;
signal	sdr_cpuwr		:std_logic;
signal	sdr_comaddr		:std_logic_vector(RAMAWIDTH-1 downto 0);
signal	sdr_comwrdata	:std_logic_vector(15 downto 0);
signal	sdr_comwr		:std_logic;
signal	sdr_combsel		:std_logic_vector(1 downto 0);
signal	sdr_comblen		:std_logic_vector(8 downto 0);
signal	sdr_cpublen		:std_logic_vector(8 downto 0);
signal	sdr_cpubsel		:std_logic_vector(1 downto 0);
signal	sdr_cpubnum		:std_logic_vector(8 downto 0);
signal	sdr_cpurval		:std_logic;
signal	sdr_cpudone		:std_logic;
signal	sdr_initdone	:std_logic;

signal	ram_addr			:std_logic_vector(RAMAWIDTH downto 2);
signal	ram_rd			:std_logic;
signal	ram_wr			:std_logic;
signal	ram_rvrd			:std_logic;
signal	ram_rvwr			:std_logic;
signal	ram_rvrsel		:std_logic_Vector(1 downto 0);
signal	ram_rvwsel		:std_logic_vector(3 downto 0);
signal	ram_blen			:std_logic_vector(2 downto 0);
signal	ram_byteen		:std_logic_vector(3 downto 0);
signal	ram_rdat			:std_logic_vector(31 downto 0);
signal	ram_wdat			:std_logic_vector(31 downto 0);
signal	ram_rdval		:std_logic;
signal	ram_wait			:std_logic;
signal	ram_cpuwdata	:std_logic_vector(31 downto 0);

signal	ram_cpuaddr			:std_logic_vector(RAMAWIDTH downto 2);
signal	ram_cpurd			:std_logic;
signal	ram_cpuwr			:std_logic;
signal	ram_cpublen			:std_logic_vector(2 downto 0);
signal	ram_cpubyteen		:std_logic_vector(3 downto 0);

--memory clearer
signal	clr_addr		:std_logic_vector(RAMAWIDTH-1 downto 0);
signal	clr_wr		:std_logic;
signal	clr_rstn		:std_logic;
signal	clr_done		:std_logic;

--iocvr bus
signal	iocvr_addr		:std_logic_vector(4 downto 0);
signal	iocvr_byteen	:std_logic_vector(3 downto 0);
signal	iocvr_rd			:std_logic;
signal	iocvr_wr			:std_logic;
signal	iocvr_rdat		:std_logic_vector(31 downto 0);
signal	iocvr_wdat		:std_logic_vector(31 downto 0);
signal	iocvr_rval		:std_logic;
signal	iocvr_wait		:std_logic;

--io bus
signal	io_dbus			:std_logic_vector(31 downto 0);
signal	io_wait			:std_logic;
signal	io_rd				:std_logic;
signal	io_wr				:std_logic;
signal	io_baddr			:std_logic_vector(15 downto 0);
signal	io_swaddr		:std_logic_vector(15 downto 0);
signal	io_dwaddr		:std_logic_vector(15 downto 0);
signal	io_byteen		:std_logic_vector(3 downto 0);
signal	odat_cpu			:std_logic_vector(31 downto 0);
signal	io_swdat			:std_logic_vector(15 downto 0);
signal	io_bwdat			:std_logic_vector(7 downto 0);

--CPU signal
signal	cpu_memaddr		:std_logic_vector(31 downto 0);
signal	cpu_memwdata	:std_logic_vector(31 downto 0);
signal	cpu_memrdata	:std_logic_vector(31 downto 0);
signal	cpu_membyteen	:std_logic_vector(3 downto 0);
signal	cpu_memwr		:std_logic;
signal	cpu_memrd		:std_logic;
signal	cpu_memblen		:std_logic_vector(2 downto 0);
signal	cpu_memrval		:std_logic;
signal	cpu_memwait		:std_logic;
signal	cpu_ioaddr		:std_logic_vector(15 downto 0);
signal	cpu_iowdata		:std_logic_vector(31 downto 0);
signal	cpu_iobyteen	:std_logic_vector(3 downto 0);
signal	cpu_iowr			:std_logic;
signal	cpu_iord			:std_logic;
signal	cpu_iorval		:std_logic;
signal	cpu_iowait		:std_logic;
signal	cpu_a20en		:std_logic;
signal	cpu_intdo		:std_logic;
signal	cpu_ivect		:std_logic_vector(7 downto 0);
signal	cpu_intdone		:std_logic;

--memory map
signal	mmap_memaddr	:std_logic_vector(31 downto 2);
signal	mmap_memblen	:std_logic_vector(2 downto 0);
signal	mmap_membyteen	:std_logic_vector(3 downto 0);
signal	mmap_memrd		:std_logic;
signal	mmap_memwr		:std_logic;
signal	mmap_memwdata	:std_logic_vector(31 downto 0);

--Initial ROM loader
signal	ldr_addr			:std_logic_vector(20 downto 2);
signal	ldr_wdat			:std_logic_vector(31 downto 0);
signal	ldr_aen			:std_logic;
signal	ldr_wr			:std_logic;
signal	ldr_ack			:std_logic;
signal	ldr_done			:std_logic;
signal	ldr_rstn			:std_logic;
signal	ldr_en			:std_logic;

--debug
signal	Seg0		:std_logic_vector(3 downto 0);
signal	Seg1		:std_logic_vector(3 downto 0);
signal	Seg2		:std_logic_vector(3 downto 0);
signal	Seg3		:std_logic_vector(3 downto 0);
signal	Seg4		:std_logic_vector(3 downto 0);
signal	Seg5		:std_logic_vector(3 downto 0);
signal	xSeg0		:std_logic_vector(7 downto 0);
signal	xSeg1		:std_logic_vector(7 downto 0);
signal	xSeg2		:std_logic_vector(7 downto 0);
signal	xSeg3		:std_logic_vector(7 downto 0);
signal	xSeg4		:std_logic_vector(7 downto 0);
signal	xSeg5		:std_logic_vector(7 downto 0);
signal	DEBSEL	:std_logic;

signal	vCLKSEL	:std_logic_vector(1 downto 0);

--io20
signal	io20_odat	:std_logic_vector(7 downto 0);
signal	io20_doe		:std_logic;
signal	io20_cs		:std_logic;
signal	io20_rst		:std_logic;
signal	io20_poff	:std_logic;
signal	io20_wrprot	:std_logic;

--cmos
signal	cmos_iaddr	:std_logic_vector(9 downto 0);
signal	cmos_ics		:std_logic;
signal	cmos_irdat	:std_logic_vector(31 downto 0);
signal	cmos_idoe	:std_logic;
signal	cmos_iwait	:std_logic;
signal	cmos_maddr	:std_logic_vector(10 downto 0);
signal	cmos_mbsel	:std_logic_vector(3 downto 0);
signal	cmos_mcs		:std_logic;
signal	cmos_mrd		:std_logic;
signal	cmos_mwr		:std_logic;
signal	cmos_mrdat	:std_logic_vector(31 downto 0);
signal	cmos_mwdat	:std_logic_vector(31 downto 0);
signal	cmos_mwait	:std_logic;
signal	cmos_mrval	:std_logic;

--timerint
signal	tint_cs		:std_logic;
signal	tint_odat	:std_logic_vector(7 downto 0);
signal	tint_doe		:std_logic;
signal	tint_int		:std_logic;
signal	tint_snden	:std_logic;

--Programmable Timer
signal	ptc0_cs		:std_logic;
signal	ptc0_odat	:std_logic_vector(7 downto 0);
signal	ptc0_doe		:std_logic;
signal	ptc0_cin		:std_logic_vector(2 downto 0);
signal	ptc0_cout	:std_logic_vector(2 downto 0);
signal	ptc1_cs		:std_logic;
signal	ptc1_odat	:std_logic_vector(7 downto 0);
signal	ptc1_doe		:std_logic;
signal	ptc1_cin		:std_logic_vector(2 downto 0);
signal	ptc1_cout	:std_logic_vector(2 downto 0);
signal	sft_307k		:std_logic;
signal	sft_1229k	:std_logic;
constant	div_307k		:integer	:=SCFREQ/307;
constant div_1229k	:integer	:=SCFREQ/1229;

--interval timer II
signal	it2_cs	:std_logic;
signal	it2_rdat	:std_logic_vector(31 downto 0);
signal	it2_doe	:std_logic;
signal	it2_int	:std_logic;
signal	it2_sft	:std_logic;

--CRTC register
signal	crtcr_cs		:std_logic;
signal	crtcr_odat	:std_logic_vector(31 downto 0);
signal	crtcr_doe	:std_logic;

signal	crtcr_HSW1	:std_logic_vector(7 downto 0);
signal	crtcr_HSW2	:std_logic_vector(10 downto 0);
signal	crtcr_HST	:std_logic_vector(10 downto 0);
signal	crtcr_VST1	:std_logic_vector(4 downto 0);
signal	crtcr_VST2	:std_logic_vector(4 downto 0);
signal	crtcr_EET	:std_logic_vector(4 downto 0);
signal	crtcr_VST	:std_logic_vector(10 downto 0);
signal	crtcr_FA0	:std_logic_vector(15 downto 0);
signal	crtcr_FO0	:std_logic_vector(15 downto 0);
signal	crtcr_LO0	:std_logic_vector(15 downto 0);
signal	crtcr_FA1	:std_logic_vector(15 downto 0);
signal	crtcr_FO1	:std_logic_vector(15 downto 0);
signal	crtcr_LO1	:std_logic_vector(15 downto 0);
signal	crtcr_HDS0	:std_logic_vector(10 downto 0);
signal	crtcr_HDE0	:std_logic_vector(10 downto 0);
signal	crtcr_HDS1	:std_logic_vector(10 downto 0);
signal	crtcr_HDE1	:std_logic_vector(10 downto 0);
signal	crtcr_VDS0	:std_logic_vector(10 downto 0);
signal	crtcr_VDE0	:std_logic_vector(10 downto 0);
signal	crtcr_VDS1	:std_logic_vector(10 downto 0);
signal	crtcr_VDE1	:std_logic_vector(10 downto 0);
signal	crtcr_ZH0	:std_logic_vector(3 downto 0);
signal	crtcr_ZV0	:std_logic_vector(3 downto 0);
signal	crtcr_ZH1	:std_logic_vector(3 downto 0);
signal	crtcr_ZV1	:std_logic_vector(3 downto 0);
signal	crtcr_PMODE	:std_logic;
signal	crtcr_CL1	:std_logic_vector(1 downto 0);
signal	crtcr_CL0	:std_logic_vector(1 downto 0);
signal	crtcr_PR1	:std_logic;

--VIDC register
signal	vidcr_cs		:std_logic;
signal	vidcr_clmode	:std_logic_vector(3 downto 0);
signal	vidcr_pmode		:std_logic;
signal	vidcr_plt	:std_logic_vector(1 downto 0);
signal	vidcr_ys		:std_logic;
signal	vidcr_ym		:std_logic;
signal	vidcr_pr1	:std_logic;


--Keyboard
signal	kbif_cs		:std_logic;
signal	kbif_odat	:std_logic_vector(31 downto 0);
signal	kbif_doe		:std_logic;
signal	kbif_int		:std_logic;

--keyboard interrupt
signal	kint_cs		:std_logic;
signal	kint_rdat	:std_logic_Vector(7 downto 0);
signal	kint_doe		:std_logic;
signal	kint_int		:std_logic;
signal	kint_nmi		:std_logic;

--Mouse
signal	mous_xdat	:std_logic_vector(9 downto 0);
signal	mous_ydat	:std_logic_vector(9 downto 0);
signal	mous_swdat	:std_logic_vector(1 downto 0);
signal	mous_recv	:std_logic;
signal	mous_clr		:std_logic;
signal	mous_atclr	:std_logic;
signal	mous_rclr	:std_logic;
signal	mous_rrecv	:std_logic;
signal	amous_pdat	:std_logic_vector(5 downto 0);
signal	amous_com	:std_logic;

--1usec delay
signal	udly_cs		:std_logic;
signal	udly_wait	:std_logic;
signal	udly_odat	:std_logic_vector(7 downto 0);
signal	udly_doe		:std_logic;


signal	macid_cs		:std_logic;
signal	macid_odat	:std_logic_vector(15 downto 0);
signal	macid_doe	:std_logic;

--ID rom
signal	idrom_cs		:std_logic;
signal	idrom_odat	:std_logic_vector(7 downto 0);
signal	idrom_doe	:std_logic;

--SPRITE
signal	pat_addr		:std_logic_vector(14 downto 0);
signal	pat_blen		:std_logic_vector(2 downto 0);
signal	pat_bsel		:std_logic_vector(3 downto 0);
signal	pat_rd		:std_logic;
signal	pat_wr		:std_logic;
signal	pat_rdat		:std_logic_vector(31 downto 0);
signal	pat_wdat		:std_logic_vector(31 downto 0);
signal	pat_rval		:std_logic;

--SCSI
signal	scsi_cs		:std_logic;
signal	scsi_odat	:std_logic_vector(7 downto 0);
signal	scsi_doe		:std_logic;
signal	scsi_int		:std_logic;
signal	scsi_drq		:std_logic;
signal	scsi_dackn	:std_logic;
signal	scsi_drdat	:std_logic_vector(15 downto 0);
signal	scsi_dwdat	:std_logic_vector(15 downto 0);

signal	SCSI_SEL		:std_logic;
signal	SCSI_RST		:std_logic;
signal	SCSI_ATN		:std_logic;
signal	SCSI_ACK		:std_logic;
signal	SCSI_REQ		:std_logic;
signal	SCSI_IO		:std_logic;
signal	SCSI_MSG		:std_logic;
signal	SCSI_CD		:std_logic;
signal	SCSI_BSY		:std_logic;
signal	SCSI_DAT		:std_logic_Vector(7 downto 0);
signal	SCSI_HOUT	:std_logic_Vector(7 downto 0);
signal	SCSI_DOUT	:std_logic_vector(7 downto 0);
signal	SCSI_HOE		:std_logic;

signal	scsi_cap		:std_logic_vector(63 downto 0);
signal	scsi_lba		:std_logic_vector(31 downto 0);
signal	scsi_rdreq	:std_logic;
signal	scsi_wrreq	:std_logic;
signal	scsi_syncreq:std_logic;
signal	scsi_sectaddr	:std_logic_vector(8 downto 0);
signal	scsi_rdata	:std_logic_Vector(7 downto 0);
signal	scsi_Wdata	:std_logic_vector(7 downto 0);
signal	scsi_sbusy	:std_logic;
signal	scsi_indisk	:std_logic;

signal	scsi_mistlba	:std_logic_Vector(31 downto 0);
signal	scsi_mistdin	:std_logic_vector(7 downto 0);
signal	scsi_mistbusy	:std_logic;

--Pad IO
signal	pad_cs	:std_logic;
signal	pad_odat	:std_logic_vector(31 downto 0);
signal	pad_doe	:std_logic;
signal	pad_ain	:std_logic_vector(6 downto 0);
signal	pad_bin	:std_logic_vector(6 downto 0);
signal	pad_atrg1:std_logic;
signal	pad_atrg2:std_logic;
signal	pad_btrg1:std_logic;
signal	pad_btrg2:std_logic;
signal	pad_acom	:std_logic;
signal	pad_bcom	:std_logic;
signal	pad_FMmute	:std_logic;
signal	pad_PCMmute	:std_logic;

--PIC
signal	picm_cs		:std_logic;
signal	picm_odat	:std_logic_vector(7 downto 0);
signal	picm_doe		:std_logic;
signal	picm_int0	:std_logic;
signal	picm_int1	:std_logic;
signal	picm_int2	:std_logic;
signal	picm_int3	:std_logic;
signal	picm_int4	:std_logic;
signal	picm_int5	:std_logic;
signal	picm_int6	:std_logic;
signal	picm_int7	:std_logic;
signal	picm_vect	:std_logic_vector(7 downto 0);
signal	picm_vectoe	:std_logic;
signal	pics_cs		:std_logic;
signal	pics_odat	:std_logic_vector(7 downto 0);
signal	pics_doe		:std_logic;
signal	pics_int0	:std_logic;
signal	pics_int1	:std_logic;
signal	pics_int2	:std_logic;
signal	pics_int3	:std_logic;
signal	pics_int4	:std_logic;
signal	pics_int5	:std_logic;
signal	pics_int6	:std_logic;
signal	pics_int7	:std_logic;
signal	pics_int		:std_logic;
signal	pics_vect	:std_logic_vector(7 downto 0);
signal	pics_vectoe	:std_logic;
signal	pic_cas		:std_logic_vector(2 downto 0);
signal	pic_slinta	:std_logic;

--DMA
signal	dmac_cs		:std_logic;
signal	dmac_rdat	:std_logic_vector(31 downto 0);
signal	dmac_doe		:std_logic;
signal	dmac_mbusy	:std_logic;
signal	dmac_muse	:std_logic;
signal	dmac_maddr	:std_logic_vector(31 downto 2);
signal	dmac_mbsel	:std_logic_vector(3 downto 0);
signal	dmac_mwdat	:std_logic_vector(31 downto 0);
signal	dmac_mrd		:std_logic;
signal	dmac_mwr		:std_logic;
signal	dmac_dwdat0	:std_logic_Vector(15 downto 0);
signal	dmac_dwdat1	:std_logic_Vector(15 downto 0);
signal	dmac_dwdat2	:std_logic_Vector(15 downto 0);
signal	dmac_dwdat3	:std_logic_Vector(15 downto 0);

--SYSTEM status
signal	io400_odat	:std_logic_vector(7 downto 0);
signal	io400_cs		:std_logic;
signal	io400_doe	:std_logic;
signal	io404_odat	:std_logic_vector(7 downto 0);
signal	io404_doe	:std_logic;
signal	io404_VRAMSELn	:std_logic;
signal	io480_odat	:std_logic_vector(7 downto 0);
signal	io480_doe	:std_logic;
signal	io480_BROMn	:std_logic;
signal	io480_DIC	:std_logic;
signal	io484_odat	:std_logic_vector(7 downto 0);
signal	io484_doe	:std_logic;
signal	io484_DICSEL	:std_logic_vector(3 downto 0);

--palette 
signal	apal_cs		:std_logic;
signal	apal_odat	:std_logic_vector(7 downto 0);
signal	apal_doe		:std_logic;

signal	dpal_cs		:std_logic;
signal	dpal_odat	:std_logic_vector(7 downto 0);
signal	dpal_doe		:std_logic;
signal	dpal_wrote	:std_logic;

--R video registers
signal	rvid_mcs		:std_logic;
signal	rvid_modat	:std_logic_vector(31 downto 0);
signal	rvid_mrval	:std_logic;

signal	rvid_iocs	:std_logic;
signal	rvid_iord	:std_logic;
signal	rvid_iowr	:std_logic;
signal	rvid_ioodat	:std_logic_vector(7 downto 0);
signal	rvid_iodoe	:std_logic;

signal	rvid_wrsel	:std_logic_vector(3 downto 0);
signal	rvid_rdsel	:std_logic_vector(1 downto 0);
signal	rvid_pgsel	:std_logic;
signal	vidrmode		:std_logic;

--Digital palette modify register
signal	dpmr_cs		:std_logic;
signal	dpmr_odat	:std_logic_vector(7 downto 0);
signal	dpmr_doe		:std_logic;

--Video
signal	vid_HS		:std_logic;
signal	vid_VS		:std_logic;
signal	vid_CS		:std_logic;
signal	vid_hen0,vid_hen1	:std_logic;
signal	vid_ven0,vid_ven1	:std_logic;
signal	vid_pal8no	:std_logic_vector(7 downto 0);
signal	vid_pal8red	:std_logic_vector(7 downto 0);
signal	vid_pal8grn	:std_logic_vector(7 downto 0);
signal	vid_pal8blu	:std_logic_vector(7 downto 0);

signal	vid_pal41no	:std_logic_vector(3 downto 0);
signal	vid_pal41red:std_logic_vector(3 downto 0);
signal	vid_pal41grn:std_logic_vector(3 downto 0);
signal	vid_pal41blu:std_logic_vector(3 downto 0);

signal	vid_pal42no	:std_logic_vector(3 downto 0);
signal	vid_pal42red:std_logic_vector(3 downto 0);
signal	vid_pal42grn:std_logic_vector(3 downto 0);
signal	vid_pal42blu:std_logic_vector(3 downto 0);

signal	vid1en			:std_logic;
signal	vid2en			:std_logic;
signal	vid1lineaddr	:std_logic_vector(10 downto 0);
signal	vid2lineaddr	:std_logic_vector(10 downto 0);
signal	vid1linedata	:std_logic_vector(15 downto 0);
signal	vid2linedata	:std_logic_vector(15 downto 0);
signal	vid1rlinedata	:std_logic_vector(3 downto 0);
signal	vid2rlinedata	:std_logic_vector(3 downto 0);
signal	vidrpen			:std_logic_vector(3 downto 0);
signal	vidrps2			:std_logic;
signal	vidHcomp			:std_logic;
signal	vidHHcomp		:std_logic;
signal	vidVcomp			:std_logic;

signal	vidram_addr		:std_logic_vector(RAMAWIDTH-1 downto 0);
signal	vidram_blen		:std_logic_vector(8 downto 0);
signal	vidram_rd		:std_logic;
signal	vidram_rval		:std_logic;
signal	vidram_rdat		:std_logic_vector(15 downto 0);
signal	vidram_num		:std_logic_vector(8 downto 0);
signal	vidram_done		:std_logic;

--KANJI CG
signal	kcg_mcs		:std_logic;
signal	kcg_mrdat	:std_logic_vector(31 downto 0);
signal	kcg_mrval	:std_logic;
signal	kcg_mwait	:std_logic;

signal	kcg_iocs		:std_logic;
signal	kcg_iordat	:std_logic_vector(31 downto 0);
signal	kcg_iodoe	:std_logic;
signal	kcg_iowait	:std_logic;

signal	kcg_ramaddr	:std_logic_Vector(RAMAWIDTH-1 downto 0);
signal	kcg_ramrd	:std_logic;
signal	kcg_ramwr	:std_logic;
signal	kcg_rambsel	:std_logic_vector(1 downto 0);
signal	kcg_ramrdat	:std_logic_Vector(15 downto 0);
signal	kcg_ramwdat	:std_logic_Vector(15 downto 0);
signal	kcg_ramdone	:std_logic;

--KanjiCGRAM controller
signal	kram_addr	:std_logic_Vector(RAMAWIDTH-1 downto 0);
signal	kram_rd		:std_logic;
signal	kram_wr		:std_logic;
signal	kram_done	:std_logic;

--iocvr ext register
signal	rext_mcs		:std_logic;
signal	rext_mrdat	:std_logic_vector(31 downto 0);
signal	rext_mrval	:std_logic;
signal	rext_iocs	:std_logic;
signal	rext_iordat	:std_logic_vector(7 downto 0);
signal	rext_iodoe	:std_logic;
signal	rext_ANKCG	:std_logic;
signal	rext_BEEPEN	:std_logic;

--iocvr dummy register
signal	iodmy_mcs	:std_logic;
signal	iodmy_mrval	:std_logic;

--CVRAM wrote reg.
signal	cvw_cs	:std_logic;
signal	cvw_rdat	:std_logic_vector(7 downto 0);
signal	cvw_doe	:std_logic;
signal	cvw_wrote:std_logic;

--VSYNC interrupt
signal	vsint_cs		:std_logic;
signal	vsint_int	:std_logic;

--CDROM I/F
signal	cdif_cs		:std_logic;
signal	cdif_rdat	:std_logic_vector(7 downto 0);
signal	cdif_doe		:std_logic;
signal	cdif_drq		:std_logic;
signal	cdif_dackn	:std_logic;
signal	cdif_int		:std_logic;
signal	cdif_mistbusy	:std_logic;
signal	cdif_mistlba	:std_logic_vector(31 downto 0);
signal	cdif_drdat	:std_logic_vector(7 downto 0);

--FDC
signal	fdc_cs		:std_logic;
signal	fdc_rdat		:std_logic_vector(7 downto 0);
signal	fdc_doe		:std_logic;
signal	fdc_drq		:std_logic;
signal	fdc_dackn	:std_logic;
signal	fdc_int		:std_logic;
signal	fdc_mistbusy:std_logic;
signal	fdc_mistlba	:std_logic_vector(31 downto 0);
signal	fdc_mistdin	:std_logic_vector(7 downto 0);
signal	fdc_drdat	:std_logic_vector(7 downto 0);
signal	fdc_dwdat	:std_logic_vector(7 downto 0);
signal	fdcnt_cs		:std_logic;
signal	fdcnt_rdat	:std_logic_vector(7 downto 0);
signal	fdcnt_doe	:std_logic;
signal	fdc_head		:std_logic;
signal	fdc_dsel		:std_logic_vector(3 downto 0);
signal	fdc_motor	:std_logic;
signal	fdc_ready	:std_logic;
signal	fdc_irqmsk	:std_logic;

--Sound
--OPN
signal	opn_cs		:std_logic;
signal	opn_rdat		:std_logic_vector(7 downto 0);
signal	opn_doe		:std_logic;
signal	opn_intn		:std_logic;
signal	opn_sft		:std_logic;
signal	opn_sndL		:std_logic_vector(15 downto 0);
signal	opn_sndR		:std_logic_vector(15 downto 0);

--PCM
signal	pcmr_cs		:std_logic;
signal	sndr_cs		:std_logic;
signal	sndr_rdat	:std_logic_vector(7 downto 0);
signal	sndr_doe		:std_logic;

signal	beep_snd		:std_logic_vector(15 downto 0);

--RTC
signal	rtc_cs	:std_logic;
signal	rtc_rdat	:std_logic_Vector(7 downto 0);
signal	rtc_doe	:std_logic;

--RS-232C
signal	uart_cs		:std_logic;
signal	uart_odat	:std_logic_Vector(7 downto 0);
signal	uart_doe		:std_logic;
signal	uart_intn	:std_logic;

--Memory size
signal	msiz_cs		:std_logic;
signal	msiz_doe		:std_logic;

--VRAM mask reg.
signal	vmsk_cs		:std_logic;
signal	vmsk_odat	:std_logic_Vector(31 downto 0);
signal	vmsk_doe		:std_logic;
signal	vmsk_msel	:std_logic_vector(3 downto 0);
signal	vmsk_mask	:std_logic_vector(31 downto 0);

--NMI mask reg
signal	nmim_cs		:std_logic;
signal	nmim_odat	:std_logic_vector(7 downto 0);
signal	nmim_doe		:std_logic;
signal	nmim_mask	:std_logic;

--PCCatd
signal	pccs_cs		:std_logic;
signal	pccs_odat	:std_logic_vector(7 downto 0);
signal	pccs_doe		:std_logic;

--Speed control
signal	spc_cs		:std_logic;
signal	spc_odat		:std_logic_vector(7 downto 0);
signal	spc_doe		:std_logic;

--reset control
signal	rstc_cs		:std_logic;
signal	rstc_odat	:std_logic_vector(7 downto 0);
signal	rstc_doe		:std_logic;
signal	rstc_rst		:std_logic;

--CD-ROM function
signal	cdf_cs		:std_logic;
signal	cdf_odat		:std_logic_vector(7 downto 0);
signal	cdf_doe		:std_logic;
signal	cdc_cs		:std_logic;
signal	cdc_odat		:std_logic_vector(7 downto 0);
signal	cdc_doe		:std_logic;

--PCMCIA reg
signal	pcmcr_cs		:std_logic;
signal	pcmcr_odat	:std_logic_vector(15 downto 0);
signal	pcmcr_doe		:std_logic;

--CPU frequency register
signal	freq_cs		:std_logic;
signal	freq_odat	:std_logic_vector(7 downto 0);
signal	freq_doe		:std_logic;
constant freq_MHz		:integer	:=SCFREQ/1000;
signal	freq_bin		:std_logic_vector(6 downto 0);

--CPU MISC3 reg.
signal	cm3_cs		:std_logic;
signal	cm3_odat		:std_logic_vector(7 downto 0);
signal	cm3_doe		:std_logic;


--CRT status reg.
signal	vsnc_cs		:std_logic;
signal	vsnc_odat	:std_logic_vector(7 downto 0);
signal	vsnc_doe		:std_logic;

signal	vlayw_cs		:std_logic;
signal	vlayr_cs		:std_logic;
signal	vlayr_odat	:std_logic_vector(7 downto 0);
signal	vlayr_doe	:std_logic;
signal	vlayval		:std_logic_vector(3 downto 0);

--usec freeruncounter
signal	usc_cs		:std_logic;
signal	usc_odat		:std_logic_vector(15 downto 0);
signal	usc_doe		:std_logic;

--townspad6
signal	pad6comA,pad6comB	:std_logic;
signal	pad6_A,pad6_B	:std_logic_vector(5 downto 0);

--MiSTer interface
signal	MiST_BUSY	:std_logic;

component SDRAMC
	generic(
		ADRWIDTH		:integer	:=25;
		COLSIZE		:integer	:=9;
		CLKMHZ			:integer	:=100;			--MHz
		REFCYC			:integer	:=64000/8192	--usec
	);
	port(
		-- SDRAM PORTS
		PMEMCKE			: OUT	STD_LOGIC;							-- SD-RAM CLOCK ENABLE
		PMEMCS_N			: OUT	STD_LOGIC;							-- SD-RAM CHIP SELECT
		PMEMRAS_N		: OUT	STD_LOGIC;							-- SD-RAM ROW/RAS
		PMEMCAS_N		: OUT	STD_LOGIC;							-- SD-RAM /CAS
		PMEMWE_N			: OUT	STD_LOGIC;							-- SD-RAM /WE
		PMEMUDQ			: OUT	STD_LOGIC;							-- SD-RAM UDQM
		PMEMLDQ			: OUT	STD_LOGIC;							-- SD-RAM LDQM
		PMEMBA1			: OUT	STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 1
		PMEMBA0			: OUT	STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 0
		PMEMADR			: OUT	STD_LOGIC_VECTOR( 12 DOWNTO 0 );	-- SD-RAM ADDRESS
		PMEMDAT			: INOUT	STD_LOGIC_VECTOR( 15 DOWNTO 0 );	-- SD-RAM DATA

		CPUADR			:in std_logic_vector(ADRWIDTH-1 downto 0);
		CPURDAT			:out std_logic_vector(15 downto 0);
		CPUWDAT			:in std_logic_vector(15 downto 0);
		CPUWR				:in std_logic;
		CPURD				:in std_logic;
		CPUBLEN			:in std_logic_vector(COLSIZE-1 downto 0);
		CPUBSEL			:in std_logic_vector(1 downto 0);
		CPURVAL			:out std_logic;
		CPUBNUM			:out std_logic_vector(COLSIZE-1 downto 0);
		CPUDONE			:out std_logic;
		
		SUBADR			:in std_logic_vector(ADRWIDTH-1 downto 0);
		SUBRDAT			:out std_logic_vector(15 downto 0);
		SUBWDAT			:in std_logic_vector(15 downto 0);
		SUBWR				:in std_logic;
		SUBRD				:in std_logic;
		SUBBLEN			:in std_logic_vector(COLSIZE-1 downto 0);
		SUBBSEL			:in std_logic_vector(1 downto 0);
		SUBRVAL			:out std_logic;
		SUBBNUM			:out std_logic_vector(COLSIZE-1 downto 0);
		SUBDONE			:out std_logic;
		
		KCGADR			:in std_logic_vector(ADRWIDTH-1 downto 0)	:=(others=>'0');
		KCGRD				:in std_logic								:='0';
		KCGWR				:in std_logic								:='0';
		KCGBSEL			:in std_logic_vector(1 downto 0)		:="00";
		KCGRDAT			:out std_logic_Vector(15 downto 0);
		KCGWDAT			:in std_logic_vector(15 downto 0)	:=(others=>'0');
		KCGRVAL			:out std_logic;
		KCGDONE			:out std_logic;
		
		VIDADR			:in std_logic_vector(ADRWIDTH-1 downto 0);
		VIDDAT			:out std_logic_vector(15 downto 0);
		VIDRD				:in std_logic;
		VIDBLEN			:in std_logic_vector(COLSIZE-1 downto 0);
		VIDRVAL			:out std_logic;
		VIDBNUM			:out std_logic_vector(COLSIZE-1 downto 0);
		VIDDONE			:out std_logic;

		FDEADR			:in std_logic_vector(ADRWIDTH-1 downto 0)	:=(others=>'0');
		FDERD				:in std_logic								:='0';
		FDEWR				:in std_logic								:='0';
		FDERDAT			:out std_logic_Vector(15 downto 0);
		FDEWDAT			:in std_logic_vector(15 downto 0)	:=(others=>'0');
		FDEDONE			:out std_logic;
		
		FECADR			:in std_logic_vector(ADRWIDTH-1 downto 0)	:=(others=>'0');
		FECRDAT			:out std_logic_vector(15 downto 0);
		FECWDAT			:in std_logic_vector(15 downto 0)	:=(others=>'0');
		FECRD				:in std_logic								:='0';
		FECWR				:in std_logic								:='0';
		FECBLEN			:in std_logic_vector(COLSIZE-1 downto 0);
		FECRVAL			:out  std_logic;
		FECBNUM			:out std_logic_vector(COLSIZE-1 downto 0);
		FECDONE			:out std_logic;
		
		SNDADR			:in std_logic_vector(ADRWIDTH-1 downto 0)	:=(others=>'0');
		SNDRD				:in std_logic								:='0';
		SNDWR				:in std_logic								:='0';
		SNDRDAT			:out std_logic_Vector(15 downto 0);
		SNDWDAT			:in std_logic_vector(15 downto 0)	:=(others=>'0');
		SNDDONE			:out std_logic;
		
		mem_inidone		:out std_logic;
		
		clk			:in std_logic;
		rstn			:in std_logic
	);
end component;

component memcont
generic(
	addrlen	:integer	:=23;
	colsize	:integer	:=9
);
port(
	bus_addr	:in std_logic_Vector(addrlen-2 downto 0);
	bus_rd	:in std_logic;
	bus_wr	:in std_logic;
	bus_rvrd	:in std_logic;
	bus_rvwr	:in std_logic;
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
end component;

component ao486
port(
   clk		:in std_logic;
   rst_n		:in std_logic;
    
--	a20_enable	:in std_logic;

   --------------------------------------------------------------------------
	interrupt_do	:in std_logic;
	interrupt_vector	:in std_logic_vector(7 downto 0);
	interrupt_done		:out std_logic;
    
   -------------------------------------------------------------------------- Altera Avalon memory bus
	avm_address		:out std_logic_vector(31 downto 0);
	avm_writedata	:out std_logic_vector(31 downto 0);
	avm_byteenable	:out std_logic_vector(3 downto 0);
	avm_burstcount	:out std_logic_Vector(2 downto 0);
	avm_write		:out std_logic;
	avm_read			:out std_logic;
	
	avm_waitrequest	:in std_logic;
	avm_readdatavalid	:in std_logic;
	avm_readdata		:in std_logic_vector(31 downto 0);
    
   -------------------------------------------------------------------------- Altera Avalon io bus
	avalon_io_address		:out std_logic_Vector(15 downto 0);
	avalon_io_byteenable	:out std_logic_vector(3 downto 0);
	
	avalon_io_read				:out std_logic;
	avalon_io_readdatavalid	:in std_logic;
	avalon_io_readdata		:in std_logic_vector(31 downto 0);
	
	avalon_io_write		:out std_logic;
	avalon_io_writedata	:out std_logic_Vector(31 downto 0);
    
	avalon_io_waitrequest	:in std_logic
);
end component;

component busbusy
port(
	rdreq	:in std_logic;
	wrreq	:in std_logic;
	rdval	:in std_logic;
	ramwait	:in std_logic;
	
	busy	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component dma71071
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
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component inicopy
generic(
	AWIDTH	:integer	:=20
);
port(
	ini_en	:in std_logic;
	ini_addr	:in std_logic_Vector(AWIDTH-1 downto 0);
	ini_oe	:in std_logic;
	ini_wdat	:in std_logic_vector(7 downto 0);
	ini_wr	:in std_logic;
	ini_ack	:out std_logic;
	ini_done	:in std_logic;

	wraddr	:out std_logic_vector(AWIDTH-1 downto 2);
	wdat		:out std_logic_vector(31 downto 0);
	aen		:out std_logic;
	wr			:out std_logic;
	ack		:in std_logic;
	done		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component memorymap
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
	
	clk			:in std_logic;
	rstn			:in std_logic
);
end component;

component iocont
port(
	cpuaddr	:in std_logic_vector(15 downto 2);
	cpurd		:in std_logic;
	cpuwr		:in std_logic;
	cpubyteen	:in std_logic_vector(3 downto 0);
	cpuwdat	:in std_logic_vector(31 downto 0);

	dwaddr	:out std_logic_vector(15 downto 0);
	swaddr	:out std_logic_vector(15 downto 0);
	baddr		:out std_logic_vector(15 downto 0);
	iobyteen	:out std_logic_vector(3 downto 0);
	
	iord		:out std_logic;
	iowr		:out std_logic;
	iowdat	:out std_logic_Vector(31 downto 0);
	ioswdat	:out std_logic_vector(15 downto 0);
	iobwdat	:out std_logic_vector(7 downto 0);
	iowait	:in std_logic;
	
	rdval		:out std_logic;
	waitreq	:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component pic8259
port(
	CS		:in std_logic;
	ADDR	:in std_logic;
	DIN		:in std_logic_vector(7 downto 0);
	DOUT	:out std_logic_vector(7 downto 0);
	DOE		:out std_logic;
	RD		:in std_logic;
	WR		:in std_logic;
	
	IR0		:in std_logic;
	IR1		:in std_logic;
	IR2		:in std_logic;
	IR3		:in std_logic;
	IR4		:in std_logic;
	IR5		:in std_logic;
	IR6		:in std_logic;
	IR7		:in std_logic;
	
	INT		:out std_logic;
	IVECT		:out std_logic_vector(7 downto 0);
	VECTOE	:out std_logic;
	INTA	:in std_logic;
	
	CASI	:in std_logic_vector(2 downto 0);
	CASO	:out std_logic_vector(2 downto 0);
	CASM	:in std_logic;
	SLINTA:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component cmosram
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
end component;

component timerint
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
end component;

component PTC8253
port(
	CS		:in std_logic;
	ADDR	:in std_logic_vector(1 downto 0);
	RD		:in std_logic;
	WR		:in std_logic;
	RDAT	:out std_logic_vector(7 downto 0);
	WDAT	:in std_logic_vector(7 downto 0);
	DOE		:out std_logic;
	
	CNTIN	:in std_logic_vector(2 downto 0);
	TRIG	:in std_logic_vector(2 downto 0);
	CNTOUT	:out std_logic_vector(2 downto 0);
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component CRTCREG
port(
	cs		:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	odat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	HSW1	:out std_logic_vector(7 downto 1);
	HSW2	:out std_logic_vector(10 downto 1);
	HST	:out std_logic_vector(10 downto 1);
	VST1	:out std_logic_vector(4 downto 0);
	VST2	:out std_logic_vector(4 downto 0);
	EET	:out std_logic_vector(4 downto 0);
	VST	:out std_logic_vector(10 downto 0);
	HDS0	:out std_logic_vector(10 downto 0);
	HDE0	:out std_logic_vector(10 downto 0);
	HDS1	:out std_logic_vector(10 downto 0);
	HDE1	:out std_logic_vector(10 downto 0);
	VDS0	:out std_logic_vector(10 downto 0);
	VDE0	:out std_logic_vector(10 downto 0);
	VDS1	:out std_logic_vector(10 downto 0);
	VDE1	:out std_logic_vector(10 downto 0);
	FA0	:out std_logic_vector(15 downto 0);
	HAJ0	:out std_logic_vector(10 downto 0);
	FO0	:out std_logic_vector(15 downto 0);
	LO0	:out std_logic_vector(15 downto 0);
	FA1	:out std_logic_vector(15 downto 0);
	HAJ1	:out std_logic_vector(10 downto 0);
	FO1	:out std_logic_vector(15 downto 0);
	LO1	:out std_logic_vector(15 downto 0);
	EHAJ	:out std_logic_vector(10 downto 0);
	EVAJ	:out std_logic_vector(10 downto 0);
	ZV1	:out std_logic_vector(3 downto 0);
	ZH1	:out std_logic_vector(3 downto 0);
	ZV0	:out std_logic_vector(3 downto 0);
	ZH0	:out std_logic_vector(3 downto 0);
	CL0	:out std_logic_vector(1 downto 0);
	CL1	:out std_logic_vector(1 downto 0);
	CEN0	:out std_logic;
	CEN1	:out std_logic;
	ESM0	:out std_logic;
	ESM1	:out std_logic;
	ESYN	:out std_logic;
	START	:out std_logic;
	
	DSPTV1	:in std_logic;
	DSPTV0	:in std_logic;
	DSPTH1	:in std_logic;
	DSPTH0	:in std_logic;
	FIELD		:in std_logic;
	VSYNC		:in std_logic;
	HSYNC		:in std_logic;
	VIDIN		:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component VIDCREG
port(
	cs		:in std_logic;
	addr	:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	
	CLMODE	:out std_logic_vector(3 downto 0);
	PMODE		:out std_logic;
	
	PLT		:out std_logic_vector(1 downto 0);
	YS			:out std_logic;
	YM			:out std_logic;
	PR1		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component KBCONV
generic(
	CLKCYC	:integer	:=20000;
	SFTCYC	:integer	:=400;
	RPSET	:integer	:=1
);
port(
	cs		:in std_logic;
	addr	:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	
	KBCLKIN	:in std_logic;
	KBCLKOUT:out std_logic;
	KBDATIN	:in std_logic;
	KBDATOUT:out std_logic;

	mous_recv	:in std_logic;
	mous_clr		:out std_logic;
	mous_Xdat	:in std_logic_vector(9 downto 0);
	mous_Ydat	:in std_logic_Vector(9 downto 0);
	mous_swdat	:in std_logic_vector(1 downto 0);
		
	emuen		:in std_logic;
	emurx		:out std_logic;
	emurxdat	:out std_logic_vector(7 downto 0);

	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component MOUSERECV
generic(
	CLKCYC	:integer	:=20000;
	SFTCYC	:integer	:=400
);
port(
	MCLKIN	:in std_logic;
	MCLKOUT:out std_logic;
	MDATIN	:in std_logic;
	MDATOUT:out std_logic;
	
	Xdat		:out std_logic_vector(9 downto 0);
	Ydat		:out std_logic_vector(9 downto 0);
	swdat		:out std_logic_Vector(1 downto 0);
	
	recv		:out std_logic;
	clr		:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component atarimouse
generic(
	CLKFREQ	:integer	:=20000;	--kHz
	TOUTLEN	:integer	:=150		--usec
);
port(
	PADOUT	:out std_logic_vector(5 downto 0);
	STROBE	:in std_logic;
	
	Xdat		:in std_logic_vector(9 downto 0);
	Ydat		:in std_logic_vector(9 downto 0);
	SWdat		:in std_logic_Vector(1 downto 0);
	clear		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component IDROMIF
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component scsiif
port(
	cs		:in std_logic;
	addr	:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	drq	:out std_logic;
	dack	:in std_logic;
	drdat	:out std_logic_vector(15 downto 0);
	dwdat	:in std_logic_vector(15 downto 0);
	
	SEL	:out std_logic;
	RST	:out std_logic;
	ATN	:out std_logic;
	ACK	:out std_logic;
	
	REQ	:in std_logic;
	IO		:in std_logic;
	MSG	:in std_logic;
	CD		:in std_logic;
	BUSY	:in std_logic;
	
	DATOUT:out std_logic_vector(7 downto 0);
	DATIN	:in std_logic_vector(7 downto 0);
	DOUTEN:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component scsidev
generic(
	clkfreq	:integer	:=10000;	--kHz
	toutlen	:integer	:=100;	--msec
	sectwid	:integer	:=9
);
port(
	IDAT		:in std_logic_vector(7 downto 0);
	ODAT		:out std_logic_vector(7 downto 0);
	SEL		:in std_logic;
	BSYI		:in std_logic;
	BSYO		:out std_logic;
	REQ		:out std_logic;
	ACK		:in std_logic;
	IO			:out std_logic;
	CD			:out std_logic;
	MSG		:out std_logic;
	ATN		:in std_logic;
	RST		:in std_logic;
	
	idsel		:in integer range 0 to 7;
	
	unit		:out std_logic_vector(2 downto 0);
	capacity	:in std_logic_vector(63 downto 0);
	lba		:out std_logic_vector(31 downto 0);
	rdreq		:out std_logic;
	wrreq		:out std_logic;
	syncreq	:out std_logic;
	sectaddr	:out std_logic_vector(sectwid-1 downto 0);
	rddat		:in std_logic_vector(7 downto 0);
	wrdat		:out std_logic_vector(7 downto 0);
	sectbusy	:in std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component scsibuf
generic(
	sectwidth	:integer	:=9
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
end component;

component padio
port(
	cs		:in std_logic;
	addr	:in std_logic;
	bsel	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	padain	:in std_logic_Vector(6 downto 0);
	padbin	:in std_logic_Vector(6 downto 0);
	triga1	:out std_logic;
	triga2	:out std_logic;
	trigb1	:out std_logic;
	trigb2	:out std_logic;
	coma		:out std_logic;
	comb		:out std_logic;
	fmmute	:out std_logic;
	pcmmute	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component iorw
generic(
	ioaddr	:std_logic_vector(15 downto 0)	:=x"0000";
	regen	:std_logic_vector(7 downto 0)
);
port(
	addr	:in std_logic_vector(15 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	do0	:out std_logic;
	do1	:out std_logic;
	do2	:out std_logic;
	do3	:out std_logic;
	do4	:out std_logic;
	do5	:out std_logic;
	do6	:out std_logic;
	do7	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component anapal
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(1 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	plt	:in std_logic_vector(1 downto 0);
	
	c8in	:in std_logic_vector(7 downto 0);
	c8red	:out std_logic_vector(7 downto 0);
	c8grn	:out std_logic_vector(7 downto 0);
	c8blu	:out std_logic_vector(7 downto 0);
	
	c41in		:in std_logic_vector(3 downto 0);
	c41red	:out std_logic_vector(3 downto 0);
	c41grn	:out std_logic_vector(3 downto 0);
	c41blu	:out std_logic_vector(3 downto 0);

	c42in		:in std_logic_vector(3 downto 0);
	c42red	:out std_logic_vector(3 downto 0);
	c42grn	:out std_logic_vector(3 downto 0);
	c42blu	:out std_logic_vector(3 downto 0);

	sclk		:in std_logic;
	vclk		:in std_logic;
	rstn		:in std_logic
);
end component;

component digpal
port(
	cs		:in std_logic;
	addr	:in std_logic_Vector(2 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	wrote	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component rvidreg
port(
	mcs	:in std_logic;
	maddr	:in std_logic;
	mbsel	:in std_logic_vector(3 downto 0);
	mrd	:in std_logic;
	mwr	:in std_logic;
	mrdat	:out std_logic_vector(31 downto 0);
	mwdat	:in std_logic_vector(31 downto 0);
	mrval	:out std_logic;
	
	iocs	:in std_logic;
	ioaddr:in std_logic_vector(2 downto 0);
	iord	:in std_logic;
	iowr	:in std_logic;
	iordat	:out std_logic_vector(7 downto 0);
	iowdat	:in std_logic_vector(7 downto 0);
	iodoe		:out std_logic;
	
	rvid_dispen	:out std_logic_vector(3 downto 0);
	rvid_disppage:out std_logic;
	
	rvid_wrsel	:out std_logic_vector(3 downto 0);
	rvid_rdsel	:out std_logic_vector(1 downto 0);
	rvid_cpupage:out std_logic;
	
	hsync	:in std_logic;
	vsync	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component dpmreg
port(
	cs		:in std_logic;
	rd		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	palwr	:in std_logic;
	spbusy:in std_logic;
	sbpage:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component tvideo
port(
	HSW1	:in std_logic_vector(7 downto 0);
	HSW2	:in std_logic_vector(10 downto 0);
	HST	:in std_logic_vector(10 downto 0);
	
	VST1	:in std_logic_vector(4 downto 0);
	VST2	:in std_logic_vector(4 downto 0);
	EET	:in std_logic_vector(4 downto 0);
	VST	:in std_logic_vector(10 downto 0);
	
	HDS0	:in std_logic_vector(10 downto 0);
	HDE0	:in std_logic_vector(10 downto 0);
	HDS1	:in std_logic_vector(10 downto 0);
	HDE1	:in std_logic_vector(10 downto 0);
	VDS0	:in std_logic_vector(10 downto 0);
	VDE0	:in std_logic_vector(10 downto 0);
	VDS1	:in std_logic_vector(10 downto 0);
	VDE1	:in std_logic_vector(10 downto 0);
	ZH0	:in std_logic_vector(3 downto 0);
	ZH1	:in std_logic_vector(3 downto 0);

	HCOMP	:out std_logic;
	HHCOMP:out std_logic;
	VCOMP	:out std_logic;
	
	RMODE	:in std_logic;
	PMODE	:in std_logic;
	CL1	:in std_logic_Vector(1 downto 0);
	CL0	:in std_logic_vector(1 downto 0);
	RPEN	:in std_logic_vector(3 downto 0);
	
	VID1EN	:out std_logic;
	VID1LINE	:out std_logic_vector(10 downto 0);
	VID1ADDR	:out std_logic_vector(10 downto 0);
	VID1DATA	:in std_logic_vector(15 downto 0);
	VID1RDATA:in std_logic_vector(3 downto 0);
	
	VID2EN	:out std_logic;
	VID2LINE	:out std_logic_vector(10 downto 0);
	VID2ADDR	:out std_logic_vector(10 downto 0);
	VID2DATA	:in std_logic_vector(15 downto 0);
	
	PR1	:in std_logic;
	PAL8ADDR	:out std_logic_vector(7 downto 0);
	PAL8RED	:in std_logic_vector(7 downto 0);
	PAL8GRN	:in std_logic_vector(7 downto 0);
	PAL8BLU	:in std_logic_vector(7 downto 0);
	
	PAL41ADDR	:out std_logic_vector(3 downto 0);
	PAL41RED		:in std_logic_vector(3 downto 0);
	PAL41GRN		:in std_logic_vector(3 downto 0);
	PAL41BLU		:in std_logic_vector(3 downto 0);

	PAL42ADDR	:out std_logic_vector(3 downto 0);
	PAL42RED		:in std_logic_vector(3 downto 0);
	PAL42GRN		:in std_logic_vector(3 downto 0);
	PAL42BLU		:in std_logic_vector(3 downto 0);
	
	vidR	:out std_logic_vector(7 downto 0);
	vidG	:out std_logic_vector(7 downto 0);
	vidB	:out std_logic_vector(7 downto 0);
	vidHS	:out std_logic;
	vidCS	:out std_logic;
	vidVS	:out std_logic;
	vidHen:out std_logic;
	vidVen:out std_logic;
	viden	:out std_logic;
	vidclk:out std_logic;
	
	hven0	:out std_logic;
	hven1	:out std_logic;
	vven0	:out std_logic;
	vven1	:out std_logic;
	
	dotclk:out std_logic;
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component videocont
generic(
	ADDRWIDTH:integer	:=25;
	COLSIZE	:integer	:=9
);
port(
	
	HDS0	:in std_logic_vector(10 downto 0);
	HDE0	:in std_logic_vector(10 downto 0);
	ZH0	:in std_logic_vector(3 downto 0);
	ZV0	:in std_logic_vector(3 downto 0);
	FA0	:in std_logic_vector(15 downto 0);
	FO0	:in std_logic_vector(15 downto 0);
	LO0	:in std_logic_vector(15 downto 0);
	CL0	:in std_logic_vector(1 downto 0);
	V0EN	:in std_logic;
	PAGESEL0:in  std_logic;

	HDS1	:in std_logic_vector(10 downto 0);
	HDE1	:in std_logic_vector(10 downto 0);
	ZH1	:in std_logic_vector(3 downto 0);
	ZV1	:in std_logic_vector(3 downto 0);
	FA1	:in std_logic_vector(15 downto 0);
	FO1	:in std_logic_vector(15 downto 0);
	LO1	:in std_logic_vector(15 downto 0);
	CL1	:in std_logic_vector(1 downto 0);
	PMODE	:in std_logic;
	V1EN	:in std_logic;
	PAGESEL1:in  std_logic;
	
	HCOMP	:in std_logic;
	HHCOMP	:in std_logic;
	VCOMP	:in std_logic;
	
	ram_addr	:out std_logic_vector(ADDRWIDTH-1 downto 0);
	ram_blen	:out std_logic_vector(COLSIZE-1 downto 0);
	ram_rd	:out std_logic;
	ram_rval	:in std_logic;
	ram_num	:in std_logic_vector(COLSIZE-1 downto 0);
	ram_rdat	:in std_logic_vector(15 downto 0);
	ram_done	:in std_logic;
	
	fram0_addr	:in std_logic_vector(10 downto 0);
	fram0_data	:out std_logic_vector(15 downto 0);
	fram0r_data	:out std_logic_vector(3 downto 0);

	fram1_addr	:in std_logic_vector(10 downto 0);
	fram1_data	:out std_logic_vector(15 downto 0);
	fram1r_data	:out std_logic_vector(3 downto 0);

	vclk	:in std_logic;
	rclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component kcgmemcont is
generic(
	addrlen	:integer	:=23
);
port(
	bus_rd	:in std_logic;
	bus_wr	:in std_logic;
	bus_done	:out std_logic;
	busclk	:in std_logic;
	
	mem_rd	:out std_logic;
	mem_wr	:out std_logic;
	mem_done	:in std_logic;
	memclk	:in std_logic;
	
	rstn		:in std_logic
);
end component;

component rkanjcg
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
end component;

component tvwrote
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	wrote	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component vsint
port(
	cs		:in std_logic;
	wr		:in std_logic;
	
	vsync	:in std_logic;
	int	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component inttim2
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	bsel	:in std_logic_Vector(3 downto 0);
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_Vector(31 downto 0);
	doe	:out std_logic;
	int	:out std_logic;
	
	sft	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component MiST8877
generic(
	drives	:integer	:=2
);
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(1 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe		:out std_logic;
	drq		:out std_logic;
	drdat	:out std_logic_vector(7 downto 0);
	dwdat	:in std_logic_vector(7 downto 0);
	dack	:in std_logic;
	int		:out std_logic;
	
	dsel	:in std_logic_vector(drives-1 downto 0);
	head	:in std_logic;
	motor	:in std_logic_vector(drives-1 downto 0);
	dready	:out std_logic;
	
	seekwait	:in std_logic;
	txwait	:in std_logic;
	
	mist_mounted	:in std_logic_vector(drives-1 downto 0);
	mist_readonly	:in std_logic_vector(drives-1 downto 0);
	mist_imgsize	:in std_logic_vector(63 downto 0);
	mist_lba		:out std_logic_vector(31 downto 0);
	mist_rd			:out std_logic_vector(drives-1 downto 0);
	mist_wr			:out std_logic_vector(drives-1 downto 0);
	mist_ack		:in std_logic;
	mist_buffaddr	:in std_logic_vector(8 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffdin	:out std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;
	
	mist_busyout	:out std_logic;
	mist_busyin		:in std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component fdcont
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(2 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	ready	:in std_logic;
	irqmsk:out std_logic;
	dden	:out std_logic;
	hdsel	:out std_logic;
	motor	:out std_logic;
	clksel:out std_logic;
	dsel	:out std_logic_vector(3 downto 0);
	inuse	:out std_logic;
	speed	:out std_logic;
	drvchg:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component sftgen
generic(
	maxlen	:integer	:=100
);
port(
	len		:in integer range 0 to maxlen;
	sft		:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component memclr
generic(
	ADDRWIDTH	:integer	:=25;
	COLSIZE		:integer	:=9
);
port(
	ADDR			:out std_logic_Vector(ADDRWIDTH-1 downto 0);
	WR				:out std_logic;
	WRDONE		:in std_logic;
	DONE			:out std_logic;
	
	clk			:in std_logic;
	rstn			:in std_logic
);
end component;

component rextreg
port(
	mcs	:in std_logic;
	mbsel	:in std_logic_vector(3 downto 0);
	mrd	:in std_logic;
	mwr	:in std_logic;
	mrdat	:out std_logic_vector(31 downto 0);
	mwdat	:in std_logic_vector(31 downto 0);
	mrval	:out std_logic;
	
	iocs	:in std_logic;
	ioaddr:in std_logic;
	iord	:in std_logic;
	iowr	:in std_logic;
	iordat	:out std_logic_vector(7 downto 0);
	iowdat	:in std_logic_vector(7 downto 0);
	iodoe		:out std_logic;

	ANKCG		:out std_logic;
	BEEPEN	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component  dummyreg
port(
	mcs	:in std_logic;
	mrd	:in std_logic;
	mrval	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component PATRAM
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
end component;

component cdif
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rddat	:out std_logic_vector(7 downto 0);
	wrdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	drq	:out std_logic;
	dack	:in std_logic;
	irq	:out std_logic;
	drdat	:out std_logic_vector(7 downto 0);
	
	mist_mounted	:in std_logic;
	mist_imgsize	:in std_logic_vector(63 downto 0);
	mist_lba	:out std_logic_vector(31 downto 0);
	mist_rd	:out std_logic;
	mist_ack	:in std_logic;
	mist_bufaddr	:in std_logic_vector(8 downto 0);
	mist_buffdout	:in std_logic_vector(7 downto 0);
	mist_buffwr		:in std_logic;
	
	mist_busyout	:out std_logic;
	mist_busyin		:in std_logic;

	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component rtc58321 is
generic(
	clkfreq	:integer	:=20000;
	YEAROFF	:std_logic_vector(7 downto 0)	:=x"00"
);
port(
	cs		:in std_logic;
	addr	:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	rdat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	RTCIN	:in std_logic_vector(64 downto 0);
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component OPN2
generic(
	res		:integer	:=16
);
port(
	DIN		:in std_logic_vector(7 downto 0);
	DOUT	:out std_logic_vector(7 downto 0);
	DOE		:out std_logic;
	CSn		:in std_logic;
	ADR		:in std_logic_vector(1 downto 0);
	RDn		:in std_logic;
	WRn		:in std_logic;
	INTn	:out std_logic;
	
	sndL		:out std_logic_vector(res-1 downto 0);
	sndR		:out std_logic_vector(res-1 downto 0);

	clk		:in std_logic;
	cpuclk	:in std_logic;
	sft		:in std_logic;
	rstn	:in std_logic
);
end component;

component lenwait
generic(
	len	:integer	:=100
);
port(
	cs		:in std_logic;
	wr		:in std_logic;
	
	wreq	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component  kbint
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	kbint	:in std_logic;
	kbnmi	:in std_logic;
	
	int	:out std_logic;
	nmi	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component vmaskreg
port(
	cs		:in std_logic;
	wr		:in std_logic;
	rd		:in std_logic;
	bsel	:in std_logic_Vector(3 downto 0);
	rdat	:out std_logic_vector(31 downto 0);
	wdat	:in std_logic_vector(31 downto 0);
	doe	:out std_logic;
	
	mbsel	:out std_logic_vector(3 downto 0);
	mask	:out std_logic_vector(31 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component e8251
port(
	WRn		:in std_logic;
	RDn		:in std_logic;
	C_Dn	:in std_logic;
	CSn		:in std_logic;
	DATIN	:in std_logic_vector(7 downto 0);
	DATOUT	:out std_logic_vector(7 downto 0);
	DATOE	:out std_logic;
	INTn	:out std_logic;
	
	TXD		:out std_logic;
	RxD		:in std_logic;
	
	DSRn	:in std_logic;
	DTRn	:out std_logic;
	RTSn	:out std_logic;
	CTSn	:in std_logic;
	
	TxRDY	:out std_logic;
	TxEMP	:out std_logic;
	RxRDY	:out std_logic;
	
	TxCn	:in std_logic;
	RxCn	:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component nmimskr
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_Vector(7 downto 0);
	doe	:out std_logic;
	
	nmimsk	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component iobin
port(
	cs		:in std_logic;
	rd		:in std_logic;
	odat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	in0	:in std_logic;
	in1	:in std_logic;
	in2	:in std_logic;
	in3	:in std_logic;
	in4	:in std_logic;
	in5	:in std_logic;
	in6	:in std_logic;
	in7	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component iobout
port(
	cs		:in std_logic;
	wr		:in std_logic;
	indat	:in std_logic_vector(7 downto 0);
	
	out0	:out std_logic;
	out1	:out std_logic;
	out2	:out std_logic;
	out3	:out std_logic;
	out4	:out std_logic;
	out5	:out std_logic;
	out6	:out std_logic;
	out7	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component resetcont
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
end component;

component spcont
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rddat	:out std_logic_vector(7 downto 0);
	wrdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	HISPEED	:out std_logic;
	HSPDEN	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component cdcachec
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_Vector(7 downto 0);
	wdat	:in std_logic_Vector(7 downto 0);
	doe	:out std_logic;
	
	cache		:in std_logic;
	cacheen	:out std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component pcmcreg
port(
	cs		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic;
	ben	:in std_logic_vector(1 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	doe	:out std_logic;
	
	bank	:out std_logic_vector(5 downto 0);
	reg	:out std_logic;
	ver4	:in std_logic;
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component PCMREG
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	
	chsel	:in std_logic_vector(2 downto 0);
	env	:out std_logic_vector(7 downto 0);
	panL	:out std_logic_vector(3 downto 0);
	panR	:out std_logic_vector(3 downto 0);
	FD		:out std_logic_vector(15 downto 0);
	LS		:out std_logic_vector(15 downto 0);
	ST		:out std_logic_vector(7 downto 0);
	WB		:out std_logic_vector(3 downto 0);
	ONOFF	:out std_logic;
	CHON	:out std_logic_vector(7 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component SOUNDREG
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	VR0		:out std_logic_vector(6 downto 0);
	VR1		:out std_logic_vector(6 downto 0);
	VR2		:out std_logic_vector(6 downto 0);
	VR3		:out std_logic_vector(6 downto 0);
	VR4		:out std_logic_vector(6 downto 0);
	VR5		:out std_logic_vector(6 downto 0);
	VR6		:out std_logic_vector(6 downto 0);
	VR7		:out std_logic_vector(6 downto 0);
	mute0		:out std_logic;
	mute1		:out std_logic;
	mute2		:out std_logic;
	mute3		:out std_logic;
	mute4		:out std_logic;
	mute5		:out std_logic;
	mute6		:out std_logic;
	mute7		:out std_logic;
	ADdata	:in std_logic_vector(7 downto 0);
	ADflag	:in std_logic;
	ADclear	:out std_logic;
	intOPN	:in std_logic;
	intPCM	:in std_logic_Vector(7 downto 0);
	LOFF		:out std_logic;
	MUTE		:out std_logic;
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

component freecount
port(
	cs		:in std_logic;
	rd		:in std_logic;
	odat	:out std_logic_Vector(15 downto 0);
	doe	:out std_logic;
	
	sft	:in std_logic;
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component ioexc
port(
	baddr	:in std_logic_vector(15 downto 0);
	
	exc	:out std_logic
);
end component;

component HEX2SEGn
	port(
		HEX	:in std_logic_vector(3 downto 0);
		DOT	:in std_logic;
		SEG	:out std_logic_vector(7 downto 0)
	);
end component;

component ixcount
generic(
	cwidth	:integer	:=32
);
port(
	cin	:in std_logic;
	
	cout	:out std_logic_vector(cwidth-1 downto 0);
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component stclk is
port(
	datin	:in std_logic;
	clk	:in std_logic;
	
	stclk	:out std_logic
);
end component;

component townspad6
port(
	Un		:in std_logic;
	Dn		:in std_logic;
	Ln		:in std_logic;
	Rn		:in std_logic;
	An		:in std_logic;
	Bn		:in std_logic;
	Cn		:in std_logic;
	Xn		:in std_logic;
	Yn		:in std_logic;
	Zn		:in std_logic;
	seln	:in std_logic;
	runn	:in std_logic;
	
	com	:in std_logic;
	pin1	:out std_logic;
	pin2	:out std_logic;
	pin3	:out std_logic;
	pin4	:out std_logic;
	pin6	:out std_logic;
	pin7	:out std_logic
);
end component;

begin

	
	ramrstn<=plllock;
	deprstn<=plllock and sdr_initdone and clr_done;
	clr_rstn<=plllock and sdr_initdone;
	ldr_rstn<=deprstn and rstn;
	sysrstn<=deprstn and rstn and ldr_done;
	
	DEBSEL<=	'1' when debclk="000" else
				(cpu_memrd and not cpu_memwait) or (cpu_memwr and not cpu_memwait) or mem_rdval when debclk="001" else
				cpu_iord or cpu_iowr or cpu_iorval when debclk="010" else
				dmac_muse when debclk="011" else
				cpu_intdone when debclk="100" else
				cpu_iord or cpu_iowr or cpu_iorval or dmac_muse when debclk="101" else
				(cpu_memrd and not cpu_memwait) or (cpu_memwr and not cpu_memwait) or mem_rdval or cpu_iord or cpu_iowr or cpu_iorval or dmac_muse or cpu_intdone when debclk="111" else
				'0';

	stc	:stclk port map(
		datin	=>DEBSEL,
		clk	=>sysclk,
		stclk	=>open
	);
	
	
	process(sysclk,sysrstn)
	variable lCLKSEL	:std_logic_vector(1 downto 0);
	begin
		if(sysrstn='0')then
			vidrstn<='0';
			lCLKSEL:="00";
		elsif(sysclk' event and sysclk='1')then
			if(lCLKSEL/=vCLKSEL)then
				vidrstn<='0';
			else
				vidrstn<='1';
			end if;
			lCLKSEL:=vCLKSEL;
		end if;
	end process;
	
--	vidclk<=	vidclk0	when vCLKSEL="00" else
--				vidclk1	when vCLKSEL="01" else
--				vidclk2	when vCLKSEL="10" else
--				vidclk3	when vCLKSEL="11" else
--				vidclk0;
--	
--	vclkout<=vidclk2;
				
	VCLKSEL<="10";
	
	MEM	:SDRAMC generic map(
		ADRWIDTH		=>RAMAWIDTH,
		COLSIZE		=>9,
		CLKMHZ		=>RCFREQ,
		REFCYC		=>64000/8192	--usec
	)port map(
		-- SDRAM PORTS
		PMEMCKE			=>pMemCke,
		PMEMCS_N			=>pMemCs_n,
		PMEMRAS_N		=>pMemRas_n,
		PMEMCAS_N		=>pMemCas_n,
		PMEMWE_N			=>pMemWe_n,
		PMEMUDQ			=>pMemUdq,
		PMEMLDQ			=>pMemLdq,
		PMEMBA1			=>pMemBa1,
		PMEMBA0			=>pMemBa0,
		PMEMADR			=>pMemAdr,
		PMEMDAT			=>pMemDat,

		CPUADR			=>sdr_comaddr,
		CPURDAT			=>sdr_cpurddata,
		CPUWDAT			=>sdr_comwrdata,
		CPUWR				=>sdr_comwr,
		CPURD				=>sdr_cpurd,
		CPUBLEN			=>sdr_cpublen,
		CPUBSEL			=>sdr_combsel,
		CPURVAL			=>sdr_cpurval,
		CPUBNUM			=>sdr_cpubnum,
		CPUDONE			=>sdr_cpudone,
		
		SUBADR			=>(others=>'0'),
		SUBRDAT			=>open,
		SUBWDAT			=>(others=>'0'),
		SUBWR				=>'0',
		SUBRD				=>'0',
		SUBBLEN			=>(others=>'0'),
		SUBBSEL			=>(others=>'0'),
		SUBRVAL			=>open,
		SUBBNUM			=>open,
		SUBDONE			=>open,
		
		KCGADR			=>kcg_ramaddr,
		KCGRD				=>kram_rd,
		KCGWR				=>kram_wr,
		KCGBSEL			=>kcg_rambsel,
		KCGRDAT			=>kcg_ramrdat,
		KCGWDAT			=>kcg_ramwdat,
		KCGRVAL			=>open,
		KCGDONE			=>kram_done,
		
		VIDADR			=>vidram_addr,
		VIDDAT			=>vidram_rdat,
		VIDRD				=>vidram_rd,
		VIDBLEN			=>vidram_blen,
		VIDRVAL			=>vidram_rval,
		VIDBNUM			=>vidram_num,
		VIDDONE			=>vidram_done,

		FDEADR			=>(others=>'0'),
		FDERD				=>'0',
		FDEWR				=>'0',
		FDERDAT			=>open,
		FDEWDAT			=>(others=>'0'),
		FDEDONE			=>open,
		
		FECADR			=>(others=>'0'),
		FECRDAT			=>open,
		FECWDAT			=>(others=>'0'),
		FECRD				=>'0',
		FECWR				=>'0',
		FECBLEN			=>(others=>'0'),
		FECRVAL			=>open,
		FECBNUM			=>open,
		FECDONE			=>open,
		
		SNDADR			=>(others=>'0'),
		SNDRD				=>'0',
		SNDWR				=>'0',
		SNDRDAT			=>open,
		SNDWDAT			=>(others=>'0'),
		SNDDONE			=>open,
		
		mem_inidone		=>sdr_initdone,
		
		clk			=>ramclk,
		rstn			=>ramrstn
	);
	
	clr	:memclr generic map(RAMAWIDTH,9) port map(
		ADDR			=>clr_addr,
		WR				=>clr_wr,
		WRDONE		=>sdr_cpudone,
		DONE			=>clr_done,
		
		clk			=>ramclk,
		rstn			=>clr_rstn
	);
	
	sdr_comaddr<=clr_addr when clr_done='0' else sdr_cpuaddr;
	sdr_comwrdata<=(others=>'0') when clr_done='0' else sdr_cpuwrdata;
	sdr_comwr<=clr_wr when clr_done='0' else sdr_cpuwr;
	sdr_combsel<=(others=>'1') when clr_done='0' else sdr_cpubsel;
	sdr_comblen<=(others=>'0') when clr_done='0' else sdr_cpublen;

	ramc	:memcont generic map(
		addrlen	=>RAMAWIDTH,
		colsize	=>9
	)port map(
		bus_addr		=>ram_addr,
		bus_rd		=>ram_rd,
		bus_wr		=>ram_wr,
		bus_rvrd		=>ram_rvrd,
		bus_rvwr		=>ram_rvwr,
		bus_rvrsel	=>ram_rvrsel,
		bus_rvwsel	=>ram_rvwsel,
		bus_blen		=>ram_blen,
		bus_byteen	=>ram_byteen,
		bus_rdat		=>ram_rdat,
		bus_wdat		=>ram_wdat,
		bus_rdval	=>ram_rdval,
		bus_wait		=>ram_wait,
		busclk		=>sysclk,
		
		mem_addr		=>sdr_cpuaddr,
		mem_rd		=>sdr_cpurd,
		mem_wr		=>sdr_cpuwr,
		mem_blen		=>sdr_cpublen,
		mem_byteen	=>sdr_cpubsel,
		mem_rdval	=>sdr_cpurval,
		mem_num		=>sdr_cpubnum,
		mem_wdata	=>sdr_cpuwrdata,
		mem_rdata	=>sdr_cpurddata,
		mem_done		=>sdr_cpudone,
		memclk		=>ramclk,
		
		rstn			=>ramrstn
	);
	ram_addr<=	RAM_ROMSTART(RAMAWIDTH-2 downto 19) & ldr_addr when ldr_aen='1' else
					ram_cpuaddr;
	ram_rd<=	'0' when ldr_aen='1' else
				ram_cpurd;
	ram_wr<=	ldr_wr when ldr_aen='1' else
				ram_cpuwr;
	ram_blen<=	"001" when ldr_aen='1' else
					ram_cpublen;
	ram_byteen<=	"1111" when ldr_aen='1' else
						ram_cpubyteen;
	ram_wdat<=	ldr_wdat when ldr_aen='1' else
					ram_cpuwdata;

	cpu_a20en<='1';
	io_wait<=udly_wait or cmos_iwait;
	
	cpu	:ao486 port map(
		clk			=>sysclk,
		rst_n			=>cpurstn,
		 
--		a20_enable	=>cpu_a20en,

		--------------------------------------------------------------------------
		interrupt_do		=>cpu_intdo,
		interrupt_vector	=>cpu_ivect,
		interrupt_done		=>cpu_intdone,
		 
		-------------------------------------------------------------------------- Altera Avalon memory bus
		avm_address		=>cpu_memaddr,
		avm_writedata	=>cpu_memwdata,
		avm_byteenable	=>cpu_membyteen,
		avm_burstcount	=>cpu_memblen,
		avm_write		=>cpu_memwr,
		avm_read			=>cpu_memrd,
		
		avm_waitrequest	=>cpu_memwait,
		avm_readdatavalid	=>cpu_memrval,
		avm_readdata		=>cpu_memrdata,
		 
		-------------------------------------------------------------------------- Altera Avalon io bus
		avalon_io_address		=>cpu_ioaddr,
		avalon_io_byteenable	=>cpu_iobyteen,
		
		avalon_io_read				=>cpu_iord,
		avalon_io_readdatavalid	=>cpu_iorval,
		avalon_io_readdata		=>io_dbus,
		
		avalon_io_write		=>cpu_iowr,
		avalon_io_writedata	=>cpu_iowdata,
		 
		avalon_io_waitrequest	=>cpu_iowait
	);
	
	muse	:busbusy port map(
		rdreq		=>cpu_memrd,
		wrreq		=>cpu_memwr,
		rdval		=>cpu_memrval,
		ramwait	=>mem_wait,
		
		busy		=>dmac_mbusy,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	dmac_cs<='1' when io_dwaddr(15 downto 4)=x"00a" else '0';
	dma	:dma71071 port map(
		cs		=>dmac_cs,
		addr	=>io_dwaddr(3 downto 2),
		bsel	=>io_byteen,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>dmac_rdat,
		wdat	=>io_dbus,
		doe	=>dmac_doe,
		
		mbusyin	=>dmac_mbusy,
		museout	=>dmac_muse,
		maddr		=>dmac_maddr,
		mbsel		=>dmac_mbsel,
		mrd		=>dmac_mrd,
		mwr		=>dmac_mwr,
		mwait		=>mem_wait,
		mrval		=>mem_rdval,
		mrdat		=>cpu_memrdata,
		mwdat		=>dmac_mwdat,

		drq0		=>fdc_drq,
		dack0		=>fdc_dackn,
		drdat0	=>x"00" & fdc_drdat,
		dwdat0	=>dmac_dwdat0,
		
		drq1		=>scsi_drq,
		dack1		=>scsi_dackn,
		drdat1	=>scsi_drdat,
		dwdat1	=>dmac_dwdat1,
		
		drq2		=>'0',
		dack2		=>open,
		drdat2	=>(others=>'0'),
		dwdat2	=>dmac_dwdat2,
		
		drq3		=>cdif_drq,
		dack3		=>cdif_dackn,
		drdat3	=>x"00" & cdif_drdat,
		dwdat3	=>dmac_dwdat3,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	fdc_dwdat<=dmac_dwdat0(7 downto 0);
	scsi_dwdat<=dmac_dwdat1;
	
	ioe	:ioexc port map(
		baddr	=>io_baddr,
		
		exc	=>open
	);
	
	io_dbus<=
					odat_cpu when io_wr='1' else
					x"00" & picm_odat & x"00" & picm_odat when picm_doe='1' else
					x"00" & pics_odat & x"00" & pics_odat when pics_doe='1' else
					dmac_rdat when dmac_doe='1' else
					x"00" & ptc0_odat & x"00" & ptc0_odat when ptc0_doe='1' else
					x"00" & ptc1_odat & x"00" & ptc1_odat when ptc1_doe='1' else
					it2_rdat when it2_doe='1' else
					x"000000" & io20_odat	when io20_doe='1' else
					cmos_irdat when cmos_idoe='1' else
					kbif_odat when kbif_doe='1' else
--					x"000000" & kint_rdat when kint_doe='1' else
					crtcr_odat when crtcr_doe='1' else
					x"0000" & macid_odat	when macid_doe='1' else
					x"00" & idrom_odat & x"0000" when idrom_doe='1' else
					x"00" & scsi_odat & x"00" & scsi_odat when scsi_doe='1' else
					pad_odat when pad_doe='1' else
					x"000000" & tint_odat when tint_doe='1' else
					x"000000" & io400_odat when io400_doe='1' else
					x"000000" & io404_odat when io404_doe='1' else
					x"000000" & io480_odat when io480_doe='1' else
					x"000000" & io484_odat when io484_doe='1' else
					rvid_ioodat & rvid_ioodat & rvid_ioodat & rvid_ioodat when rvid_iodoe='1' else
					rext_iordat & rext_iordat & rext_iordat & rext_iordat when rext_iodoe='1' else
					x"00" & apal_odat & x"00" & apal_odat when apal_doe='1' else
					dpal_odat & dpal_odat & dpal_odat & dpal_odat when dpal_doe='1' else
					x"000000" & dpmr_odat when dpmr_doe='1' else
					x"000000" & MEMSIZE when msiz_doe='1' else
					cdif_rdat & cdif_rdat & cdif_rdat & cdif_rdat when cdif_doe='1' else
					x"00" & fdc_rdat & x"00" & fdc_rdat when fdc_doe='1' else
					x"00" & fdcnt_rdat & x"00" & fdcnt_rdat when fdcnt_doe='1' else
					x"000000" & rtc_rdat	when rtc_doe='1' else
					x"00" & opn_rdat & x"00" & opn_rdat	when opn_doe='1' else
					x"000000" & cvw_rdat when cvw_doe='1' else
					vmsk_odat when vmsk_doe='1' else
					x"00" & uart_odat & x"00" & uart_odat when uart_doe='1' else
					x"000000" & nmim_odat when nmim_doe='1' else
					x"00" & pccs_odat & x"0000" when pccs_doe='1' else
					x"000000" & rstc_odat when rstc_doe='1' else
					x"0000" & freq_odat & spc_odat when spc_doe='1' else
					x"0000" & freq_odat & spc_odat when freq_doe='1' else
					x"000000" & cdf_odat when cdf_doe='1' else
					x"000000" & cdc_odat when cdc_doe='1' else
					x"0000" & pcmcr_odat when pcmcr_doe='1' else
					x"000000" & udly_odat when udly_doe='1' else
					usc_odat & x"ff" & cm3_odat when cm3_doe='1' or usc_doe='1' else
					x"00" & vlayr_odat & x"00" & vsnc_odat	when vsnc_doe='1' or vlayr_doe='1' else
					sndr_rdat & sndr_rdat & sndr_rdat & sndr_rdat when sndr_doe='1' else
					(others=>'1');
	
	mmap_memaddr<=	dmac_maddr(31 downto 2) when dmac_muse='1' else
						cpu_memaddr(31 downto 2);
	mmap_memblen<=	"001" when dmac_muse='1' else
						cpu_memblen;
	mmap_membyteen<=	dmac_mbsel when dmac_muse='1' else
							cpu_membyteen;
	mmap_memrd<=	dmac_mrd when dmac_muse='1' else
						cpu_memrd;
	mmap_memwr<=	dmac_mwr when dmac_muse='1' else
						cpu_memwr;
	mmap_memwdata<=	dmac_mwdat when dmac_muse='1' else
							cpu_memwdata;
						
							
	
	mmap	:memorymap generic map(RAMAWIDTH-1)port map(
		cpuaddr		=>mmap_memaddr,
		cpublen		=>mmap_memblen,
		cpubyteen	=>mmap_membyteen,
		cpurd			=>mmap_memrd,
		cpuwr			=>mmap_memwr,
		cpuwdat		=>mmap_memwdata,
		cpurdat		=>cpu_memrdata,
		cpurval		=>mem_rdval,
		cpuwait		=>mem_wait,
		
		a20en			=>cpu_a20en,
		rbooten		=>not io480_BROMn,
		rviden		=>not io404_VRAMSELn,
		rdicen		=>io480_DIC,
		rdicsel		=>io484_DICSEL,
		wpagesel		=>rvid_pgsel,
		wplanesel	=>rvid_wrsel,
		rpagesel		=>rvid_pgsel,
		rplanesel	=>rvid_rdsel,
		ankcgsel		=>rext_ANKCG,
		vrammsel		=>vmsk_msel,
		vrammsk		=>vmsk_mask,
		
		sdraddr		=>ram_cpuaddr,
		sdrblen		=>ram_cpublen,
		sdrbyteen	=>ram_cpubyteen,
		sdrrd			=>ram_cpurd,
		sdrwr			=>ram_cpuwr,
		sdrrvrd		=>ram_rvrd,
		sdrrvwr		=>ram_rvwr,
		sdrrvrsel	=>ram_rvrsel,
		sdrrvwsel	=>ram_rvwsel,
		sdrrdat		=>ram_rdat,
		sdrwdat		=>ram_cpuwdata,
		sdrrval		=>ram_rdval,
		sdrwait		=>ram_wait,
		
		spraddr		=>pat_addr,
		sprblen		=>pat_blen,
		sprbyteen	=>pat_bsel,
		sprrd			=>pat_rd,
		sprwr			=>pat_wr,
		sprrdat		=>pat_rdat,
		sprwdat		=>pat_wdat,
		sprrval		=>pat_rval,
		sprwait		=>'0',
		
		cmosaddr		=>cmos_maddr,
		cmosblen		=>open,
		cmosbyteen	=>cmos_mbsel,
		cmosrd		=>cmos_mrd,
		cmoswr		=>cmos_mwr,
		cmosrdat		=>cmos_mrdat,
		cmoswdat		=>cmos_mwdat,
		cmosrval		=>cmos_mrval,
		cmoswait		=>cmos_mwait,
	
		iocvraddr	=>iocvr_addr,
		iocvrblen	=>open,
		iocvrbyteen	=>iocvr_byteen,
		iocvrrd		=>iocvr_rd,
		iocvrwr		=>iocvr_wr,
		iocvrrdat	=>iocvr_rdat,
		iocvrwdat	=>iocvr_wdat,
		iocvrrval	=>iocvr_rval,
		iocvrwait	=>iocvr_wait,
		
		cvwrote		=>cvw_wrote,
		
		vidPmode		=>vidcr_pmode,
		vidrmode		=>vidrmode,

		clk			=>sysclk,
		rstn			=>sysrstn
	);
	cpu_memwait<=dmac_muse or mem_wait;
	cpu_memrval<=mem_rdval when dmac_muse='0' else '0';
	
	iocvr_rdat<=	rvid_modat 	when rvid_mrval='1' else
						kcg_mrdat	when kcg_mrval='1' else
						rext_mrdat	when rext_mrval='1' else
						(others=>'1');
	
	iocvr_rval<=	rvid_mrval or kcg_mrval or rext_mrval or iodmy_mrval;
	iocvr_wait<=	kcg_mwait;
	
	ldr_en<='1' when INI_INDEX=x"0000" else '0';
	
	loader	:inicopy generic map(21) port map(
		ini_en	=>ldr_en,
		ini_addr	=>INI_ADDR,
		ini_oe	=>INI_OE,
		ini_wdat	=>INI_WDAT,
		ini_wr	=>INI_WR,
		ini_ack	=>INI_ACK,
		ini_done	=>INI_DONE,

		wraddr	=>ldr_addr,
		wdat	=>ldr_wdat,
		aen	=>ldr_aen,
		wr		=>ldr_wr,
		ack	=>ldr_ack,
		done	=>ldr_done,
	
		clk	=>sysclk,
		rstn	=>ldr_rstn
	);
	
	process(sysclk,sysrstn)begin
		if(sysrstn='0')then
			INI_ULREQ<='0';
		elsif(sysclk' event and sysclk='1')then
			if(cmosstore='1')then
				INI_ULREQ<='1';
			elsif(INI_UL='1')then
				INI_ULREQ<='0';
			end if;
		end if;
	end process;
	
	process(sysclk,ldr_rstn)
	variable wrwait	:std_logic;
	variable lwait	:std_logic;
	begin
		if(ldr_rstn='0')then
			ldr_ack<='0';
			wrwait:='0';
			lwait:='0';
		elsif(sysclk' event and sysclk='1')then
			ldr_ack<='0';
			if(ldr_wr='1')then
				wrwait:='1';
			elsif(wrwait='1' and lwait='1' and ram_wait='0')then
				ldr_ack<='1';
				wrwait:='0';
			end if;
			lwait:=ram_wait;
		end if;
	end process;
	
	ioc	:iocont port map(
		cpuaddr	=>cpu_ioaddr(15 downto 2),
		cpurd		=>cpu_iord,
		cpuwr		=>cpu_iowr,
		cpubyteen	=>cpu_iobyteen,
		cpuwdat	=>cpu_iowdata,

		dwaddr	=>io_dwaddr,
		swaddr	=>io_swaddr,
		baddr		=>io_baddr,
		iobyteen	=>io_byteen,
		
		iord		=>io_rd,
		iowr		=>io_wr,
		iowdat	=>odat_cpu,
		ioswdat	=>io_swdat,
		iobwdat	=>io_bwdat,
		iowait	=>io_wait,
		
		rdval		=>cpu_iorval,
		waitreq	=>cpu_iowait,
		
		clk		=>sysclk,
		rstn		=>cpurstn
	);
	
	io20_cs<='1' when io_baddr=x"0020" else '0';
	io20_odat<="00000000";
	io20_doe<=io_rd when io20_cs='1' else '0';
	
	rstcnt	:iobout port map(
		cs		=>io20_cs,
		wr		=>io_wr,
		indat	=>io_dbus(7 downto 0),
		
		out0	=>io20_rst,
		out1	=>open,
		out2	=>open,
		out3	=>open,
		out4	=>open,
		out5	=>open,
		out6	=>io20_poff,
		out7	=>io20_wrprot,
		
		clk	=>sysclk,
		rstn	=>cpurstn
	);
	
	process(sysclk,sysrstn)
	variable	delay	:integer range 0 to 100;
	begin
		if(sysrstn='0')then
			cpurstn<='0';
			delay:=0;
		elsif(sysclk' event and sysclk='1')then
			case delay is
			when 2 | 1 =>
				cpurstn<='0';
			when 0 =>
				cpurstn<='1';
			when others =>
				cpurstn<='1';
			end case;
			if(io20_rst='1' and delay=0)then
				delay:=100;
			elsif(delay>0)then
				delay:=delay-1;
			end if;
		end if;
	end process;
	
	msiz_cs<='1' when io_baddr=x"05e8" else '0';
	msiz_doe<=io_rd when msiz_cs='1' else '0';
	
	picm_cs<='1' when io_dwaddr=x"0000" else '0';
	PICM	:pic8259 port map(
		CS		=>picm_cs,
		ADDR	=>io_baddr(1),
		DIN	=>io_swdat(7 downto 0),
		DOUT	=>picm_odat,
		DOE	=>picm_doe,
		RD		=>io_rd,
		WR		=>io_wr,
		
		IR0		=>picm_int0,
		IR1		=>picm_int1,
		IR2		=>picm_int2,
		IR3		=>picm_int3,
		IR4		=>picm_int4,
		IR5		=>picm_int5,
		IR6		=>picm_int6,
		IR7		=>picm_int7,
		
		INT		=>cpu_intdo,
		IVECT		=>picm_vect,
		VECTOE	=>picm_vectoe,
		INTA		=>cpu_intdone,
		
		CASI	=>(others=>'0'),
		CASO	=>pic_cas,
		CASM	=>'1',
		SLINTA	=>pic_slinta,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	picm_int0<=tint_int or it2_int or fint(0) ;
	picm_int1<=kbif_int or fint(1);
	picm_int2<=(not uart_intn) or fint(2);
	picm_int3<='0' or fint(3);
	picm_int4<='0' or fint(4);
	picm_int5<='0' or fint(5);
	picm_int6<=(fdc_int and fdc_irqmsk) or fint(6);
	picm_int7<=pics_int or fint(7);

	pics_cs<='1' when io_dwaddr=x"0010" else '0';
	PICS	:pic8259 port map(
		CS		=>pics_cs,
		ADDR	=>io_baddr(1),
		DIN	=>io_swdat(7 downto 0),
		DOUT	=>pics_odat,
		DOE	=>pics_doe,
		RD		=>io_rd,
		WR		=>io_wr,
		
		IR0		=>pics_int0,
		IR1		=>pics_int1,
		IR2		=>pics_int2,
		IR3		=>pics_int3,
		IR4		=>pics_int4,
		IR5		=>pics_int5,
		IR6		=>pics_int6,
		IR7		=>pics_int7,
		
		INT		=>pics_int,
		IVECT		=>pics_vect,
		VECTOE	=>pics_vectoe,
		INTA		=>pic_slinta,
		
		CASI	=>pic_cas,
		CASO	=>open,
		CASM	=>'0',
		SLINTA	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	pics_int0<=scsi_int or fint(8);
	pics_int1<='0' or fint(9);
	pics_int2<='0' or fint(10);
	pics_int3<=vsint_int or fint(11);
	pics_int4<='0' or fint(12);
	pics_int5<=(not opn_intn) or fint(13);
	pics_int6<='0' or fint(14);
	pics_int7<='0' or fint(15);

	cpu_ivect<=	picm_vect when picm_vectoe='1' else
					pics_vect when pics_vectoe='1' else
					(others=>'1');
	
	cmos_iaddr<=io_dwaddr(11 downto 2);
	cmos_ics<='1' when io_dwaddr(15 downto 12)=x"3" else '0';
	
	cmos	:cmosram port map(
		mcs	=>'1',
		maddr	=>cmos_maddr,
		mbsel	=>cmos_mbsel,
		mrd	=>cmos_mrd,
		mwr	=>cmos_mwr,
		mrdat	=>cmos_mrdat,
		mwdat	=>cmos_mwdat,
		mrval	=>cmos_mrval,
		mwait	=>cmos_mwait,
		
		iocs	=>cmos_ics,
		ioaddr=>cmos_iaddr,
		iobsel=>io_byteen,
		iord	=>io_rd,
		iowr	=>io_wr,
		iordat=>cmos_irdat,
		iodoe	=>cmos_idoe,
		iowdat=>io_dbus,
		iowait=>cmos_iwait,
		
		app	=>(others=>'0'),
		hma	=>'0',
		emsmode=>'0',
		ems	=>(others=>'0'),
		ramdisk=>(others=>'0'),
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	tint_cs<='1' when io_baddr=x"0060" else '0';
	
	tint	:timerint port map(
		cs		=>tint_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		rddat	=>tint_odat,
		wrdat	=>io_dbus(7 downto 0),
		doe	=>tint_doe,
		int	=>tint_int,
		snden	=>tint_snden,
		
		tout0	=>ptc0_cout(0),
		tout1	=>ptc0_cout(1),
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	ptc0_cs<='1' when io_baddr(15 downto 4)=x"004" else '0';
	ptc1_cs<='1' when io_baddr(15 downto 4)=x"005" else '0';
	
	sft307	:sftgen generic map(div_307k) port map(div_307k,sft_307k,sysclk,sysrstn);
	sft1228	:sftgen generic map(div_1229k) port map(div_1229k,sft_1229k,sysclk,sysrstn);
	
	ptc0_cin<=sft_307k & sft_307k & sft_307k;
	ptc1_cin<=sft_1229k & sft_1229k & sft_1229k;

	ptc0	:PTC8253 port map(
		CS		=>ptc0_cs,
		ADDR	=>io_baddr(2 downto 1),
		RD		=>io_rd,
		WR		=>io_wr,
		RDAT	=>ptc0_odat,
		WDAT	=>io_swdat(7 downto 0),
		DOE	=>ptc0_doe,
		
		CNTIN	=>ptc0_cin,
		TRIG	=>(others=>'1'),
		CNTOUT	=>ptc0_cout,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	ptc1	:PTC8253 port map(
		CS		=>ptc1_cs,
		ADDR	=>io_baddr(2 downto 1),
		RD		=>io_rd,
		WR		=>io_wr,
		RDAT	=>ptc1_odat,
		WDAT	=>io_swdat(7 downto 0),
		DOE	=>ptc1_doe,
		
		CNTIN	=>ptc1_cin,
		TRIG	=>(others=>'0'),
		CNTOUT	=>ptc1_cout,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	udly_cs<='1' when io_baddr=x"006c" else'0';
	udly_odat<=x"00";
	udly_doe<='1' when udly_cs='1' and io_rd='1' else '0';
	
	udly	:lenwait generic map(SCFREQ/1000) port map(
		cs		=>udly_cs,
		wr		=>io_wr,
		
		wreq	=>udly_wait,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
--	udly_wait<='0';
	
	it2_cs<='1' when io_dwaddr=x"0068" else '0';
	
	it2sft	:sftgen generic map(SCFREQ/1000) port map(SCFREQ/1000,it2_sft,sysclk,sysrstn);
	
	it2	:inttim2 port map(
		cs		=>it2_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		bsel	=>io_byteen,
		rdat	=>it2_rdat,
		wdat	=>io_dbus,
		doe	=>it2_doe,
		int	=>it2_int,
		
		sft	=>it2_sft,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	usc_cs<='1' when io_dwaddr=x"0024" else '0';
	
	usc	:freecount port map(
	cs		=>usc_cs,
	rd		=>io_rd,
	odat	=>usc_odat,
	doe	=>usc_doe,
	
	sft	=>it2_sft,
	clk	=>sysclk,
	rstn	=>sysrstn
);
	

	kbif_cs<='1' when io_dwaddr=x"0600" or io_dwaddr=x"0604" else '0';
	mous_rrecv<=	mous_recv when mousecon="11" else '0';
	
	kbif	:KBCONV generic map(
		CLKCYC	=>SCFREQ,
		SFTCYC	=>400,
		RPSET		=>0
	)port map(
		cs		=>kbif_cs,
		addr	=>io_dwaddr(2),
		bsel	=>io_byteen,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>kbif_odat,
		wdat	=>io_dbus,
		doe	=>kbif_doe,
		int	=>kbif_int,
		
		KBCLKIN	=>pPs2Clkin,
		KBCLKOUT	=>pPs2Clkout,
		KBDATIN	=>pPs2Datin,
		KBDATOUT	=>pPs2Datout,
		
		mous_recv	=>mous_rrecv,
		mous_clr		=>mous_rclr,
		mous_Xdat	=>mous_xdat,
		mous_Ydat	=>mous_ydat,
		mous_swdat	=>mous_swdat,
	
		emuen		=>'0',
		emurx		=>open,
		emurxdat	=>open,

		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
--	kint_cs<='1' when io_baddr=x"0604" else '0';
--	kint	: kbint port map(
--		cs		=>kint_cs,
--		rd		=>io_rd,
--		wr		=>io_wr,
--		rdat	=>kint_rdat,
--		wdat	=>io_bwdat,
--		doe	=>kint_doe,
--		
--		kbint	=>kbif_int,
--		kbnmi	=>'0',
--		
--		int	=>kint_int,
--		nmi	=>kint_nmi,
--		
--		clk	=>sysclk,
--		rstn	=>sysrstn
--	);

	mous	:MOUSERECV generic map(SCFREQ,400) port map(
		MCLKIN	=>pPmsClkin,
		MCLKOUT	=>pPmsClkout,
		MDATIN	=>pPmsDatin,
		MDATOUT	=>pPmsDatout,
		
		Xdat		=>mous_Xdat,
		Ydat		=>mous_Ydat,
		swdat		=>mous_swdat,
		
		recv		=>mous_recv,
		clr		=>mous_clr,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);

	mous_clr<=	mous_atclr	when mousecon="01" else
					mous_atclr	when mousecon="10" else
					mous_rclr	when mousecon="11" else
					'0';
	
	ATMOUS	:atarimouse generic map(SCFREQ,150)port map(
		PADOUT	=>amous_pdat,
		STROBE	=>amous_com,
		
		Xdat		=>mous_Xdat,
		Ydat		=>mous_Ydat,
		SWdat		=>mous_swdat,
		clear		=>mous_atclr,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	crtcr_cs<=	'1' when io_dwaddr=x"0440" else '0';

	CRTCR	:CRTCREG port map(
		cs		=>crtcr_cs,
		bsel	=>io_byteen,
		rd		=>io_rd,
		wr		=>io_wr,
		odat	=>crtcr_odat,
		wdat	=>io_dbus,
		doe	=>crtcr_doe,
		
		HSW1	=>crtcr_HSW1(7 downto 1),
		HSW2	=>crtcr_HSW2(10 downto 1),
		HST	=>crtcr_HST(10 downto 1),
		VST1	=>crtcr_VST1,
		VST2	=>crtcr_VST2,
		EET	=>crtcr_EET,
		VST	=>crtcr_VST,
		HDS0	=>crtcr_HDS0,
		HDE0	=>crtcr_HDE0,
		HDS1	=>crtcr_HDS1,
		HDE1	=>crtcr_HDE1,
		VDS0	=>crtcr_VDS0,
		VDE0	=>crtcr_VDE0,
		VDS1	=>crtcr_VDS1,
		VDE1	=>crtcr_VDE1,
		FA0	=>crtcr_FA0,
		HAJ0	=>open,
		FO0	=>crtcr_FO0,
		LO0	=>crtcr_LO0,
		FA1	=>crtcr_FA1,
		HAJ1	=>open,
		FO1	=>crtcr_FO1,
		LO1	=>crtcr_LO1,
		EHAJ	=>open,
		EVAJ	=>open,
		ZV1	=>crtcr_ZV1,
		ZH1	=>crtcr_ZH1,
		ZV0	=>crtcr_ZV0,
		ZH0	=>crtcr_ZH0,
		CL0	=>crtcr_CL0,
		CL1	=>crtcr_CL1,
		CEN0	=>open,
		CEN1	=>open,
		ESM0	=>open,
		ESM1	=>open,
		ESYN	=>open,
		START	=>open,
	
		DSPTV1	=>vid_ven1,
		DSPTV0	=>vid_ven0,
		DSPTH1	=>vid_hen1,
		DSPTH0	=>vid_hen0,
		FIELD		=>'0',
		VSYNC		=>vid_VS,
		HSYNC		=>vid_HS,
		VIDIN		=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	crtcr_HSW1(0)<='0';
	crtcr_HSW2(0)<='0';
	crtcr_HST(0)<='1';

	vidcr_cs<=	'1' when io_dwaddr=x"0448" else '0';
	vidcr	:VIDCREG port map(
		cs		=>vidcr_cs,
		addr	=>io_swaddr(1),
		wr		=>io_wr,
		wdat	=>io_swdat(7 downto 0),
		
		CLMODE	=>vidcr_clmode,
		PMODE		=>vidcr_pmode,
		
		PLT		=>vidcr_plt,
		YS			=>vidcr_ys,
		YM			=>vidcr_ym,
		PR1		=>vidcr_pr1,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	macid_cs<='1' when io_swaddr=x"0030" else '0';
	macid_odat<=MACHINEID & CPUID;
	macid_doe<=io_rd when macid_cs='1' else '0';
	
	idrom_cs<='1' when io_swaddr=x"0032" else '0';
	IDROM	:IDROMIF port map(
		cs		=>idrom_cs,
		rd		=>io_rd,
		wr		=>io_Wr,
		rdat	=>idrom_odat,
		wdat	=>io_dbus(23 downto 16),
		doe	=>idrom_doe,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	scsi_cs<='1' when io_dwaddr=x"0c30" else '0';
	SCSI	:scsiif port map(
		cs		=>scsi_cs,
		addr	=>io_baddr(1),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>scsi_odat,
		wdat	=>io_bwdat,
		doe	=>scsi_doe,
		int	=>scsi_int,
		drq	=>scsi_drq,
		dack	=>not scsi_dackn,
		drdat	=>scsi_drdat,
		dwdat	=>scsi_dwdat,
		
		SEL	=>SCSI_SEL,
		RST	=>SCSI_RST,
		ATN	=>SCSI_ATN,
		ACK	=>SCSI_ACK,
		
		REQ	=>SCSI_REQ,
		IO		=>SCSI_IO,
		MSG	=>SCSI_MSG,
		CD		=>SCSI_CD,
		BUSY	=>SCSI_BSY,
		
		DATOUT=>SCSI_HOUT,
		DATIN	=>SCSI_DOUT,
		DOUTEN=>SCSI_HOE,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	HDD_S	:scsidev generic map(SCFREQ,0,9)port map(
		IDAT		=>SCSI_HOUT,
		ODAT		=>SCSI_DOUT,
		SEL		=>SCSI_SEL and scsi_indisk,
		BSYI		=>SCSI_BSY,
		BSYO		=>SCSI_BSY,
		REQ		=>SCSI_REQ,
		ACK		=>SCSI_ACK,
		IO			=>SCSI_IO,
		CD			=>SCSI_CD,
		MSG		=>SCSI_MSG,
		ATN		=>SCSI_ATN,
		RST		=>SCSI_RST,

		idsel		=>0,

		unit		=>open,
		capacity	=>scsi_cap,
		lba		=>scsi_lba,
		rdreq		=>scsi_rdreq,
		wrreq		=>scsi_wrreq,
		syncreq	=>scsi_syncreq,
		sectaddr	=>scsi_sectaddr,
		rddat		=>scsi_rdata,
		wrdat		=>scsi_wdata,
		sectbusy	=>scsi_sbusy,

		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	
	SCSI_DAT<=	SCSI_HOUT or SCSI_DOUT;

	HDD_B	:scsibuf generic map(9) port map(
		indisk	=>scsi_indisk,
		capacity	=>scsi_cap,
		lba		=>scsi_lba,
		rdreq		=>scsi_rdreq,
		wrreq		=>scsi_wrreq,
		syncreq	=>scsi_syncreq,
		sectaddr	=>scsi_Sectaddr,
		rddat		=>scsi_rdata,
		wrdat		=>scsi_wdata,
		sectbusy	=>scsi_sbusy,
		
		mist_mounted	=>mist_mounted(3),
		mist_readonly	=>mist_readonly(3),
		mist_imgsize	=>mist_imgsize,
		mist_lba			=>scsi_mistlba,
		mist_rd			=>mist_rd(3),
		mist_wr			=>mist_wr(3),
		mist_ack			=>mist_ack(3),
		mist_buffaddr	=>mist_buffaddr,
		mist_buffdout	=>mist_buffdout,
		mist_buffdin	=>scsi_mistdin,
		mist_buffwr		=>mist_buffwr,
		
		mist_busyout	=>scsi_mistbusy,
		mist_busyin		=>'0',
--		mist_busyin		=>MiST_BUSY,

		clk	=>sysclk,
		rstn	=>sysrstn
	);

	
	pad_cs<='1' when io_dwaddr=x"04d0" or io_dwaddr=x"04d4" else '0';
	
	PAD	: padio port map(
		cs		=>pad_cs,
		addr	=>io_dwaddr(2),
		bsel	=>io_byteen,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>pad_odat,
		wdat	=>io_dbus,
		doe	=>pad_doe,
		
		padain	=>pad_ain,
		padbin	=>pad_bin,
		triga1	=>pad_atrg1,
		triga2	=>pad_atrg2,
		trigb1	=>pad_btrg1,
		trigb2	=>pad_btrg2,
		coma		=>pad_acom,
		comb		=>pad_bcom,
		fmmute	=>pad_FMmute,
		pcmmute	=>pad_PCMmute,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	io400_cs<='1' when io_baddr=x"0400" else '0';
	io400_doe<='1' when io400_cs='1' and io_rd='1' else '0';
	io400_odat<=x"00";
	
	io404	:iorw	generic map(x"0404","10000000") port map(
		addr	=>io_baddr,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>io404_odat,
		wdat	=>io_dbus(7 downto 0),
		doe	=>io404_doe,
		
		do0	=>open,
		do1	=>open,
		do2	=>open,
		do3	=>open,
		do4	=>open,
		do5	=>open,
		do6	=>open,
		do7	=>io404_VRAMSELn,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	io480	:iorw	generic map(x"0480","00000011") port map(
		addr	=>io_baddr,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>io480_odat,
		wdat	=>io_dbus(7 downto 0),
		doe	=>io480_doe,
		
		do0	=>io480_DIC,
		do1	=>io480_BROMn,
		do2	=>open,
		do3	=>open,
		do4	=>open,
		do5	=>open,
		do6	=>open,
		do7	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	io484	:iorw	generic map(x"0484","00001111") port map(
		addr	=>io_baddr,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>io484_odat,
		wdat	=>io_dbus(7 downto 0),
		doe	=>io484_doe,
		
		do0	=>io484_DICSEL(0),
		do1	=>io484_DICSEL(1),
		do2	=>io484_DICSEL(2),
		do3	=>io484_DICSEL(3),
		do4	=>open,
		do5	=>open,
		do6	=>open,
		do7	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	padA	:townspad6 port map(
		Un		=>pJoyA(0),
		Dn		=>pJoyA(1),
		Ln		=>pJoyA(2),
		Rn		=>pJoyA(3),
		An		=>pJoyA(4),
		Bn		=>pJoyA(5),
		Cn		=>pJoyA(6),
		Xn		=>pJoyA(7),
		Yn		=>pJoyA(8),
		Zn		=>pJoyA(9),
		seln	=>pJoyA(10),
		runn	=>pJoyA(11),
		
		com	=>pad6comA,
		pin1	=>pad6_A(0),
		pin2	=>pad6_A(1),
		pin3	=>pad6_A(2),
		pin4	=>pad6_A(3),
		pin6	=>pad6_A(4),
		pin7	=>pad6_A(5)
	);
	
	padb	:townspad6 port map(
		Un		=>pJoyB(0),
		Dn		=>pJoyB(1),
		Ln		=>pJoyB(2),
		Rn		=>pJoyB(3),
		An		=>pJoyB(4),
		Bn		=>pJoyB(5),
		Cn		=>pJoyB(6),
		Xn		=>pJoyB(7),
		Yn		=>pJoyB(8),
		Zn		=>pJoyB(9),
		seln	=>pJoyB(10),
		runn	=>pJoyB(11),
		
		com	=>pad6comB,
		pin1	=>pad6_B(0),
		pin2	=>pad6_B(1),
		pin3	=>pad6_B(2),
		pin4	=>pad6_B(3),
		pin6	=>pad6_B(4),
		pin7	=>pad6_B(5)
	);
	
	pad_ain<=pad_acom & amous_pdat when mousecon="01" else
--				pad_acom & townspad(pJoyA);
				pad_acom & pad6_A;
	pad_bin<=pad_bcom & amous_pdat when mousecon="10" else
--				pad_bcom & townspad(pJoyA) when mousecon="01" else
				pad_bcom & pad6_A when mousecon="01" else
--				pad_bcom & townspad(pJoyB);
				pad_bcom & pad6_B;
	pad6comA<=	pad_bcom when mousecon="01" else
					pad_acom;
	pad6comB<=	pad_bcom;
	pStrA<=pad_bcom when mousecon="01" else pad_acom;
	pStrB<='1' when mousecon="10" else pad_bcom;
	amous_com<=	pad_acom when mousecon="01" else
					pad_bcom when mousecon="10" else
					'0';

	apal_cs<='1' when io_baddr(15 downto 3)=(x"fd9" & '0') else '0';
	apal	:anapal port map(
		cs		=>apal_cs,
		addr	=>io_baddr(2 downto 1),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>apal_odat,
		wdat	=>io_bwdat,
		doe	=>apal_doe,
		plt	=>vidcr_plt,
		
		c8in	=>vid_pal8no,
		c8red	=>vid_pal8red,
		c8grn	=>vid_pal8grn,
		c8blu	=>vid_pal8blu,
		
		c41in		=>vid_pal41no,
		c41red	=>vid_pal41red,
		c41grn	=>vid_pal41grn,
		c41blu	=>vid_pal41blu,

		c42in		=>vid_pal42no,
		c42red	=>vid_pal42red,
		c42grn	=>vid_pal42grn,
		c42blu	=>vid_pal42blu,

		sclk		=>sysclk,
		vclk		=>vidclk,
		rstn		=>sysrstn
	);
	
	dpal_cs<='1' when io_baddr(15 downto 3)=(x"fd9" & '1') else '0';
	dpal	:digpal port map(
		cs		=>dpal_cs,
		addr	=>io_baddr(2 downto 0),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>dpal_odat,
		wdat	=>io_bwdat,
		doe	=>dpal_doe,
		wrote	=>dpal_wrote,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	dpmr_cs<='1' when io_baddr=x"044c" else '0';
	dpmr	:dpmreg port map(
		cs		=>dpmr_cs,
		rd		=>io_rd,
		rdat	=>dpmr_odat,
		doe	=>dpmr_doe,
		
		palwr	=>dpal_wrote,
		spbusy=>'0',
		sbpage=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	rvid_mcs<=	'1' when iocvr_addr(4 downto 1)="0000" else '0';
	rvid_iocs<=	'1' when io_baddr(15 downto 3)="1111111110000" else '0';
	rvidr	:rvidreg port map(
		mcs	=>rvid_mcs,
		maddr	=>iocvr_addr(0),
		mbsel	=>iocvr_byteen,
		mrd	=>iocvr_rd,
		mwr	=>iocvr_wr,
		mrdat	=>rvid_modat,
		mwdat	=>iocvr_wdat,
		mrval	=>rvid_mrval,
		
		iocs	=>rvid_iocs,
		ioaddr=>io_baddr(2 downto 0),
		iord	=>io_rd,
		iowr	=>io_wr,
		iordat	=>rvid_ioodat,
		iowdat	=>io_bwdat,
		iodoe		=>rvid_iodoe,
		
		rvid_dispen	=>vidrpen,
		rvid_disppage=>vidrps2,
		
		rvid_wrsel	=>rvid_wrsel,
		rvid_rdsel	=>rvid_rdsel,
		rvid_cpupage=>rvid_pgsel,
		
		hsync	=>vid_HS,
		vsync	=>vid_VS,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	rext_mcs<=	'1' when iocvr_addr(4 downto 0)="00110" else '0';
	rext_iocs<=	'1' when io_baddr(15 downto 1)="111111111001100" else '0';
	rext	:rextreg	port map(
		mcs		=>rext_mcs,
		mbsel		=>iocvr_byteen,
		mrd		=>iocvr_rd,
		mwr		=>iocvr_wr,
		mrdat		=>rext_mrdat,
		mwdat		=>iocvr_wdat,
		mrval		=>rext_mrval,
		
		iocs		=>rext_iocs,
		ioaddr	=>io_baddr(0),
		iord		=>io_rd,
		iowr		=>io_wr,
		iordat	=>rext_iordat,
		iowdat	=>io_bwdat,
		iodoe		=>rext_iodoe,

		ANKCG		=>rext_ANKCG,
		BEEPEN	=>rext_BEEPEN,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	iodmy_mcs<=	'0' when kcg_mcs='1' else
					'0' when rext_mcs='1' else
					'0' when rvid_mcs='1' else
					'1';

	dmyr	: dummyreg	port map(
		mcs	=>iodmy_mcs,
		mrd	=>iocvr_rd,
		mrval	=>iodmy_mrval,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	vid	:tvideo port map(
		HSW1	=>crtcr_HSW1,
		HSW2	=>crtcr_HSW2,
		HST	=>crtcr_HST,
		
		VST1	=>crtcr_VST1,
		VST2	=>crtcr_VST2,
		EET	=>crtcr_EET,
		VST	=>crtcr_VST,
		
		HDS0	=>crtcr_HDS0,
		HDE0	=>crtcr_HDE0,
		HDS1	=>crtcr_HDS1,
		HDE1	=>crtcr_HDE1,
		VDS0	=>crtcr_VDS0,
		VDE0	=>crtcr_VDE0,
		VDS1	=>crtcr_VDS1,
		VDE1	=>crtcr_VDE1,
		ZH0	=>crtcr_ZH0,
		ZH1	=>crtcr_ZH1,

		HCOMP	=>vidHcomp,
		HHCOMP=>vidHHcomp,
		VCOMP	=>vidVcomp,
		
		RMODE	=>vidrmode,
		PMODE	=>vidcr_pmode,
		CL1	=>vidcr_clmode(3 downto 2),
		CL0	=>vidcr_clmode(1 downto 0),
		RPEN	=>vidrpen,
	
		VID1EN	=>vid1en,
		VID1LINE	=>open,
		VID1ADDR	=>vid1lineaddr,
		VID1DATA	=>vid1linedata,
		VID1RDATA=>vid1rlinedata,
		
		VID2EN	=>vid2en,
		VID2LINE	=>open,
		VID2ADDR	=>vid2lineaddr,
		VID2DATA	=>vid2linedata,
		
		PR1	=>vidcr_pr1,
		PAL8ADDR	=>vid_pal8no,
		PAL8RED	=>vid_pal8red,
		PAL8GRN	=>vid_pal8grn,
		PAL8BLU	=>vid_pal8blu,
		
		PAL41ADDR	=>vid_pal41no,
		PAL41RED		=>vid_pal41red,
		PAL41GRN		=>vid_pal41grn,
		PAL41BLU		=>vid_pal41blu,

		PAL42ADDR	=>vid_pal42no,
		PAL42RED		=>vid_pal42red,
		PAL42GRN		=>vid_pal42grn,
		PAL42BLU		=>vid_pal42blu,
		
		vidR	=>pVid_R,
		vidG	=>pVid_G,
		vidB	=>pVid_B,
		vidHS	=>Vid_HS,
		vidCS	=>vid_CS,
		vidVS	=>Vid_VS,
		vidHen=>open,
		vidVen=>open,
		viden	=>pVid_En,
		vidclk=>pVid_Clk,
		
		hven0	=>vid_hen0,
		hven1	=>vid_hen1,
		vven0	=>vid_ven0,
		vven1	=>vid_ven1,
		
		dotclk =>dotclk,
		clk	=>vidclk,
		rstn	=>sysrstn
	);
	
	pVid_HS<=vid_HS;
	pVid_VS<=vid_VS;
	vidc	:videocont generic map(
		ADDRWIDTH	=>RAMAWIDTH,
		COLSIZE		=>9
	)port map(
		HDS0	=>crtcr_HDS0,
		HDE0	=>crtcr_HDE0,
		ZH0	=>crtcr_ZV0,
		ZV0	=>crtcr_ZV0,
		FA0	=>crtcr_FA0,
		FO0	=>crtcr_FO0,
		LO0	=>crtcr_LO0,
		CL0	=>crtcr_CL0,
		V0EN	=>vid1en,
		PAGESEL0=>vidrps2,

		HDS1	=>crtcr_HDS1,
		HDE1	=>crtcr_HDE1,
		ZH1	=>crtcr_ZV1,
		ZV1	=>crtcr_ZV1,
		FA1	=>crtcr_FA1,
		FO1	=>crtcr_FO1,
		LO1	=>crtcr_LO1,
		CL1	=>crtcr_CL1,
		PMODE	=>vidcr_pmode,
		V1EN	=>vid2en,
		PAGESEL1=>'0',
		
		HCOMP	=>vidHcomp,
		HHCOMP=>vidHHcomp,
		VCOMP	=>vidVcomp,
		
		ram_addr	=>vidram_addr,
		ram_blen	=>vidram_blen,
		ram_rd	=>vidram_rd,
		ram_rval	=>vidram_rval,
		ram_num	=>vidram_num,
		ram_rdat	=>vidram_rdat,
		ram_done	=>vidram_done,
		
		fram0_addr	=>vid1lineaddr,
		fram0_data	=>vid1linedata,
		fram0r_data	=>vid1rlinedata,

		fram1_addr	=>vid2lineaddr,
		fram1_data	=>vid2linedata,
		fram1r_data	=>vid2rlinedata,
		
		vclk	=>dotclk,
		rclk	=>ramclk,
		rstn	=>sysrstn
	);
	
	kcg_mcs<=	'1' when iocvr_addr="00101" else '0';
	kcg_iocs<=	'1' when io_dwaddr=x"ff94" else '0';
	
	rknj	:rkanjcg	generic map(RAMAWIDTH) port map(
		mcs	=>kcg_mcs,
		mbsel	=>iocvr_byteen,
		mrd	=>iocvr_rd,
		mwr	=>iocvr_wr,
		mrdat	=>kcg_mrdat,
		mwdat	=>iocvr_wdat,
		mrval	=>kcg_mrval,
		mwait	=>kcg_mwait,
		
		iocs		=>kcg_iocs,
		iobsel	=>io_byteen,
		iord		=>io_rd,
		iowr		=>io_wr,
		iordat	=>kcg_iordat,
		iowdat	=>io_dbus,
		iodoe		=>kcg_iodoe,
		iowait	=>kcg_iowait,
		
		ramaddr	=>kcg_ramaddr,
		ramrd		=>kcg_ramrd,
		ramwr		=>kcg_ramwr,
		rambsel	=>kcg_rambsel,
		ramrdat	=>kcg_ramrdat,
		ramwdat	=>kcg_ramwdat,
		ramdone	=>kcg_ramdone,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	kmem	:kcgmemcont generic map(RAMAWIDTH) port map(
		bus_rd	=>kcg_ramrd,
		bus_wr	=>kcg_ramwr,
		bus_done	=>kcg_ramdone,
		busclk	=>sysclk,
		
		mem_rd	=>kram_rd,
		mem_wr	=>kram_wr,
		mem_done	=>kram_done,
		memclk	=>ramclk,
		
		rstn		=>sysrstn
	);

	cvw_cs<='1' when io_baddr=x"05c8" else '0';
	cvw	:tvwrote port map(
		cs		=>cvw_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>cvw_rdat,
		doe	=>cvw_doe,
		
		wrote	=>cvw_wrote,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	vsint_cs<='1' when io_baddr=x"05ca" else '0';
	vsi	:vsint port map(
		cs		=>vsint_cs,
		wr		=>io_wr,
		
		vsync	=>vid_VS,
		int	=>vsint_int,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	cdif_cs<='1' when io_baddr(15 downto 4)=x"04c" else '0';
	
	CD	:cdif port map(
		cs		=>cdif_cs,
		addr	=>io_baddr(3  downto 0),
		rd		=>io_rd,
		wr		=>io_wr,
		rddat	=>cdif_rdat,
		wrdat	=>io_bwdat,
		doe	=>cdif_doe,
		drq	=>cdif_drq,
		dack	=>not cdif_dackn,
		irq	=>cdif_int,
		drdat	=>cdif_drdat,
		
		mist_mounted	=>mist_mounted(2),
		mist_imgsize	=>mist_imgsize,
		mist_lba			=>cdif_mistlba,
		mist_rd			=>mist_rd(2),
		mist_ack			=>mist_ack(2),
		mist_bufaddr	=>mist_buffaddr,
		mist_buffdout	=>mist_buffdout,
		mist_buffwr		=>mist_buffwr,

		mist_busyout	=>cdif_mistbusy,
		mist_busyin		=>'0',
--		mist_busyin		=>MiST_BUSY,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	fdc_cs<='1' when io_baddr(15 downto 4)=x"020" and io_baddr(3)='0' else '0';
	fdc	:MiST8877 generic map(2) port map(
		cs		=>fdc_cs,
		addr	=>io_baddr(2 downto 1),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>fdc_rdat,
		wdat	=>io_bwdat,
		doe	=>fdc_doe,
		drq	=>fdc_drq,
		drdat	=>fdc_drdat,
		dwdat	=>fdc_dwdat,
		dack	=>not fdc_dackn,
		int	=>fdc_int,
		
		dsel	=>fdc_dsel(1 downto 0),
		head	=>fdc_head,
		motor	=>(others=>fdc_motor),
		dready	=>fdc_ready,

		seekwait	=>fdd_seekwait,
		txwait	=>fdd_txwait,
	
		mist_mounted	=>mist_mounted(1 downto 0),
		mist_readonly	=>mist_readonly(1 downto 0),
		mist_imgsize	=>mist_imgsize,
		mist_lba			=>fdc_mistlba,
		mist_rd			=>mist_rd(1 downto 0),
		mist_wr			=>mist_wr(1 downto 0),
		mist_ack			=>mist_ack(0) or mist_ack(1),
		mist_buffaddr	=>mist_buffaddr,
		mist_buffdout	=>mist_buffdout,
		mist_buffdin	=>fdc_mistdin,
		mist_buffwr		=>mist_buffwr,

		mist_busyout	=>fdc_mistbusy,
		mist_busyin		=>'0',
--		mist_busyin		=>MiST_BUSY,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	fdcnt_cs<='1' when io_baddr(15 downto 4)=x"020" and io_baddr(3)='1' else '0';
	
	fdcnt	:fdcont port map(
		cs		=>fdcnt_cs,
		addr	=>io_baddr(2 downto 0),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>fdcnt_rdat,
		wdat	=>io_bwdat,
		doe	=>fdcnt_doe,
		
		ready	=>fdc_ready,
		irqmsk=>fdc_irqmsk,
		dden	=>open,
		hdsel	=>fdc_head,
		motor	=>fdc_motor,
		clksel=>open,
		dsel	=>fdc_dsel,
		inuse	=>open,
		speed	=>open,
		drvchg=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	rtc_cs<='1' when io_baddr=x"0070" else '1' when io_baddr=x"0080" else '0';
	rtc	:rtc58321 generic map(SCFREQ*1000,x"00") port map(
		cs		=>rtc_cs,
		addr	=>io_baddr(7),
		rd		=>io_rd,
		wr		=>io_wr,
		wdat	=>io_bwdat,
		rdat	=>rtc_rdat,
		doe	=>rtc_doe,
		
		RTCIN	=>sysrtc,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	ixc	:ixcount generic map(32) port map(
		cin	=>cpu_memrval,
		
		cout	=>open,
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	mist_lba0<=fdc_mistlba;
	mist_lba1<=fdc_mistlba;
	mist_lba2<=cdif_mistlba;
	mist_lba3<=scsi_mistlba;
--	mist_lba<=	fdc_mistlba when fdc_mistbusy='1' else
--					cdif_mistlba when cdif_mistbusy='1' else
--					scsi_mistlba when scsi_mistbusy='1' else
--					(others=>'0');

	mist_buffdin0<=fdc_mistdin;
	mist_buffdin1<=fdc_mistdin;
	mist_buffdin2<=(others=>'0');
	mist_buffdin3<=scsi_mistdin;
--	mist_buffdin<=	fdc_mistdin when fdc_mistbusy='1' else
--						scsi_mistdin when scsi_mistbusy='1' else
--						(others=>'0');
	
	MIST_BUSY<=fdc_mistbusy or cdif_mistbusy or scsi_mistbusy;
	
	opn_cs<=	'1' when io_baddr(15 downto 4)=x"04d" and io_baddr(3)='1' and io_baddr(0)='0' else '0';
	opns	:sftgen generic map(SCFREQ/10000) port map(SCFREQ/10000,opn_sft,sysclk,sysrstn);
	
	FMS	:OPN2 generic map(16) port map(
		DIN		=>io_bwdat,
		DOUT		=>opn_rdat,
		DOE		=>opn_doe,
		CSn		=>not opn_cs,
		ADR		=>io_baddr(2 downto 1),
		RDn		=>not io_rd,
		WRn		=>not io_wr,
		INTn		=>opn_intn,
		
		sndL		=>opn_sndL,
		sndR		=>opn_sndR,

		clk		=>sysclk,
		cpuclk	=>sysclk,
		sft		=>opn_sft,
		rstn		=>sysrstn
	);

	pLed<=MIST_BUSY;
	
	beep_snd<=	x"0000" when tint_snden='0' else
					x"1000" when ptc0_cout(2)='1' else
					x"e000";
	pSnd_L<=opn_sndL + beep_snd;
	psnd_R<=opn_sndR + beep_snd;
	
	PATR	:PATRAM port map(
		addr	=>pat_addr,
		blen	=>pat_blen,
		rd		=>pat_rd,
		wr		=>pat_wr,
		bsel	=>pat_bsel,
		rdat	=>pat_rdat,
		rval	=>pat_rval,
		wdat	=>pat_wdat,
		
		index	=>(others=>'0'),
		posX	=>open,
		posY	=>open,
		attr	=>open,
		ctable	=>open,
		
		ctno	=>(others=>'0'),
		cno	=>(others=>'0'),
		palout	=>open,
		
		paddr	=>(others=>'0'),
		pdat	=>open,
	
		
		clk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>sysrstn
	);
	
	vmsk_cs<='1' when io_dwaddr(15 downto 4)=x"045" and io_dwaddr(3)='1' else '0';
	
	vmsk	:vmaskreg port map(
		cs		=>vmsk_cs,
		wr		=>io_wr,
		rd		=>io_rd,
		bsel	=>io_byteen,
		rdat	=>vmsk_odat,
		wdat	=>cpu_iowdata,
		doe	=>vmsk_doe,
		
		mbsel	=>vmsk_msel,
		mask	=>vmsk_mask,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	uart_cs<='1' when io_baddr=x"0a00" or io_baddr=x"0a02" else '0';

	uart	:e8251 port map(
		WRn		=>not io_wr,
		RDn		=>not io_rd,
		C_Dn		=>io_baddr(1),
		CSn		=>not uart_cs,
		DATIN		=>io_dbus(7 downto 0),
		DATOUT	=>uart_odat,
		DATOE		=>uart_doe,
		INTn		=>uart_intn,
		
		TXD		=>open,
		RxD		=>'1',
		
		DSRn		=>'1',
		DTRn		=>open,
		RTSn		=>open,
		CTSn		=>'1',
		
		TxRDY		=>open,
		TxEMP		=>open,
		RxRDY		=>open,
		
		TxCn		=>'1',
		RxCn		=>'1',
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	nmim_cs<='1' when io_baddr=x"0028" else '0';
	nmsk	:nmimskr port map(
		cs		=>nmim_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>nmim_odat,
		wdat	=>io_dbus(7 downto 0),
		doe	=>nmim_doe,
		
		nmimsk	=>nmim_mask,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	pccs_cs<='1' when io_baddr=x"048a" else '0';
	pccs	:iobin port map(
		cs		=>pccs_cs,
		rd		=>io_rd,
		odat	=>pccs_odat,
		doe	=>pccs_doe,
		
		in0	=>'0',
		in1	=>'1',
		in2	=>'1',
		in3	=>'0',
		in4	=>'1',
		in5	=>'1',
		in6	=>'0',
		in7	=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	rstc_cs<='1' when io_baddr(15 downto 2)="00000000001000" else '0';
	rstc	:resetcont port map(
		cs		=>rstc_Cs,
		addr	=>io_baddr(1),
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>rstc_odat,
		wdat	=>io_swdat(7 downto 0),
		doe	=>rstc_doe,
		
		shutdown	=>'0',
		wrprot	=>open,
		poff0		=>open,
		poff2		=>open,
		rst		=>rstc_rst,
		
		clk		=>sysclk,
		rstn		=>sysrstn
	);
	
	spc_cs<='1' when io_baddr=x"05ec" else '0';
	
	spc	:spcont port map(
		cs		=>spc_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		rddat	=>spc_odat,
		wrdat	=>io_bwdat,
		doe	=>spc_doe,
		
		HISPEED	=>open,
		HSPDEN	=>'1',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	freq_bin<=conv_std_logic_vector(freq_MHz,7);
	freq_cs<='1' when io_baddr=x"05ed" else '0';
	freq	:iobin port map(
		cs		=>freq_cs,
		rd		=>io_rd,
		odat	=>freq_odat,
		doe	=>freq_doe,
		
		in0	=>freq_bin(0),
		in1	=>freq_bin(1),
		in2	=>freq_bin(2),
		in3	=>freq_bin(3),
		in4	=>freq_bin(4),
		in5	=>freq_bin(5),
		in6	=>freq_bin(6),
		in7	=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	cdf_cs<='1' when io_baddr=x"04b0" else '0';
	cdfunc	:iobin port map(
		cs		=>cdf_cs,
		rd		=>io_rd,
		odat	=>cdf_odat,
		doe	=>cdf_doe,
		
		in0	=>'1',
		in1	=>'1',
		in2	=>'1',
		in3	=>'1',
		in4	=>'1',
		in5	=>'1',
		in6	=>'1',
		in7	=>'1',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	cdc_cs<='1' when io_baddr=x"04c8" else '0';
	cdcache	:cdcachec port map(
		cs		=>cdc_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		rdat	=>cdc_odat,
		wdat	=>io_bwdat,
		doe	=>cdc_doe,
		
		cache		=>'1',
		cacheen	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	pcmcr_cs<='1' when io_swaddr=x"0490" else '0';
	pcmcr	:pcmcreg port map(
		cs		=>pcmcr_cs,
		rd		=>io_rd,
		wr		=>io_wr,
		ben	=>io_byteen(1 downto 0),
		rdat	=>pcmcr_odat,
		wdat	=>io_swdat,
		doe	=>pcmcr_doe,
		
		bank	=>open,
		reg	=>open,
		ver4	=>'1',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	pcmr_cs<=	'1' when io_baddr(15 downto 3)=x"04f" else '0';
	
	pcmr	:PCMREG port map(
		cs		=>pcmr_cs,
		addr	=>io_baddr(3 downto 0),
		wr		=>io_wr,
		wdat	=>io_bwdat,
		
		chsel	=>"000",
		env	=>open,
		panL	=>open,
		panR	=>open,
		FD		=>open,
		LS		=>open,
		ST		=>open,
		WB		=>open,
		ONOFF	=>open,
		CHON	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	sndr_cs<='1' when io_baddr(15 downto 4)=x"04e" else '0';
	
	sndr	:SOUNDREG port map(
	cs		=>sndr_cs,
	addr	=>io_baddr(3 downto 0),
	rd		=>io_rd,
	wr		=>io_wr,
	rdat	=>sndr_rdat,
	wdat	=>io_bwdat,
	doe	=>sndr_doe,
	
	VR0		=>open,
	VR1		=>open,
	VR2		=>open,
	VR3		=>open,
	VR4		=>open,
	VR5		=>open,
	VR6		=>open,
	VR7		=>open,
	mute0		=>open,
	mute1		=>open,
	mute2		=>open,
	mute3		=>open,
	mute4		=>open,
	mute5		=>open,
	mute6		=>open,
	mute7		=>open,
	ADdata	=>(others=>'0'),
	ADflag	=>'0',
	ADclear	=>open,
	intOPN	=>not opn_intn,
	intPCM	=>(others=>'0'),
	LOFF		=>open,
	MUTE		=>open,
	
	clk		=>sysclk,
	rstn		=>sysrstn
);
	
	cm3_cs<='1' when io_baddr=x"0024" else '0';
	cm3	:iobin port map(
		cs		=>cm3_cs,
		rd		=>io_rd,
		odat	=>cm3_odat,
		doe	=>cm3_doe,
		
		in0	=>'1',
		in1	=>'1',
		in2	=>'1',
		in3	=>'0',
		in4	=>'0',
		in5	=>'0',
		in6	=>'0',
		in7	=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	vsnc_cs<='1' when io_baddr=x"fda0" else '0';
	vsnc	:iobin port map(
		cs		=>vsnc_cs,
		rd		=>io_rd,
		odat	=>vsnc_odat,
		doe	=>vsnc_doe,
		
		in0	=>vid_VS,
		in1	=>vid_HS,
		in2	=>'0',
		in3	=>'0',
		in4	=>'0',
		in5	=>'0',
		in6	=>'0',
		in7	=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);

	vlayw_cs<='1' when io_baddr=x"fda0" else '0';
	vlayw	:iobout port map(
		cs		=>vlayw_cs,
		wr		=>io_wr,
		indat	=>io_dbus(7 downto 0),
		
		out0	=>vlayval(0),
		out1	=>vlayval(1),
		out2	=>vlayval(2),
		out3	=>vlayval(3),
		out4	=>open,
		out5	=>open,
		out6	=>open,
		out7	=>open,
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	vlayr_cs<='1' when io_baddr=x"fda2" else '0';
	vrayr	:iobin port map(
		cs		=>vlayr_cs,
		rd		=>io_rd,
		odat	=>vlayr_odat,
		doe	=>vlayr_doe,
		
		in0	=>vlayval(0),
		in1	=>vlayval(1),
		in2	=>vlayval(2),
		in3	=>vlayval(3),
		in4	=>'0',
		in5	=>'0',
		in6	=>'0',
		in7	=>'0',
		
		clk	=>sysclk,
		rstn	=>sysrstn
	);
	
	
	cxio<='1' when io_baddr=x"0024" else 
			'1' when io_baddr=x"0022" else
			'1' when io_baddr=x"05ed" else
			'1' when io_baddr=x"0026" else
			'1' when io_baddr=x"0027" else
			'1' when io_baddr=x"020d" else
			'1' when io_baddr=x"0034" else
			'1' when io_baddr=x"fda2" else
			'1' when io_baddr=x"fda4" else
			'0';

end rtl;
