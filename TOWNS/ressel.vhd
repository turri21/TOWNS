LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RESSEL is
port(
	HDS0	:in std_logic_vector(10 downto 0);
	HDE0	:in std_logic_vector(10 downto 0);
	HDS1	:in std_logic_vector(10 downto 0);
	HDE1	:in std_logic_vector(10 downto 0);
	VDS0	:in std_logic_vector(10 downto 0);
	VDE0	:in std_logic_vector(10 downto 0);
	VDS1	:in std_logic_vector(10 downto 0);
	VDE1	:in std_logic_vector(10 downto 0);
	ZH0	:in std_logic_vector(3 downto 0);
	ZV0	:in std_logic_vector(3 downto 0);
	ZH1	:in std_logic_vector(3 downto 0);
	ZV1	:in std_logic_vector(3 downto 0);
	
	H0time	:out std_logic_Vector(3 downto 0);
	V0time	:out std_logic_Vector(3 downto 0);
	
	H1time	:out std_logic_Vector(3 downto 0);
	V1time	:out std_logic_Vector(3 downto 0)
);
end RESSEL;

architecture rtl of RESSEL is
signal	H0res	:std_logic_vector(10 downto 0);
signal	H1res	:std_logic_vector(10 downto 0);
signal	V0res	:std_logic_vector(10 downto 0);
signal	V1res	:std_logic_vector(10 downto 0);

signal	Hres	:std_logic_vector(10 downto 0);
signal	Vres	:std_logic_vector(10 downto 0);

signal	Htime	:std_logic_vector(3 downto 0);
signal	Vtime	:std_logic_vector(3 downto 0);

component calcres
port(
	DS	:in std_logic_vector(10 downto 0);
	DE	:in std_logic_vector(10 downto 0);
	Z	:in std_logic_vector(3 downto 0);

	res	:out std_logic_vector(10 downto 0)
);
end component;
begin
	H0r	:calcres port map(HDS0,HDE0,ZH0,H0res);
	V0r	:calcres port map(VDS0,VDE0,ZV0,V0res);
	H1r	:calcres port map(HDS1,HDE1,ZH1,H1res);
	V1r	:calcres port map(VDS1,VDE1,ZV1,V1res);

	Hres<=	H0res when H0res>H1res else H1res;
	Vres<=	V0res when V0res>V1res else V1res;
	
	process(Hres)begin
		if(Hres>x"320")then
			Htime<="0001";
		elsif(Hres>x"215")then
			Htime<="0010";
		elsif(Hres>x"190")then
			Htime<="0011";
		elsif(Hres>x"140")then
			Htime<="0100";
		elsif(Hres>x"10a")then
			Htime<="0101";
		elsif(Hres>x"0e4")then
			Htime<="0110";
		elsif(Hres>x"0c8")then
			Htime<="0111";
		elsif(Hres>x"0b1")then
			Htime<="1000";
		elsif(Hres>x"0a0")then
			Htime<="1001";
		elsif(Hres>x"091")then
			Htime<="1010";
		elsif(Hres>x"085")then
			Htime<="1011";
		elsif(Hres>x"07b")then
			Htime<="1100";
		elsif(Hres>x"072")then
			Htime<="1101";
		elsif(Hres>x"06a")then
			Htime<="1110";
		else
			Htime<="1111";
		end if;
	end process;
			
	process(Vres)begin
		if(Vres>x"258")then
			Vtime<="0001";
		elsif(Vres>x"190")then
			Vtime<="0010";
		elsif(Vres>x"12c")then
			Vtime<="0011";
		elsif(Vres>x"0f0")then
			Vtime<="0100";
		elsif(Vres>x"0c8")then
			Vtime<="0101";
		elsif(Vres>x"0ab")then
			Vtime<="0110";
		elsif(Vres>x"096")then
			Vtime<="0111";
		elsif(Vres>x"085")then
			Vtime<="1000";
		elsif(Vres>x"078")then
			Vtime<="1001";
		elsif(Vres>x"06d")then
			Vtime<="1010";
		elsif(Vres>x"064")then
			Vtime<="1011";
		elsif(Vres>x"05c")then
			Vtime<="1100";
		elsif(Vres>x"055")then
			Vtime<="1101";
		elsif(Vres>x"050")then
			Vtime<="1110";
		else
			Vtime<="1111";
		end if;
	end process;
	
	H0time<=Htime;
	H1time<=Htime;
	V0time<=Vtime;
	V1time<=Vtime;
end rtl;

	