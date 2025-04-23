LIBRARY	IEEE,work;
USE	IEEE.STD_LOGIC_1164.ALL;
USE	IEEE.STD_LOGIC_ARITH.ALL;
USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SOUNDREG is
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
end SOUNDREG;

architecture rtl of SOUNDREG is
subtype VRlev is std_logic_vector(6 downto 0);
type VRrev_array_t is array(natural range <>) of VRlev;
signal	VRrev_array	:VRrev_array_t(0 to 7);
signal	VR0sel,VR1sel	:integer range 0 to 3;
signal	ADflagb	:std_logic;
signal	intmask	:std_logic_vector(7 downto 0);
signal	intpcmx	:std_logic;
signal	mutex		:std_logic_vector(7 downto 0);
signal	full		:std_logic_vector(7 downto 0);
signal	ADflagrd	:std_logic_vector(1 downto 0);
signal	LOFFb		:std_logic;
signal	MUTEb		:std_logic;
begin
	
	process(clk,rstn)
	variable vrsel	:integer range 0 to 3;
	begin
		if(rstn='0')then
			VR0sel<=0;
			VR1sel<=0;
			LOFFb<='0';
			MUTEb<='0';
			intmask<=(others=>'0');
			ADflagb<='0';
			mutex<=(others=>'0');
			ADclear<='0';
			ADflagrd<="00";
		elsif(clk' event and clk='1')then
			ADclear<='0';
			if(ADflag='1')then
				ADflagb<='1';
			end if;
			if(cs='1' and wr='1')then
				case addr is
				when x"0" =>
					VRrev_array(VR0sel)(5 downto 0)<=wdat(5 downto 0);
				when x"1" =>
					vrsel:=conv_integer(wdat(1 downto 0));
					VRrev_array(vrsel)(6)<=wdat(4);
					VR0sel<=vrsel;
					mutex(vrsel)<=wdat(2);
					full(vrsel)<=wdat(3);
				when x"2" =>
					VRrev_array(VRsel+4)(5 downto 0)<=wdat(5 downto 0);
				when x"3" =>
					vrsel:=conv_integer(wdat(1 downto 0));
					VRrev_array(vrsel+4)(6)<=wdat(4);
					VR1sel<=vrsel;
					mutex(vrsel+4)<=wdat(2);
					full(vrsel+4)<=wdat(3);
				when x"8" =>
					ADclear<='1';
					ADflagb<='0';
				when x"a" =>
					intmask<=wdat;
				when x"c" =>
					LOFFb<=wdat(7);
					MUTEb<=wdat(6);
				when others =>
				end case;
			end if;
			ADflagrd(1)<=ADflagrd(0);
			if(cs='1' and rd='1' and addr=x"8")then
				ADflagrd(0)<='1';
			else
				ADflagrd(0)<='0';
			end if;
			if(ADflagrd="10")then
				ADflagb<='0';
			end if;
		end if;
	end process;
	
	rdat<=	"00" & VRrev_array(VR0sel)(5 downto 0)	when addr=x"0" else
				"000" & VRrev_array(VR0sel)(6) & full(VR0sel) & mutex(VR0sel) & conv_std_logic_vector(VR0sel,2) when addr=x"1" else
				"00" & VRrev_array(VR1sel+4)(5 downto 0)	when addr=x"2" else
				"000" & VRrev_array(VR1sel+4)(6) & full(VR1sel+4) & mutex(VR1sel+4) & conv_std_logic_vector(VR1sel,2) when addr=x"3" else
				ADdata when addr=x"7" else
				"0000000" & ADflagb when addr=x"8" else
				"0000" & intpcmx & "00" & intOPN when addr=x"9" else
				intmask when addr=x"a" else
				intPCM when addr=x"b" else
				LOFFb & MUTEb & "000000" when addr=x"c" else
				(others=>'0');
	doe<='1' when cs='1' and rd='1' else '0';
	
	VR0<=VRrev_array(0);
	VR1<=VRrev_array(1);
	VR2<=VRrev_array(2);
	VR3<=VRrev_array(3);
	VR4<=VRrev_array(4);
	VR5<=VRrev_array(5);
	VR6<=VRrev_array(6);
	VR7<=VRrev_array(7);
	mute0<=mutex(0);
	mute1<=mutex(1);
	mute2<=mutex(2);
	mute3<=mutex(3);
	mute4<=mutex(4);
	mute5<=mutex(5);
	mute6<=mutex(6);
	mute7<=mutex(7);
	
end rtl;
