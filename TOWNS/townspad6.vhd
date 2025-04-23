LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE	IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;

entity townspad6 is
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
end townspad6;

architecture selector of townspad6 is
signal	pinsel0,pinsel1,pinsel	:std_logic_vector(1 to 4);
begin
	pinsel0(1)<=	Un and seln;
	pinsel0(2)<=	Dn and seln;
	pinsel0(3)<=	Ln and runn;
	pinsel0(4)<=	Rn and runn;
	
	pinsel1(1)<=	Zn;
	pinsel1(2)<=	Yn;
	pinsel1(3)<=	Xn;
	pinsel1(4)<=	Cn;
	
	pinsel<=pinsel0 when com='0' else pinsel1;
	pin1<=pinsel(1);
	pin2<=pinsel(2);
	pin3<=pinsel(3);
	pin4<=pinsel(4);
	pin6<=An;
	pin7<=Bn;
end selector;
