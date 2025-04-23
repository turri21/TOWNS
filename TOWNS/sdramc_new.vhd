LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY SDRAMC IS
	generic(
		ADRWIDTH		:integer	:=25;
		COLSIZE		:integer	:=9;
		VIDBOUND		:integer	:=9;
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
end SDRAMC;

architecture rtl of SDRAMC is

type state_t is(
	st_INITIMER,
	st_CLOCKWAIT,
	st_INITPALL,
	st_INITREF,
	st_INITMRS,
	st_REFRESH,
	st_READ,
	st_WRITE
);
constant latency	:integer	:=3;
type state_array is array (natural range <>) of state_t; 
signal	state	:state_t;
signal	lSTATE	:state_array(latency-1 downto 0);

type select_t is(
	sel_COM,
	sel_CPU,
	sel_SUB,
	sel_KCG,
	sel_VID,
	sel_FDE,
	sel_FEC,
	sel_SND
);
signal	jobsel	:select_t;
signal	SELADR	:std_logic_vector(ADRWIDTH-1 downto 0);
signal	SELBSEL	:std_logic_vector(1 downto 0);
signal	SELWDAT	:std_logic_vector(15 downto 0);
signal	SELBLEN	:std_logic_vector(COLSIZE-1 downto 0);

constant INITR_TIMES	:integer	:=20;
signal	INITR_COUNT	:integer range 0 to INITR_TIMES;
constant INITTIMERCNT:integer	:=1000;
signal	INITTIMER	:integer range 0 to INITTIMERCNT;
constant clockwtime	:integer	:=50000;	--usec
--constant clockwtime	:integer	:=2;	--usec
constant cwaitcnt	:integer	:=clockwtime*86;	--clocks
signal	CLOCKWAIT	:integer range 0 to cwaitcnt;
signal	clkcount	:integer range 0 to 20;
subtype  clkcount_t is integer range 0 to 20;
type clkcount_array is array(natural range <>) of clkcount_t;

constant REFINT		:integer	:=CLKMHZ*REFCYC;
signal	REFCNT	:integer range 0 to REFINT-1;

signal	smemdat		:std_logic_vector(15 downto 0);
signal	BCOUNT	:std_logic_vector(COLSIZE-1 downto 0);
--signal	BCDELAY	:std_logic_vector(COLSIZE-1 downto 0);
signal	BNUMCOUNT	:std_logic_vector(COLSIZE-1 downto 0);
signal	BNCOUNTEN	:std_logic;
signal	BNCEN			:std_logic;
signal	BNCENDLY		:std_logic_vector(latency downto 0);
signal	LEN1			:std_logic_vector(COLSIZE-1 downto 0);

type job_t is(
	JOB_NOP,
	JOB_RD,
	JOB_WR
);

signal	CURJOB	:job_t;
signal	CPUJOB	:job_t;
signal	SUBJOB	:job_t;
signal	KCGJOB	:job_t;
signal	VIDJOB	:job_t;
signal	FDEJOB	:job_t;
signal	FECJOB	:job_t;
signal	SNDJOB	:job_t;

signal	MEMCKE		:STD_LOGIC;							-- SD-RAM CLOCK ENABLE
signal	MEMCS_N		:STD_LOGIC;							-- SD-RAM CHIP SELECT
signal	MEMRAS_N	:STD_LOGIC;							-- SD-RAM ROW/RAS
signal	MEMCAS_N	:STD_LOGIC;							-- SD-RAM /CAS
signal	MEMWE_N		:STD_LOGIC;							-- SD-RAM /WE
signal	MEMUDQ		:STD_LOGIC;							-- SD-RAM UDQM
signal	MEMLDQ		:STD_LOGIC;							-- SD-RAM LDQM
signal	MEMBA1		:STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 1
signal	MEMBA0		:STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 0
signal	MEMADR		:STD_LOGIC_VECTOR( 12 DOWNTO 0 );	-- SD-RAM ADDRESS
signal	MEMDAT		:STD_LOGIC_VECTOR( 15 DOWNTO 0 );	-- SD-RAM DATA
signal	MEMDATOE	:STD_LOGIC;

constant ALLZERO	:std_logic_vector(ADRWIDTH-1 downto 0)	:=(others=>'0');
signal	jobbgn	:std_logic;
signal	jobdone	:std_logic;

begin

	process(clk,rstn)begin
		if(rstn='0')then
			jobsel<=sel_COM;
			curjob<=JOB_NOP;
			jobbgn<='0';
			CPUDONE		<='0';
			SUBDONE		<='0';
			VIDDONE		<='0';
			KCGDONE		<='0';
			FDEDONE		<='0';
			FECDONE		<='0';
			SNDDONE		<='0';
			CPUJOB		<=JOB_NOP;
			SUBJOB		<=JOB_NOP;
			KCGJOB		<=JOB_NOP;
			VIDJOB		<=JOB_NOP;
			FDEJOB		<=JOB_NOP;
			FECJOB		<=JOB_NOP;
			SNDJOB		<=JOB_NOP;
			INITR_COUNT	<=INITR_TIMES;
			INITTIMER	<=INITTIMERCNT;
			CLOCKWAIT	<=cwaitcnt;
			mem_inidone<='0';
			jobsel<=sel_COM;
			state<=st_INITIMER;
		elsif(clk' event and clk='1')then
			jobbgn<='0';
			CPUDONE		<='0';
			SUBDONE		<='0';
			KCGDONE		<='0';
			VIDDONE		<='0';
			FDEDONE		<='0';
			FECDONE		<='0';
			SNDDONE		<='0';
			
			if(CPURD='1')then
				CPUJOB<=JOB_RD;
			elsif(CPUWR='1')then
				CPUJOB<=JOB_WR;
			end if;
			
			if(SUBRD='1')then
				SUBJOB<=JOB_RD;
			elsif(SUBWR='1')then
				SUBJOB<=JOB_WR;
			end if;
			
			if(KCGRD='1')then
				KCGJOB<=JOB_RD;
			elsif(KCGWR='1')then
				KCGJOB<=JOB_WR;
			end if;
			
			if(VIDRD='1')then
				VIDJOB<=JOB_RD;
			end if;
			
			if(FDERD='1')then
				FDEJOB<=JOB_RD;
			elsif(FDEWR='1')then
				FDEJOB<=JOB_WR;
			end if;
			
			if(FECRD='1')then
				FECJOB<=JOB_RD;
			elsif(FECWR='1')then
				FECJOB<=JOB_WR;
			end if;
			
			if(SNDRD='1')then
				SNDJOB<=JOB_RD;
			elsif(SNDWR='1')then
				SNDJOB<=JOB_WR;
			end if;
			
			case state is
			when st_INITIMER =>
				if(INITTIMER>0)then
					INITTIMER<=INITTIMER-1;
				else
					state<=st_CLOCKWAIT;
				end if;
			when st_CLOCKWAIT =>
				if(CLOCKWAIT>0)then
					CLOCKWAIT<=CLOCKWAIT-1;
				else
					STATE<=st_INITPALL;
					jobbgn<='1';
				end if;
			when st_INITPALL =>
				if(jobdone='1')then
					INITR_COUNT<=INITR_TIMES;
					state<=st_INITREF;
					jobbgn<='1';
				end if;
			when st_INITREF =>
				if(jobdone='1')then
					if(INITR_COUNT>0)then
						INITR_COUNT<=INITR_COUNT-1;
						jobbgn<='1';
					else
						state<=st_INITMRS;
						jobbgn<='1';
					end if;
				end if;
			when st_INITMRS =>
				if(jobdone='1')then
					mem_inidone<='1';
					state<=st_REFRESH;
					jobbgn<='1';
				end if;
			when others =>
				if(jobdone='1')then
					case jobsel is
					when sel_CPU =>
						CPUDONE<='1';
					when sel_SUB =>
						SUBDONE<='1';
					when sel_VID =>
						VIDDONE<='1';
					when sel_KCG =>
						KCGDONE<='1';
					when sel_FDE =>
						FDEDONE<='1';
					when sel_FEC =>
						FECDONE<='1';
					when sel_SND =>
						SNDDONE<='1';
					when others =>
					end case;
					if(REFCNT=0)then
						jobsel<=sel_COM;
						STATE<=ST_REFRESH;
					elsif(VIDJOB/=JOB_NOP and jobsel/=sel_VID)then
						VIDJOB<=JOB_NOP;
						jobsel<=sel_VID;
						STATE<=st_READ;
					elsif(FDEJOB/=JOB_NOP)then
						jobsel<=sel_FDE;
						case FDEJOB is
						when JOB_RD =>
							STATE<=st_READ;
						when JOB_WR =>
							STATE<=st_WRITE;
						when others =>
							jobsel<=sel_COM;
							STATE<=st_REFRESH;
						end case;
						FDEJOB<=JOB_NOP;
					elsif(SNDJOB/=JOB_NOP)then
						jobsel<=sel_SND;
						case SNDJOB is
						when JOB_RD =>
							STATE<=st_READ;
						when JOB_WR =>
							STATE<=st_WRITE;
						when others =>
							jobsel<=sel_COM;
							STATE<=st_REFRESH;
						end case;
						SNDJOB<=JOB_NOP;
					elsif(KCGJOB/=JOB_NOP)then
						jobsel<=sel_KCG;
						case KCGJOB is
						when JOB_RD =>
							STATE<=st_READ;
						when JOB_WR =>
							STATE<=st_WRITE;
						when others =>
							jobsel<=sel_COM;
							STATE<=st_REFRESH;
						end case;
						KCGJOB<=JOB_NOP;
					elsif(SUBJOB/=JOB_NOP and (jobsel/=sel_SUB or CPUJOB=JOB_NOP))then
						jobsel<=sel_SUB;
						case SUBJOB is
						when JOB_RD =>
							STATE<=st_READ;
						when JOB_WR =>
							STATE<=st_WRITE;
						when others =>
							jobsel<=sel_COM;
							STATE<=st_REFRESH;
						end case;
						SUBJOB<=JOB_NOP;
					else
						jobsel<=sel_CPU;
						case CPUJOB is
						when JOB_RD =>
							STATE<=st_READ;
							CPUJOB<=JOB_NOP;
						when JOB_WR =>
							STATE<=st_WRITE;
							CPUJOB<=JOB_NOP;
						when others =>
							jobsel<=sel_COM;
							STATE<=st_REFRESH;
						end case;
					end if;
					jobbgn<='1';
				end if;
			end case;
		end if;
	end process;

	SELADR<=	CPUADR	when jobsel=sel_CPU else
				SUBADR	when jobsel=sel_SUB else
				KCGADR	when jobsel=sel_KCG else
				VIDADR	when jobsel=sel_VID else
				FDEADR	when jobsel=sel_FDE else
				FECADR	when jobsel=sel_FEC else
				SNDADR	when jobsel=sel_SND else
				(others=>'1');

	SELBSEL<=CPUBSEL	when jobsel=sel_CPU else
				SUBBSEL	when jobsel=sel_SUB else
				KCGBSEL	when jobsel=sel_KCG else
				"11"		when jobsel=sel_VID else
				"11"		when jobsel=sel_FDE else
				"11"		when jobsel=sel_FEC else
				"11"		when jobsel=sel_SND else
				"00";

	
	SELWDAT<=CPUWDAT	when jobsel=sel_CPU else
				SUBWDAT	when jobsel=sel_SUB else
				KCGWDAT	when jobsel=sel_KCG else
				x"ffff"	when jobsel=sel_VID else
				FDEWDAT	when jobsel=sel_FDE else
				FECWDAT	when jobsel=sel_FEC else
				SNDWDAT	when jobsel=sel_SND else
				x"ffff";
	
	LEN1<=(0=>'1',others=>'0');
	
	SELBLEN<=CPUBLEN	when jobsel=sel_CPU else
				SUBBLEN	when jobsel=sel_SUB else
				LEN1		when jobsel=sel_KCG else
				VIDBLEN	when jobsel=sel_VID else
				LEN1		when jobsel=sel_FDE else
				FECBLEN	when jobsel=sel_FEC else
				LEN1		when jobsel=sel_SND else
				LEN1;
				
	process(clk,rstn)
	variable cont		:std_logic;
	variable	done		:std_logic;
	variable vcomp		:std_logic_vector(COLSIZE-1 downto 0);
	begin
		if(rstn='0')then
			MEMCKE		<='0';
			MEMCS_N		<='1';
			MEMRAS_N		<='1';
			MEMCAS_N		<='1';
			MEMWE_N		<='1';
			MEMUDQ		<='1';
			MEMLDQ		<='1';
			MEMBA1		<='0';
			MEMBA0		<='0';
			MEMADR		<=(others=>'0');
			MEMDAT		<=(others=>'0');
			MEMDATOE		<='0';
			BCOUNT		<=(others=>'0');
			REFCNT		<=REFINT-1;
			BNCEN			<='0';
			clkcount		<=20;
		elsif(clk' event and clk='1')then
			BNCEN<='0';
			jobdone		<='0';
			cont:='0';
			done:='0';
			if(REFCNT>0)then
				REFCNT<=REFCNT-1;
			end if;
			
			case STATE is
			when ST_INITPALL =>
				case clkcount is
				when 0 =>	--precharge all
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='0';
					MEMCAS_N	<='1';
					MEMWE_N		<='0';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'1');
					MEMDATOE	<='0';
				when 3 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
					jobdone<='1';
					done:='1';
				when others =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
				end case;
			when ST_INITREF | ST_REFRESH =>
				case clkcount is
				when 0 =>
					REFCNT		<=REFINT-1;
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='0';
					MEMCAS_N	<='0';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
				when 6 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
					jobdone<='1';
					done:='1';
				when others =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
				end case;
			when ST_INITMRS =>
				case clkcount is
				when 0 =>
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='0';
					MEMCAS_N	<='0';
					MEMWE_N		<='0';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<="0000000100111";	-- full page burst, CAS2
					MEMDATOE	<='0';
				when 2 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE		<='0';
					jobdone		<='1';
					done:='1';
				when others =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N		<='1';
					MEMCAS_N		<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR		<=(others=>'0');
					MEMDATOE	<='0';
				end case;
			when ST_READ =>
				case clkcount is
				when 0 =>		--active bank
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='0';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<=SELADR(ADRWIDTH-1);
					MEMBA0		<=SELADR(ADRWIDTH-2);
					MEMADR		<=SELADR(ADRWIDTH-3 downto ADRWIDTH-15);
					MEMDATOE	<='1';
					MEMDAT		<=x"ffff";
				when 2 =>		--read command
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='1';
					MEMCAS_N	<='0';
					MEMWE_N		<='1';
					MEMUDQ		<='0';
					MEMLDQ		<='0';
					MEMBA1		<=SELADR(ADRWIDTH-1);
					MEMBA0		<=SELADR(ADRWIDTH-2);
					MEMADR		<="000" & SELADR(9 downto 0);
					MEMDATOE	<='0';
					BCOUNT		<=(others=>'0');
					BNCEN<='1';
				when 3 =>
					vcomp:=BCOUNT+1;
					if(SELBLEN=vcomp)then
						--precharge all
						MEMCKE		<='1';
						MEMCS_N		<='0';
						MEMRAS_N	<='0';
						MEMCAS_N	<='1';
						MEMWE_N		<='0';
						MEMUDQ		<='1';
						MEMLDQ		<='1';
						MEMBA1		<='0';
						MEMBA0		<='0';
						MEMADR		<=(others=>'1');
						MEMDATOE	<='0';
					else
						MEMCKE		<='1';
						MEMCS_N		<='1';
						MEMRAS_N	<='1';
						MEMCAS_N	<='1';
						MEMWE_N		<='1';
						MEMUDQ		<='0';
						MEMLDQ		<='0';
						MEMBA1		<=SELADR(ADRWIDTH-1);
						MEMBA0		<=SELADR(ADRWIDTH-2);
						MEMADR(12 downto 11)	<="00";
						MEMADR(10 downto 0)	<=(others=>'0');
						MEMDATOE	<='0';
						BCOUNT<=BCOUNT+1;
						BNCEN<='1';
						cont:='1';
					end if;
				when 6 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
				when 8 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
					jobdone<='1';
					done:='1';
				when others =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
				end case;
			when ST_WRITE =>
				case clkcount is
				when 0 =>		--active bank
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='0';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<=SELADR(ADRWIDTH-1);
					MEMBA0		<=SELADR(ADRWIDTH-2);
					MEMADR		<=SELADR(ADRWIDTH-3 downto ADRWIDTH-15);
					MEMDATOE	<='0';
				when 1 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
					BNCEN<='1';
					BCOUNT<=(others=>'0');
				when 2 =>		--write command & send word
					MEMCKE		<='1';
					MEMCS_N		<='0';
					MEMRAS_N	<='1';
					MEMCAS_N	<='0';
					MEMWE_N		<='0';
					MEMUDQ		<=not SELBSEL(1);
					MEMLDQ		<=not SELBSEL(0);
					MEMBA1		<=SELADR(ADRWIDTH-1);
					MEMBA0		<=SELADR(ADRWIDTH-2);
					MEMADR(12 downto 11)	<=not SELBSEL(1) & not SELBSEL(0);
					MEMADR(10 downto 0)	<='0' & SELADR(9 downto 0);
					MEMDAT		<=SELWDAT;
					MEMDATOE	<='1';
					BNCEN<='1';
					BCOUNT<=BCOUNT+1;
				when 3 =>
					if(SELBLEN=BCOUNT)then
						--break burst and precharge all
						MEMCKE		<='1';
						MEMCS_N		<='0';
						MEMRAS_N	<='0';
						MEMCAS_N	<='1';
						MEMWE_N		<='0';
						MEMUDQ		<='1';
						MEMLDQ		<='1';
						MEMBA1		<='0';
						MEMBA0		<='0';
						MEMADR		<=(others=>'1');
						MEMDATOE	<='0';
					else
						MEMCKE		<='1';
						MEMCS_N		<='1';
						MEMRAS_N	<='1';
						MEMCAS_N	<='1';
						MEMWE_N		<='1';
						MEMUDQ		<=not SELBSEL(1);
						MEMLDQ		<=not SELBSEL(0);
						MEMBA1		<=SELADR(ADRWIDTH-1);
						MEMBA0		<=SELADR(ADRWIDTH-2);
						MEMADR(12 downto 11)	<=not SELBSEL(1) & not SELBSEL(0);
						MEMADR(10 downto 0)	<=(others=>'0');
						MEMDAT		<=SELWDAT;
						MEMDATOE		<='1';
						BCOUNT		<=BCOUNT+1;
						BNCEN<='1';
						cont:='1';
					end if;
				when 5 =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
					JOBDONE<='1';
					done:='1';
				when others =>
					MEMCKE		<='1';
					MEMCS_N		<='1';
					MEMRAS_N	<='1';
					MEMCAS_N	<='1';
					MEMWE_N		<='1';
					MEMUDQ		<='1';
					MEMLDQ		<='1';
					MEMBA1		<='0';
					MEMBA0		<='0';
					MEMADR(12 downto 11)	<="11";
					MEMADR(10 downto 0)	<=(others=>'0');
					MEMDATOE	<='0';
				end case;
			when others =>
				done:='1';
				jobdone<='1';
			end case;
			if(jobbgn='1')then
				clkcount<=0;
			elsif(done='1')then
				clkcount<=20;
			elsif(clkcount<20 and cont='0')then
				clkcount<=clkcount+1;
			end if;
		end if;
	end process;

--	process(clk)begin
--		if(clk' event and clk='0')then
--			smemdat<=pMEMDAT;
--		end if;
--	end process;
	smemdat<=pMEMDAT;
	
	process(clk)
	variable lclkcount	:clkcount_array(0 to latency-1);
	begin
		if(clk' event and clk='1')then
			if(rstn='0')then
				CPURDAT	<=(others=>'0');
				SUBRDAT	<=(others=>'0');
				KCGRDAT	<=(others=>'0');
				VIDDAT	<=(others=>'0');
				FDERDAT	<=(others=>'0');
				FECRDAT	<=(others=>'0');
				SNDRDAT	<=(others=>'0');
				lSTATE	<=(others=>ST_REFRESH);
				lclkcount	:=(others=>0);
				CPURVAL<='0';
				SUBRVAL<='0';
				KCGRVAL<='0';
				VIDRVAL<='0';
				FECRVAL<='0';
				BNCENDLY<=(others=>'0');
			else
				CPURVAL<='0';
				SUBRVAL<='0';
				KCGRVAL<='0';
				VIDRVAL<='0';
				FECRVAL<='0';
				if(lSTATE(latency-1)=st_READ and lclkcount(latency-1)=3)then
					case jobsel is
					when sel_CPU =>
						CPURDAT<=smemdat;
						CPURVAL<='1';
					when sel_SUB =>
						SUBRDAT<=smemdat;
						SUBRVAL<='1';
					when sel_KCG =>
						KCGRDAT<=smemdat;
						KCGRVAL<='1';
					when sel_VID =>
						VIDDAT<=smemdat;
						VIDRVAL<='1';
					when sel_FDE =>
						FDERDAT<=smemdat;
					when sel_FEC =>
						FECRDAT<=smemdat;
						FECRVAL<='1';
					when sel_SND =>
						SNDRDAT<=smemdat;
					when others =>
					end case;
				end if;
				BNCENDLY(latency)<=BNCENDLY(latency-1);
				for i in latency-1 downto 1 loop
					lclkcount(i):=lclkcount(i-1);
					lSTATE(i)<=lSTATE(i-1);
					BNCENDLY(i)<=BNCENDLY(i-1);
				end loop;
				lclkcount(0):=clkcount;
				lSTATE(0)<=STATE;
				BNCENDLY(0)<=BNCEN;
			end if;
		end if;
	end process;

	process(clk)begin
		if(clk' event and clk='1')then
			PMEMCKE		<=MEMCKE;
			PMEMCS_N	<=MEMCS_N;
			PMEMRAS_N	<=MEMRAS_N;
			PMEMCAS_N	<=MEMCAS_N;
			PMEMWE_N	<=MEMWE_N;
			PMEMUDQ		<=MEMUDQ;
			PMEMLDQ		<=MEMLDQ;
			PMEMBA1		<=MEMBA1;
			PMEMBA0		<=MEMBA0;
			PMEMADR		<=MEMADR;
			if(MEMDATOE='1')then
				PMEMDAT		<=MEMDAT;
			else
				PMEMDAT		<=(others=>'Z');
			end if;
		end if;
	end process;
	
--	BCDELAY<=BCOUNT-latency;

	BNCOUNTEN<=	BNCENDLY(latency)	when lSTATE(latency-1)=ST_READ else
					BNCEN	when STATE=ST_WRITE else
					'0';
	
	process(clk)begin
		if(clk' event and clk='1')then
			if(rstn='0')then
				BNUMCOUNT<=(others=>'0');
			else
				if(BNCOUNTEN='0')then
					BNUMCOUNT<=(others=>'0');
				else
					BNUMCOUNT<=BNUMCOUNT+1;
				end if;
			end if;
		end if;
	end process;
	
	CPUBNUM<=	BNUMCOUNT when jobsel=sel_CPU else
					(others=>'0');
	SUBBNUM<=	BNUMCOUNT when jobsel=sel_SUB else
					(others=>'0');
	VIDBNUM<=	BNUMCOUNT when jobsel=sel_VID else
					(others=>'0');
	FECBNUM<=	BNUMCOUNT when jobsel=sel_FEC else
					(others=>'0');
	
end rtl;
