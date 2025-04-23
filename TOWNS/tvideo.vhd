LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tvideo is
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
	
	dotclk	:out std_logic;
	clk	:in std_logic;
	rstn	:in std_logic
);
end tvideo;

architecture rtl of tvideo is
signal	dclk		:std_logic;
signal	hcount	:std_logic_vector(10 downto 0);
signal	vcount	:std_logic_vector(10 downto 0);
signal	V1DLY0	:std_logic_vector(15 downto 0);
signal	V1DLY1	:std_logic_vector(15 downto 0);
signal	V2DLY0	:std_logic_vector(15 downto 0);
signal	V2DLY1	:std_logic_vector(15 downto 0);

signal	V1HPOS	:std_logic_vector(10 downto 0);
signal	V2HPOS	:std_logic_vector(10 downto 0);
signal	V1HPOSZ	:std_logic_vector(10 downto 0);
signal	V2HPOSZ	:std_logic_vector(10 downto 0);
signal	Zcount0	:std_logic_vector(3 downto 0);
signal	Zcount1	:std_logic_vector(3 downto 0);
signal	VSen,HSen,CSen,VSend		:std_logic;
signal	hcompb	:std_logic;
signal	HVIDEN1	:std_logic;
signal	HVIDEN2	:std_logic;
signal	VVIDEN1	:std_logic;
signal	VVIDEN2	:std_logic;
signal	VVIDEN1d	:std_logic;
signal	VVIDEN2d	:std_logic;
signal	C8V1SELD	:std_logic_vector(3 downto 0);
signal	C8V2SELD	:std_logic_vector(3 downto 0);
signal	C4V1SELD	:std_logic_vector(3 downto 0);
signal	C4V2SELD	:std_logic_vector(3 downto 0);
signal	C8SELD	:std_logic_vector(1 downto 0);
signal	C4V1SELD0	:std_logic_vector(1 downto 0);
signal	C4V1SELD1	:std_logic_vector(1 downto 0);
signal	C4V2SELD0	:std_logic_vector(1 downto 0);
signal	C4V2SELD1	:std_logic_vector(1 downto 0);

begin

	process(clk)begin
		if(clk' event and clk='1')then
			dclk<=not dclk;
		end if;
	end process;
--	dclk<=clk;
	dotclk<=dclk;

	process(dclk)begin
		if(dclk' event and dclk='1')then
			V1DLY1<=V1DLY0;
			V1DLY0<=VID1DATA;
			V2DLY1<=V2DLY0;
			V2DLY0<=VID2DATA;
			C8SELD<=C8SELD(0) & V1HPOSZ(0);
			C4V1SELD1<=C4V1SELD0;
			C4V2SELD1<=C4V2SELD0;
			C4V1SELD0<=V1HPOSZ(1 downto 0);
			C4V2SELD0<=V2HPOSZ(1 downto 0);
			C8V1SELD(3 downto 1)<=C8V1SELD(2 downto 0);
			C8V2SELD(3 downto 1)<=C8V2SELD(2 downto 0);
			C4V1SELD(3 downto 1)<=C4V1SELD(2 downto 0);
			C4V2SELD(3 downto 1)<=C4V2SELD(2 downto 0);
			if(V1HPOSZ(0)='0')then
				if(VID1DATA(7 downto 0)=x"00")then
					C8V1SELD(0)<='0';
				else
					C8V1SELD(0)<='1';
				end if;
			else
				if(VID1DATA(15 downto 8)=x"00")then
					C8V1SELD(0)<='0';
				else
					C8V1SELD(0)<='1';
				end if;
			end if;
			if(V2HPOSZ(0)='0')then
				if(VID2DATA(7 downto 0)=x"00")then
					C8V2SELD(0)<='0';
				else
					C8V2SELD(0)<='1';
				end if;
			else
				if(VID2DATA(15 downto 8)=x"00")then
					C8V2SELD(0)<='0';
				else
					C8V2SELD(0)<='1';
				end if;
			end if;
			if(RMODE='0')then
				case C4V1SELD0 is
				when "00" =>
					if(VID1DATA(3 downto 0)=x"0")then
						C4V1SELD(0)<='0';
					else
						C4V1SELD(0)<='1';
					end if;
				when "01" =>
					if(VID1DATA(7 downto 4)=x"0")then
						C4V1SELD(0)<='0';
					else
						C4V1SELD(0)<='1';
					end if;
				when "10" =>
					if(VID1DATA(11 downto 8)=x"0")then
						C4V1SELD(0)<='0';
					else
						C4V1SELD(0)<='1';
					end if;
				when "11" =>
					if(VID1DATA(15 downto 12)=x"0")then
						C4V1SELD(0)<='0';
					else
						C4V1SELD(0)<='1';
					end if;
				when others =>
				end case;
			else
				if(VID1RDATA=x"0")then
					C4V1SELD(0)<='0';
				else
					C4V1SELD(0)<='1';
				end if;
			end if;
			case C4V2SELD0 is
			when "00" =>
				if(VID2DATA(3 downto 0)=x"0")then
					C4V2SELD(0)<='0';
				else
					C4V2SELD(0)<='1';
				end if;
			when "01" =>
				if(VID2DATA(7 downto 4)=x"0")then
					C4V2SELD(0)<='0';
				else
					C4V2SELD(0)<='1';
				end if;
			when "10" =>
				if(VID2DATA(11 downto 8)=x"0")then
					C4V2SELD(0)<='0';
				else
					C4V2SELD(0)<='1';
				end if;
			when "11" =>
				if(VID2DATA(15 downto 12)=x"0")then
					C4V2SELD(0)<='0';
				else
					C4V2SELD(0)<='1';
				end if;
			when others =>
			end case;
		end if;
	end process;

	process(dclk,rstn)begin
		if(rstn='0')then
			hcount<=(others=>'0');
			vcount<=(others=>'0');
			hcompb<='0';
			hhcomp<='0';
			vcomp<='0';
			V1HPOSZ<=(others=>'0');
			V2HPOSZ<=(others=>'0');
			Zcount0<=(others=>'0');
			Zcount1<=(others=>'0');
		elsif(dclk' event and dclk='1')then
			hcompb<='0';
			vcomp<='0';
			hhcomp<='0';
			if(hcount<HST)then
				hcount<=hcount+1;
				if(hcount=('0' & HST(10 downto 1)))then
					hhcomp<='1';
					if(vcount<VST)then
						vcount<=vcount+1;
					else
						vcount<=(others=>'0');
						vcomp<='1';
					end if;
				end if;
				if(hcount>=HDS0)then
					if(Zcount0="0000")then
						V1HPOSZ<=V1HPOSZ+1;
						Zcount0<=ZH0;
					else
						Zcount0<=Zcount0-1;
					end if;
				else
					V1HPOSZ<=(others=>'0');
					Zcount0<=ZH0;
				end if;
				if(hcount>=HDS1)then
					if(Zcount1="0000")then
						V2HPOSZ<=V2HPOSZ+1;
						Zcount1<=ZH1;
					else
						Zcount1<=Zcount1-1;
					end if;
				else
					V2HPOSZ<=(others=>'0');
					Zcount1<=ZH1;
				end if;
			else
				hcount<=(others=>'0');
				V1HPOSZ<=(others=>'0');
				V2HPOSZ<=(others=>'0');
				Zcount0<=ZH0;
				Zcount1<=ZH1;
				hcompb<='1';
				VVIDEN1d<=VVIDEN1;
				VVIDEN2d<=VVIDEN2;
				VSend<=VSen;
				if(vcount<VST)then
					vcount<=vcount+1;
				else
					vcount<=(others=>'0');
					vcomp<='1';
				end if;
			end if;
		end if;
	end process;
	hcomp<=hcompb;
	
	VSen<=	'0' when vcount<VST1 else
				'1' when vcount<VST2 else
				'0';
	process(dclk)begin
		if(dclk' event and dclk='1')then
			vidVS<=VSend;
			vidHS<=HSen;
			vidCS<=CSen;
			viden<=	(HVIDEN1 or HVIDEN2) and (VVIDEN1d or VVIDEN2d);
			hven0<=HVIDEN1;
			hven1<=HVIDEN2;
			vven0<=VVIDEN1d;
			vven1<=VVIDEN2d;
		end if;
	end process;
			
	HSen<=	'1' when hcount<HSW1 else '0';
	
	CSen<=	'1' when hcount<HSW1 and VSen='0' else
				'1' when hcount<HSW2 and VSen='1' else
				'0';
			
	
	HVIDEN1<=	'0' when hcount<HDS0 else
					'1' when hcount<HDE0 else
					'0';
	HVIDEN2<=	'0' when hcount<HDS1 else
					'1' when hcount<HDE1 else
					'0';
	
	VVIDEN1<=	'0' when vcount<VDS0 else
					'1' when vcount<VDE0 else
					'0';
	VVIDEN2<=	'0' when vcount<VDS1 else
					'1' when vcount<VDE1 else
					'0';
	VID1EN<=VVIDEN1;
	VID2EN<=VVIDEN2;
	
	vidHen<=	HVIDEN1 or HVIDEN2;
	vidVen<=	VVIDEN1 or VVIDEN2;
	
	V1HPOS<=	(others=>'1')when HVIDEN1='0' else
				hcount-HDS0;

	V2HPOS<=	(others=>'1')when HVIDEN2='0' else
				hcount-HDS1;
	
	
	VID1LINE<=	(others=>'1') when VVIDEN1='0' else
					vcount-VDS0;

	VID2LINE<=	(others=>'1') when VVIDEN2='0' else
					vcount-VDS1;
	
	VID1ADDR<=	(others=>'1') when CL0="00" else
					V1HPOSZ when RMODE='1' else
					"00" & V1HPOSZ(10 downto 2) when CL0="01" and PMODE='1' else	--4bit color
					'0' & V1HPOSZ(10 downto 1)  when CL0="10" and PMODE='0' else	--8bit color
					V1HPOSZ;																		--16bit color

	VID2ADDR<=	(others=>'1') when CL1="00" else
--					V2HPOSZ when RMODE='1' else
					"00" & V2HPOSZ(10 downto 2) when CL1="01" and PMODE='1' else	--4bis color
					'0' & V2HPOSZ(10 downto 1)  when CL1="10" and PMODE='0' else	--8bit color
					V2HPOSZ;																		--16bit color
	
	PAL8ADDR<=	VID1DATA(7 downto 0) when C8SELD(1)='1'  else
					VID1DATA(15 downto 8);
	
	PAL41ADDR<=	VID1RDATA and RPEN when RMODE='1' else
					VID1DATA(3 downto 0) when C4V1SELD0="00" else
					VID1DATA(7 downto 4) when C4V1SELD0="01" else
					VID1DATA(11 downto 8) when C4V1SELD0="10" else
					VID1DATA(15 downto 12) when C4V1SELD0="11" else
					(others=>'0');
	
	PAL42ADDR<=	
					VID2DATA(3 downto 0) when C4V2SELD0="00" else
					VID2DATA(7 downto 4) when C4V2SELD0="01" else
					VID2DATA(11 downto 8) when C4V2SELD0="10" else
					VID2DATA(15 downto 12) when C4V2SELD0="11" else
					(others=>'0');
	
	vidR<=	PAL8RED when CL0="10" and PMODE='0' else
				V1DLY1( 9 downto  5) & V1DLY1( 9 downto  7) when CL0="11" and ((V1DLY1(15)='0' and PMODE='1' and PR1='0') or PMODE='0') else
				V2DLY1( 9 downto  5) & V2DLY1( 9 downto  7) when CL1="11" and V2DLY1(15)='0' and PMODE='1' and PR1='1' else
				PAL41RED & PAL41RED when CL0="01" and C4V1SELD(0)='1' and PMODE='1' and PR1='0' else
				PAL42RED & PAL42RED when CL1="01" and C4V2SELD(0)='1' and PMODE='1' and PR1='1' else
				V1DLY1( 9 downto  5) & V1DLY1( 9 downto  7) when CL0="11" and PMODE='1' and PR1='1' else
				V2DLY1( 9 downto  5) & V2DLY1( 9 downto  7) when CL1="11" and PMODE='1' and PR1='0' else
				PAL41RED & PAL41RED when CL0="01" and PMODE='1' and PR1='1' else
				PAL42RED & PAL42RED when CL1="01" and PMODE='1' and PR1='0' else
				(others=>'0');
				
	vidG<=	PAL8GRN when CL0="10" and PMODE='0' else
				V1DLY1(14 downto 10) & V1DLY1(14 downto 12) when CL0="11" and ((V1DLY1(15)='0' and PMODE='1' and PR1='0') or PMODE='0') else
				V2DLY1(14 downto 10) & V2DLY1(14 downto 12) when CL1="11" and V2DLY1(15)='0' and PMODE='1' and PR1='1' else
				PAL41GRN & PAL41GRN when CL0="01" and C4V1SELD(0)='1' and PMODE='1' and PR1='0' else
				PAL42GRN & PAL42GRN when CL1="01" and C4V2SELD(0)='1' and PMODE='1' and PR1='1' else
				V1DLY1(14 downto 10) & V1DLY1(14 downto 12) when CL0="11" and PMODE='1' and PR1='1' else
				V2DLY1(14 downto 10) & V2DLY1(14 downto 12) when CL1="11" and PMODE='1' and PR1='0' else
				PAL41GRN & PAL41GRN when CL0="01" and PMODE='1' and PR1='1' else
				PAL42GRN & PAL42GRN when CL1="01" and PMODE='1' and PR1='0' else
				(others=>'0');
				
	vidB<=	PAL8BLU when CL0="10" and PMODE='0' else
				V1DLY1( 4 downto  0) & V1DLY1( 4 downto  2) when CL0="11" and ((V1DLY1(15)='0' and PMODE='1' and PR1='0') or PMODE='0') else
				V2DLY1( 4 downto  0) & V2DLY1( 4 downto  2) when CL1="11" and V2DLY1(15)='0' and PMODE='1' and PR1='1' else
				PAL41BLU & PAL41BLU when CL0="01" and C4V1SELD(0)='1' and PMODE='1' and PR1='0' else
				PAL42BLU & PAL42BLU when CL1="01" and C4V2SELD(0)='1' and PMODE='1' and PR1='1' else
				V1DLY1( 4 downto  0) & V1DLY1( 4 downto  2) when CL0="11" and PMODE='1' and PR1='1' else
				V2DLY1( 4 downto  0) & V2DLY1( 4 downto  2) when CL1="11" and PMODE='1' and PR1='0' else
				PAL41BLU & PAL41BLU when CL0="01" and PMODE='1' and PR1='1' else
				PAL42BLU & PAL42BLU when CL1="01" and PMODE='1' and PR1='0' else
				(others=>'0');
	
--	vidR<=PAL42RED & PAL42RED;
--	vidG<=PAL42GRN & PAL42GRN;
--	vidB<=PAL42BLU & PAL42BLU;
	
	vidclk<=dclk;
	
end rtl;
