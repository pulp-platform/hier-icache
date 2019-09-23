

ungroup [get_cells PRI_ICACHE[0].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[1].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[2].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[3].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[4].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[5].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[6].i_pri_icache/* ] -flatten
ungroup [get_cells PRI_ICACHE[7].i_pri_icache/* ] -flatten
ungroup [get_cells ICACHE_INTERCONNECT/*        ] -flatten


ungroup [get_cells Main_Icache[*].i_main_shared_icache/*] -flatten 
