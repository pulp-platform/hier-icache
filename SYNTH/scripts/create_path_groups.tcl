
group_path -name "IO_to_REG"     -from   [get_ports  -filter {@port_direction == in} data_*  ]   -to   [all_registers]  -weight 2.0
group_path -name "REG_to_IO"     -to     [get_ports  -filter {@port_direction == out} data_* ]   -from [all_registers]  -weight 2.0
group_path -name "IO_to_IO_COMB" -from   [get_ports  -filter {@port_direction == in} data_*  ]   -to   [get_ports  -filter {@port_direction == out} data_*  ]     -weight 2.0
