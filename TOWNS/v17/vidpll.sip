set_global_assignment -entity "vidpll" -library "lib_vidpll" -name IP_TOOL_NAME "altera_pll_reconfig"
set_global_assignment -entity "vidpll" -library "lib_vidpll" -name IP_TOOL_VERSION "17.0"
set_global_assignment -entity "vidpll" -library "lib_vidpll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_vidpll" -name SPD_FILE [file join $::quartus(sip_path) "vidpll.spd"]

set_global_assignment -library "lib_vidpll" -name MISC_FILE [file join $::quartus(sip_path) "vidpll_sim/vidpll.v"]
set_global_assignment -library "lib_vidpll" -name MISC_FILE [file join $::quartus(sip_path) "vidpll_sim/altera_pll_reconfig/altera_pll_reconfig_top.v"]
set_global_assignment -library "lib_vidpll" -name MISC_FILE [file join $::quartus(sip_path) "vidpll_sim/altera_pll_reconfig/altera_pll_reconfig_core.v"]
set_global_assignment -library "lib_vidpll" -name MISC_FILE [file join $::quartus(sip_path) "vidpll_sim/altera_pll_reconfig/altera_std_synchronizer.v"]
