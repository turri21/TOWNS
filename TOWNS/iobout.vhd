library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity iobout is
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
end iobout;

architecture rtl of iobout is
signal	oreg	:std_logic_vector(7 downto 0);
begin
	process(clk,rstn)begin
		if(rstn='0')then
			oreg<=(others=>'0');
		elsif(clk' event and clk='1')then
			if(cs='1' and wr='1')then
				oreg<=indat;
			end if;
		end if;
	end process;

	out0<=oreg(0);
	out1<=oreg(1);
	out2<=oreg(2);
	out3<=oreg(3);
	out4<=oreg(4);
	out5<=oreg(5);
	out6<=oreg(6);
	out7<=oreg(7);
	
end rtl;
