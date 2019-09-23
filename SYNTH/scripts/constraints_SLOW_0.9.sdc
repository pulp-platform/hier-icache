
set SID "1.5"
set SOD "1.5"

current_design $OUT_FILENAME\_SH_CACHE_SIZE$SH_CACHE_SIZE\_PRI_CACHE_SIZE$PRI_NB_WAYS


## Boundary
set_driving_cell -lib_cell BUF_X6M_A9TR -pin Y -from_pin A [ all_inputs  ]
set_load                                               0.1 [ all_outputs ]

create_clock -period 4  -name CLK       [ get_ports clk  ]
set_clock_uncertainty   0.7              [ get_clocks CLK ]
set_clock_transition    0.2              [ get_clocks CLK ]
set_clock_latency -max  2.2              [ get_clocks CLK ]
set_clock_latency -min  1                [ get_clocks CLK ]



set_case_analysis 0 [get_ports test_en_i ]


set_input_delay  $SID  -clock CLK [get_ports     fetch_*_i* ]
set_output_delay $SOD  -clock CLK [get_ports     fetch_*_o* ]

set_input_delay   0.8  -clock CLK  [get_ports sh* -filter {@port_direction == in}]
set_output_delay  0.8  -clock CLK  [get_ports sh* -filter {@port_direction == out}]

set_input_delay   0.8  -clock CLK  [get_ports pri* -filter {@port_direction == in}]
set_output_delay  0.8  -clock CLK  [get_ports pri* -filter {@port_direction == out}]

set_input_delay   0.8  -clock CLK  [get_ports axi* -filter {@port_direction == in}]
set_output_delay  0.8  -clock CLK  [get_ports axi* -filter {@port_direction == out}]


# Constraints fro Private caches
for { set i 0 } { $i < 8 } { incr i } {
   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rdata_o* ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rdata_o* ]
   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rdata_o* ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rdata_o* ]

   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/d*]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/d*]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]
   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/d*]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/d*]  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_DATA_WAY_[*].DATA_BANK/MemContentxDP_reg*/Q ]

   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rvalid_o* ]
   set_multicycle_path 2 -setup -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_gnt_o*    ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_rvalid_o* ]
   set_multicycle_path 1 -hold  -through [get_pins PRI_ICACHE[$i].i_pri_icache/_TAG_WAY_[*].TAG_BANK/MemContentxDP_reg*/Q]     -through [get_pins PRI_ICACHE[$i].i_pri_icache/fetch_gnt_o*    ]
}




#Constraints for Main shared cache bank
set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]  -through [get_pins i_main_shared_icache/fetch_r_rdata_o* ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]  -through [get_pins i_main_shared_icache/fetch_r_rdata_o* ]
set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_r_rdata_o* ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_r_rdata_o* ]

set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/d*]  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/d*]  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]
set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/d*]  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/d*]  -through [get_pins i_main_shared_icache/DATA_RAM_WAY[*].DATA_RAM/scm_data/MemContentxDP_reg*/Q ]

set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_r_valid_o* ]
set_multicycle_path 2 -setup -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_grant_o*   ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_r_valid_o* ]
set_multicycle_path 1 -hold  -through [get_pins i_main_shared_icache/TAG_RAM_WAY[*].TAG_RAM/scm_tag/MemContentxDP_reg*/Q]      -through [get_pins i_main_shared_icache/fetch_grant_o*   ]

