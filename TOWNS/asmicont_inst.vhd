asmicont_inst : asmicont PORT MAP (
		addr	 => addr_sig,
		clkin	 => clkin_sig,
		rden	 => rden_sig,
		read	 => read_sig,
		reset	 => reset_sig,
		busy	 => busy_sig,
		data_valid	 => data_valid_sig,
		dataout	 => dataout_sig,
		read_address	 => read_address_sig
	);
