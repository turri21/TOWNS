library IEEE,work;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ioexc is
port(
	baddr	:in std_logic_vector(15 downto 0);
	
	exc	:out std_logic
);
end ioexc;

architecture rtl of ioexc is
begin
	exc<=
		'1' when baddr=x"0078" else
		'1' when baddr=x"0a0a" else	--modem
		'1' when baddr=x"0a0c" else	--usart fifo
		'1' when baddr=x"0a0d" else	--usart fifo
		'1' when baddr=x"0c34" else
		'1' when baddr=x"0c80" else
		'1' when baddr=x"0c82" else
		'1' when baddr=x"0c8c" else
		'1' when baddr=x"0c8d" else
		'1' when baddr=x"0c90" else
		'1' when baddr=x"0c92" else
		'1' when baddr=x"0c9c" else
		'1' when baddr=x"0c9d" else
		'1' when baddr=x"0cc0" else
		'1' when baddr=x"0cc2" else
		'1' when baddr=x"0ccc" else
		'1' when baddr=x"0ccd" else
		'1' when baddr=x"0cd0" else
		'1' when baddr=x"0cd2" else
		'1' when baddr=x"0cdc" else
		'1' when baddr=x"0cdd" else
		'1' when baddr=x"0fb0" else
		'1' when baddr=x"0fb2" else
		'1' when baddr=x"41ff" else
		'0';
end rtl;
