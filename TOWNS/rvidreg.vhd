LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rvidreg	is
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
end rvidreg;

architecture rtl of rvidreg is
signal	cursorlsb	:std_logic;
signal	twidth		:std_logic;
signal	rdsel			:std_logic_vector(1 downto 0);
signal	wrsel			:std_logic_Vector(3 downto 0);
signal	cpupage		:std_logic;
signal	shsync		:std_logic;
signal	svsync		:std_logic;
begin

	process(clk,rstn)begin
		if(rstn='0')then
			cursorlsb<='0';
			twidth<='0';
			rvid_dispen<=(others=>'0');
			rvid_disppage<='0';
			wrsel<=(others=>'0');
			rdsel<=(others=>'0');
			cpupage<='0';
		elsif(clk' event and clk='1')then
			if(mcs='1' and mwr='1')then
				if(maddr='0')then
					if(mbsel(0)='1')then
						cursorlsb<=mwdat(5);
						twidth<=mwdat(3);
					end if;
					if(mbsel(1)='1')then
						rdsel<=mwdat(15 downto 14);
						wrsel<=mwdat(11 downto 8);
					end if;
					if(mbsel(2)='1')then
						rvid_disppage<=mwdat(20);
						rvid_dispen<=mwdat(21) & mwdat(18 downto 16);
					end if;
					if(mbsel(3)='1')then
						cpupage<=mwdat(28);
					end if;
				end if;
			end if;
			if(iocs='1' and iowr='1')then
				case ioaddr is
				when "000" =>
					cursorlsb<=iowdat(5);
					twidth<=iowdat(3);
				when "001" =>
					rdsel<=iowdat(7 downto 6);
					wrsel<=iowdat(3 downto 0);
				when "010" =>
					rvid_disppage<=iowdat(4);
					rvid_dispen<=iowdat(5) & iowdat(2 downto 0);
				when "011" =>
					cpupage<=iowdat(4);
				when others =>
				end case;
			end if;
		end if;
	end process;
	
	process(clk)begin
		if(clk' event and clk='1')then
			shsync<=hsync;
			svsync<=vsync;
		end if;
	end process;
	
	process(clk,rstn)begin
		if(rstn='0')then
			mrval<='0';
			mrdat<=(others=>'0');
		elsif(clk' event and clk='1')then
			mrval<='0';
			mrdat<=(others=>'0');
			if(mcs='1' and mrd='1')then
				if(maddr='0')then
					mrdat<="000" & cpupage & "0000" & x"00" & rdsel & "00" & wrsel & "00" & cursorlsb & "0" & twidth & "000";
				else
					mrdat<=x"00" & shsync & "0010" & svsync & "00" & x"0000";
				end if;
				mrval<='1';
			end if;
		end if;
	end process;
	
	iordat<=	"00" & cursorlsb & "0" & twidth & "000" when ioaddr="000" else
				rdsel & "00" & wrsel when ioaddr="001" else
				"000" & cpupage & "0000" when ioaddr="011" else
				shsync & "0010" & svsync & "00" when ioaddr="110" else
				(others=>'0');
	
	iodoe<=iocs and  iord;
						
	rvid_rdsel<=rdsel;
	rvid_wrsel<=wrsel;
	rvid_cpupage<=cpupage;
	
end rtl;
