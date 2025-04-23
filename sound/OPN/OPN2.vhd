LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use ieee.std_logic_arith.all;
	use work.envelope_pkg.all;

entity OPN2 is
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
end OPN2;

architecture rtl of OPN2 is

component OPNFM
generic(
	res		:integer	:=16
);
port(
	CPU_RADR	:in std_logic_vector(7 downto 0);
	CPU_RWR		:in std_logic;
	CPU_WDAT	:in std_logic_vector(7 downto 0);
	KEY1		:in std_logic_vector(3 downto 0);
	KEY2		:in std_logic_vector(3 downto 0);
	KEY3		:in std_logic_vector(3 downto 0);
	C3M			:in std_logic_vector(1 downto 0);
	
	fmsft	:in std_logic;
	
	sndL	:out std_logic_vector(res-1 downto 0);
	sndR	:out std_logic_vector(res-1 downto 0);

	INITDONE:in std_logic;
	clk		:in std_logic;
	sft		:in std_logic;
	rstn	:in std_logic
);
end component;


component average
generic(
	datwidth	:integer	:=16
);
port(
	INA		:in std_logic_vector(datwidth-1 downto 0);
	INB		:in std_logic_vector(datwidth-1 downto 0);
	
	OUTQ	:out std_logic_vector(datwidth-1 downto 0)
);
end component;

signal	CPU_RADR0	:std_logic_vector(7 downto 0);
signal	CPU_RADR1	:std_logic_vector(7 downto 0);
signal	CPU_WDAT	:std_logic_vector(7 downto 0);
signal	INT_RADR	:std_logic_vector(7 downto 0);
signal	INT_RDAT	:std_logic_vector(7 downto 0);
signal	CPU_RWR0	:std_logic;
signal	CPU_RWR1	:std_logic;

signal	STATUS		:std_logic_vector(7 downto 0);
signal	BUSY		:std_logic;
signal	FLAG		:std_logic_vector(1 downto 0);
signal	TARST,TBRST	:std_logic;
signal	TAEN,TBEN	:std_logic;
signal	TALD,TBLD	:std_logic;
signal	TARDAT,TACOUNT		:std_logic_vector(9 downto 0);
signal	TBRDAT,TBCOUNT		:std_logic_vector(7 downto 0);
signal	C3M			:std_logic_vector(1 downto 0);
signal	intbgn,intend	:std_logic;

constant fslength	:integer	:=198;
signal	fscount		:integer range 0 to fslength-1;

type FMSTATE_t is (
	FS_IDLE,
	FS_TIMER
);
signal	FMSTATE	:FMSTATE_t;
signal	fmsft	:std_logic;
signal	TBPS	:integer range 0 to 15;

signal	Key1,Key2,Key3	:std_logic_vector(3 downto 0);
signal	Key4,Key5,Key6	:std_logic_vector(3 downto 0);

signal	STATEMSK:std_logic_vector(4 downto 0);
signal	FLAGRES	:std_logic;
signal	IRQE	:std_logic_vector(4 downto 0);
signal	SCH		:std_logic;
signal	stateread	:std_logic;
		
signal	fmsndL0,fmsndR0	:std_logic_vector(15 downto 0);
signal	fmsndL1,fmsndR1	:std_logic_vector(15 downto 0);
signal	fmsndL,fmsndR	:std_logic_vector(15 downto 0);

constant DEVICEID	:std_logic_vector(7 downto 0)	:=x"01";

begin
	
	process(clk,rstn)begin
		if(rstn='0')then
			fmsft<='0';
			fscount<=fslength-1;
		elsif(clk' event and clk='1')then
			if(sft='1')then
				fmsft<='0';
				if(fscount>0)then
					fscount<=fscount-1;
				else
					fmsft<='1';
					fscount<=fslength-1;
				end if;
			end if;
		end if;
	end process;

	process(cpuclk,rstn)begin
		if(rstn='0')then
			CPU_RADR0<=x"30";
			CPU_RADR1<=x"30";
			BUSY<='1';
			CPU_RWR0<='0';
			CPU_RWR1<='0';
			TARST<='0';
			TBRST<='0';
			TAEN<='0';
			TBEN<='0';
			TARDAT<=(others=>'0');
			TBRDAT<=(others=>'0');
			Key1<=(others=>'0');
			Key2<=(others=>'0');
			Key3<=(others=>'0');
			CPU_WDAT<=(others=>'0');
			SCH<='0';
			IRQE<=(others=>'1');
			STATEMSK<="11100";
			FLAGRES<='0';
		elsif(cpuclk' event and cpuclk='1')then
			CPU_RWR0<='0';
			CPU_RWR1<='0';
			TARST<='0';
			TBRST<='0';
			FLAGRES<='0';
			if(BUSY='1')then
				if(CPU_RADR0/=x"ff")then
					CPU_RADR0<=CPU_RADR0+x"01";
					CPU_RADR1<=CPU_RADR1+x"01";
					case (CPU_RADR0+x"01") is
					when x"b4" | x"b5" | x"b6" =>
						CPU_WDAT<=x"c0";
					when others =>
						CPU_WDAT<=x"00";
					end case;
					CPU_RWR0<='1';
					CPU_RWR1<='1';
				else
					CPU_RADR0<=(others=>'0');
					CPU_RADR1<=(others=>'0');
					BUSY<='0';
				end if;
			else
				if(CSn='0' and WRn='0')then
					case ADR is
					when "00"  =>
						CPU_RADR0<=DIN;
					when "10" =>
						CPU_RADR1<=DIN;
					when "01" =>
						CPU_RWR0<='1';
						CPU_WDAT<=DIN;
						case CPU_RADR0 is
						when x"24" =>
							TARDAT(9 downto 2)<=DIN;
						when x"25" =>
							TARDAT(1 downto 0)<=DIN(1 downto 0);
						when x"26" =>
							TBRDAT<=DIN;
						when x"27"=>
							TALD<=DIN(0);
							TBLD<=DIN(1);
							TAEN<=DIN(2);
							TBEN<=DIN(3);
							TARST<=DIN(4);
							TBRST<=DIN(5);
							C3M<=DIN(7 downto 6);
						when x"28" =>
							case DIN(2 downto 0) is
							when "000" =>
								Key1<=DIN(7 downto 4);
							when "001" =>
								Key2<=DIN(7 downto 4);
							when "010" =>
								Key3<=DIN(7 downto 4);
							when "100" =>
								if(SCH='0')then
									Key1<=DIN(7 downto 4);
								else
									Key4<=DIN(7 downto 4);
								end if;
							when "101" =>
								if(SCH='0')then
									Key2<=DIN(7 downto 4);
								else
									Key5<=DIN(7 downto 4);
								end if;
							when "110" =>
								if(SCH='0')then
									Key3<=DIN(7 downto 4);
								else
									Key6<=DIN(7 downto 4);
								end if;
							when others =>
							end case;
						when x"29" =>
							SCH<=DIN(7);
							IRQE<=DIN(4 downto 0);
						when others=>
						end case;
					when "11" =>
						CPU_RWR1<='1';
						CPU_WDAT<=DIN;
					when others =>
					end case;
				end if;
			end if;
		end if;
	end process;
			
	DOUT<=	STATUS when ADR="00" else
			(others=>'0');

	DOE<='1' when CSn='0' and RDn='0' and ADR="00" else '0';
	
	stateread<='1' when CSn='0' and RDn='0' and ADR="10" else '0';
	
	FM0	:OPNFM generic map(res)	port map(
		CPU_RADR	=>CPU_RADR0,
		CPU_RWR		=>CPU_RWR0,
		CPU_WDAT	=>CPU_WDAT,
		KEY1		=>key1,
		KEY2		=>key2,
		KEY3		=>key3,
		C3M			=>C3M,
		
		fmsft	=>fmsft,
		
		sndL	=>fmsndL0,
		sndR	=>fmsndR0,

		INITDONE=>not BUSY,
		clk		=>clk,
		sft		=>sft,
		rstn	=>rstn
	);

	FM1	:OPNFM generic map(res)	port map(
		CPU_RADR	=>CPU_RADR1,
		CPU_RWR		=>CPU_RWR1,
		CPU_WDAT	=>CPU_WDAT,
		KEY1		=>key4,
		KEY2		=>key5,
		KEY3		=>key6,
		C3M			=>"00",
		
		fmsft	=>fmsft,
		
		sndL	=>fmsndL1,
		sndR	=>fmsndR1,

		INITDONE=>not BUSY,
		clk		=>clk,
		sft		=>sft,
		rstn	=>rstn
	);

	fmmixL	:average generic map(res) port map(fmsndL0,fmsndL1,fmsndL);
	fmmixR	:average generic map(res) port map(fmsndR0,fmsndR1,fmsndR);
	sndL<=fmsndL;
	sndR<=fmsndR;
	
	process(clk,rstn)begin
		if(rstn='0')then
			FMSTATE<=FS_IDLE;
			intbgn<='0';
		elsif(clk' event and clk='1')then
			if(BUSY='0' and sft='1')then
				intbgn<='0';
				case FMSTATE is
				when FS_IDLE =>
					if(fmsft='1')then
						FMSTATE<=FS_TIMER;
						intbgn<='1';
					end if;
				when FS_TIMER =>
					if(intend='1')then
						FMSTATE<=FS_IDLE;
					end if;
				when others=>
					FMSTATE<=FS_IDLE;
				end case;
			end if;
		end if;
	end process;
	
	process(clk,rstn)
	begin
		if(rstn='0')then
			TBPS<=0;
			intend<='0';
			TACOUNT<=(others=>'0');
			TBCOUNT<=(others=>'0');
			FLAG<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(BUSY='0' and sft='1')then
				intend<='0';
				if(FLAGRES='1')then
					FLAG<="00";
				end if;
				if(TARST='1')then
					FLAG(0)<='0';
				end if;
				if(TBRST='1')then
					FLAG(1)<='0';
				end if;
				case FMSTATE is
				when FS_TIMER =>
					if(intbgn='1')then
						if(TALD='0')then
							TACOUNT<=TARDAT;
						else
							if(TACOUNT="1111111111")then
								if(TAEN='1')then
									FLAG(0)<='1';
								end if;
								TACOUNT<=TARDAT;
							else
								TACOUNT<=TACOUNT+"0000000001";
							end if;
						end if;
						
						if(TBPS/=0)then
							TBPS<=TBPS-1;
						else
							TBPS<=15;
							if(TBLD='0')then
								TBCOUNT<=TBRDAT;
							else
								if(TBCOUNT=x"ff")then
									if(TBEN='1')then
										FLAG(1)<='1';
									end if;
									TBCOUNT<=TBRDAT;
								else
									TBCOUNT<=TBCOUNT+x"01";
								end if;
							end if;
						end if;
						intend<='1';
					end if;
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	STATUS<=BUSY & "00000" & FLAG;
	INTn<=not(FLAG(1) or FLAG(0)) ;
	
end rtl;
