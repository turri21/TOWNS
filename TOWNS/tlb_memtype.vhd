LIBRARY	IEEE,work;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use	work.MEM_ADDR_pkg.all;

entity tlb_memtype is
port(
	physical				:in std_logic_Vector(31 downto 0);
	cache_disable		:out std_logic;
	write_transparent	:out std_logic
);
end tlb_memtype;

architecture rtl of tlb_memtype is

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
	sel_OTHER
);
signal	memsel	:memsel_t;

begin
	memsel<=
			sel_RVRAM	when physical>=ADDR_RVRAM and physical<(ADDR_RVRAM+WIDTH_RVRAM) else
			sel_IOCVRAM when physical>=ADDR_IOCVRAM and physical<(ADDR_IOCVRAM+WIDTH_IOCVRAM) else
			sel_ANK8		when physical>=ADDR_ANKCG8 and physical<(ADDR_ANKCG8+WIDTH_ANKCG8) else
			sel_ANK16	when physical>=ADDR_ANKCG16 and physical<(ADDR_ANKCG16+WIDTH_ANKCG16) else
			sel_CVRAM	when physical>=ADDR_CVRAM and physical<(ADDR_CVRAM+WIDTH_CVRAM) else
			sel_KVRAM	when physical>=ADDR_KVRAM and physical<(ADDR_KVRAM+WIDTH_KVRAM) else
			sel_CVRAMres when physical>=ADDR_CVRAM and physical<(ADDR_CVRAM+WIDTH_CVRAMres) else
			sel_RDIC		when physical>=ADDR_RDIC and physical<(ADDR_RDIC+WIDTH_RDIC) else
			sel_RGAIJ	when physical>=ADDR_RGAIJ and physical<(ADDR_RGAIJ+WIDTH_RGAIJ) else
			sel_BOOT		when physical>=ADDR_BOOT and physical<(ADDR_BOOT+WIDTH_BOOT) else
			sel_MRAM		when physical>=ADDR_MRAM and physical<(ADDR_MRAM+WIDTH_RAM) else
			sel_XRAM		when physical>=ADDR_XRAM and physical<(ADDR_XRAM+WIDTH_XRAM) else
			sel_VRAM0	when physical>=ADDR_VRAM0 and physical<(ADDR_VRAM0+WIDTH_VRAM0) else
			sel_VRAM1	when physical>=ADDR_VRAM1 and physical<(ADDR_VRAM1+WIDTH_VRAM1) else
			sel_VRAM2	when physical>=ADDR_VRAM2 and physical<(ADDR_VRAM2+WIDTH_VRAM2) else
			sel_SPRITE	when physical>=ADDR_SPRITE and physical<(ADDR_SPRITE+WIDTH_SPRITE) else
			sel_DOS		when physical>=ADDR_DOS and physical<(ADDR_DOS+WIDTH_DOS) else
			sel_DIC		when physical>=ADDR_DIC and physical<(ADDR_DIC+WIDTH_DIC) else
			sel_FNT		when physical>=ADDR_FNT and physical<(ADDR_FNT+WIDTH_FNT) else
			sel_CMOS		when physical>=ADDR_CMOS and physical<(ADDR_CMOS+WIDTH_CMOS) else
			sel_F20		when physical>=ADDR_F20 and physical<(ADDR_F20+WIDTH_F20) else
			sel_SYS		when physical>=ADDR_SYS else
			sel_OTHER;
	
	cache_disable<=	
		'0' when memsel=sel_MRAM else
		'0' when memsel=sel_DOS else
		'0' when memsel=sel_DIC else
		'0' when memsel=sel_FNT else
		'0' when memsel=sel_SYS else
		'1';
	write_transparent<=
		'0' when memsel=sel_MRAM else
		'0' when memsel=sel_DOS else
		'0' when memsel=sel_DIC else
		'0' when memsel=sel_FNT else
		'0' when memsel=sel_SYS else
		'1';
	
end rtl;