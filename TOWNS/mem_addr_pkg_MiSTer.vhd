LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

package MEM_ADDR_pkg is
	-- phisical address(unit:word)
	-- ROM area
	constant RAM_ROMSTART	:std_logic_vector(27 downto 0)	:=x"0000000";
	constant	RAM_DOS		:std_logic_vector(27 downto 0)	:=x"0000000";
	constant	RAM_DIC		:std_logic_vector(27 downto 0)	:=x"0040000";
	constant	RAM_FNT		:std_logic_vector(27 downto 0)	:=x"0080000";
	constant RAM_ANK8		:std_logic_vector(27 downto 0)	:=x"009e800";
	constant RAM_ANK16	:std_logic_vector(27 downto 0)	:=x"009ec00";
	constant	RAM_F20		:std_logic_vector(27 downto 0)	:=x"00a0000";
	constant	RAM_SYS		:std_logic_vector(27 downto 0)	:=x"00e0000";
	constant RAM_BOOT		:std_logic_vector(27 downto 0)	:=x"00fc000";
	
	-- RAM area
	constant RAM_VRAM0	:std_logic_vector(27 downto 0)	:=x"0100000";
	constant RAM_VRAM0P0	:std_logic_vector(27 downto 0)	:=x"0100000";
	constant RAM_VRAM0P1	:std_logic_vector(27 downto 0)	:=x"0110000";
	constant RAM_VRAM1	:std_logic_vector(27 downto 0)	:=x"0120000";
	constant RAM_VRAM1P0	:std_logic_vector(27 downto 0)	:=x"0120000";
	constant RAM_VRAM1P1	:std_logic_vector(27 downto 0)	:=x"0130000";
	constant RAM_VRAMEND	:std_logic_vector(27 downto 0)	:=x"0140000";
	constant RAM_SND		:std_logic_vector(27 downto 0)	:=x"0140000";
	constant RAM_GAIJ		:std_logic_vector(27 downto 0)	:=x"0150000";
	constant RAM_CVRAM	:std_logic_vector(27 downto 0)	:=x"0158000";
	constant RAM_KVRAM	:std_logic_vector(27 downto 0)	:=x"015a000";
	constant	RAM_MAIN		:std_logic_vector(27 downto 0)	:=x"0400000";
	constant RAM_FDEMU0	:std_logic_vector(27 downto 0)	:=x"0800000";
	constant RAM_FDEMU1	:std_logic_vector(27 downto 0)	:=x"0c00000";
	
	-- CPU address mapping(unit:byte)
	constant	ADDR_MRAM	:std_logic_vector(31 downto 0)	:=x"00000000";
	constant WIDTH_MRAM	:std_logic_vector(31 downto 0)	:=x"000c0000";
	constant WIDTH_RAM	:std_logic_vector(31 downto 0)	:=x"00100000";
	constant ADDR_RVRAM	:std_logic_vector(31 downto 0)	:=x"000c0000";
	constant WIDTH_RVRAM	:std_logic_vector(31 downto 0)	:=x"00008000";
	constant ADDR_CVRAM	:std_logic_vector(31 downto 0)	:=x"000c8000";
	constant WIDTH_CVRAM	:std_logic_vector(31 downto 0)	:=x"00001000";
	constant WIDTH_CVRAMres:std_logic_vector(31 downto 0)	:=x"00008000";
	constant ADDR_IOCVRAM:std_logic_vector(31 downto 0)	:=x"000cff80";
	constant WIDTH_IOCVRAM:std_logic_vector(31 downto 0)	:=x"00000080";
	constant ADDR_KVRAM	:std_logic_vector(31 downto 0)	:=x"000ca000";
	constant WIDTH_KVRAM	:std_logic_vector(31 downto 0)	:=x"00001000";
	constant ADDR_ANKCG8	:std_logic_vector(31 downto 0)	:=x"000ca000";
	constant WIDTH_ANKCG8:std_logic_vector(31 downto 0)	:=x"00000800";
	constant ADDR_ANKCG16:std_logic_vector(31 downto 0)	:=x"000cb000";
	constant WIDTH_ANKCG16:std_logic_vector(31 downto 0)	:=x"00001000";
	constant ADDR_RDIC	:std_logic_vector(31 downto 0)	:=x"000d0000";
	constant	WIDTH_RDIC	:std_logic_vector(31 downto 0)	:=x"00008000";
	constant ADDR_RGAIJ	:std_logic_vector(31 downto 0)	:=x"000d8000";
	constant	WIDTH_RGAIJ	:std_logic_vector(31 downto 0)	:=x"00008000";
	constant	ADDR_BOOT	:std_logic_vector(31 downto 0)	:=x"000f8000";
	constant	WIDTH_BOOT	:std_logic_vector(31 downto 0)	:=x"00008000";
	constant ADDR_XRAM	:std_logic_vector(31 downto 0)	:=x"00100000";
	constant WIDTH_XRAM	:std_logic_vector(31 downto 0)	:=x"00700000";
	constant ADDR_VRAM0	:std_logic_vector(31 downto 0)	:=x"80000000";
	constant WIDTH_VRAM0	:std_logic_vector(31 downto 0)	:=x"00040000";
	constant ADDR_VRAM1	:std_logic_vector(31 downto 0)	:=x"80040000";
	constant WIDTH_VRAM1	:std_logic_vector(31 downto 0)	:=x"00040000";
	constant ADDR_VRAM2	:std_logic_vector(31 downto 0)	:=x"80100000";
	constant WIDTH_VRAM2	:std_logic_vector(31 downto 0)	:=x"00080000";
	constant	ADDR_SPRITE	:std_logic_vector(31 downto 0)	:=x"81000000";
	constant	WIDTH_SPRITE:std_logic_vector(31 downto 0)	:=x"00020000";
	constant ADDR_DOS		:std_logic_vector(31 downto 0)	:=x"c2000000";
	constant WIDTH_DOS	:std_logic_vector(31 downto 0)	:=x"00080000";
	constant ADDR_DIC		:std_logic_vector(31 downto 0)	:=x"c2080000";
	constant WIDTH_DIC	:std_logic_vector(31 downto 0)	:=x"00080000";
	constant ADDR_FNT		:std_logic_vector(31 downto 0)	:=x"c2100000";
	constant WIDTH_FNT	:std_logic_vector(31 downto 0)	:=x"00040000";
	constant	ADDR_CMOS	:std_logic_vector(31 downto 0)	:=x"c2140000";
	constant WIDTH_CMOS	:std_logic_vector(31 downto 0)	:=x"00020000";
	constant ADDR_F20		:std_logic_vector(31 downto 0)	:=x"c2180000";
	constant WIDTH_F20	:std_logic_vector(31 downto 0)	:=x"00080000";
	constant ADDR_PCMWIN	:std_logic_vector(31 downto 0)	:=x"c2200000";
	constant WIDTH_PCMWIN:std_logic_vector(31 downto 0)	:=x"00001000";
	constant ADDR_SYS		:std_logic_vector(31 downto 0)	:=x"fffc0000";
	constant WIDTH_SYS	:std_logic_vector(31 downto 0)	:=x"00040000";

end package;
