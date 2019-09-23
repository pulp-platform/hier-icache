#SYNTHESIS SCRIPT

source scripts/utils/print_logo.tcl
suppress_message {VER-130 }
after 3000

#1) PREPARE THE ENVIRONMET
#Number of Cores
set_host_option -max_core 4
set timing_enable_through_paths true

set reAnalyzeRTL "TRUE"

set OUT_FILENAME "icache_hier_top"


#2) ANALIZE THE RTL CODE or Read the GTECH
sh mkdir -p ./unmapped

if { $reAnalyzeRTL == "TRUE" } {
    file delete -force -- ./work
    source -echo -verbose ./scripts/analyze/analyze.tcl
    elaborate icache_hier_top -parameters "SH_CACHE_SIZE => $SH_CACHE_SIZE, PRI_CACHE_SIZE => $PRI_NB_WAYS"
    write -format verilog -hier -o ./unmapped/$OUT_FILENAME.v
    write -format ddc -hier -o ./unmapped/$OUT_FILENAME.ddc
} else {
     read_file  -format ddc  ./unmapped/$OUT_FILENAME.ddc
}

current_design $OUT_FILENAME\_SH_CACHE_SIZE$SH_CACHE_SIZE\_PRI_CACHE_SIZE$PRI_NB_WAYS

link
after 10000
set uniquify_naming_style "icache_hier_%s_%d"
uniquify -force


#3) Ungroup script
source -echo -verbose scripts/ungroup_script.tcl
after 3000

source scripts/icache_hier.upf
after 3000


#set auto_wire_load_selection false
#set_wire_load_mode top
#set_wire_load_model -name "Zero"

if { $USE_LOW_VOLTAGE_SCENARIO == "TRUE" }  {
    create_scenario LOW_VOLTAGE
}
if { $USE_NOM_VOLTAGE_SCENARIO == "TRUE" }  {
    create_scenario NOM_VOLTAGE
}


#6) LOAD SCENARIOS CONSTRAINT
#Contraint files here
#MMMC Synthesis
if { $USE_NOM_VOLTAGE_SCENARIO == "TRUE" }  {
    current_scenario NOM_VOLTAGE
    set_voltage 1.08  -object_list  {VDD}
    set_voltage 0.00  -object_list  {VSS}
    source -echo -verbose scripts/constraints_SLOW_1.08.sdc
    source -echo -verbose  scripts/create_path_groups.tcl
    set_operating_conditions ss_typical_max_1p08v_125c
    set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                       -min_tluplus $TLUPLUS_MIN_FILE \
                       -tech2itf_map $MAP_FILE
}

if { $USE_LOW_VOLTAGE_SCENARIO == "TRUE" }  {
    current_scenario LOW_VOLTAGE
    set_voltage 0.90  -object_list  {VDD}
    set_voltage 0.00  -object_list  {VSS}
    source -echo -verbose scripts/constraints_SLOW_0.9.sdc
    source -echo -verbose  scripts/create_path_groups.tcl
    set_operating_conditions ss_typical_max_0p90v_125c
    set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                       -min_tluplus $TLUPLUS_MIN_FILE \
                       -tech2itf_map $MAP_FILE
}




#7) INSERT CLOCK GATE
sh mkdir -p reports
source -echo -verbose ./scripts/insert_clock_gating.tcl


#10) Read the Floorplan
# extract_physical_constraints def/pulp_chip.def


#11) Compile Ultra
compile_ultra -scan -no_autoungroup -no_boundary_optimization -timing -gate_clock


#12) Incremental Compile
set_fix_multiple_port_nets -all -buffer_constants -outputs -feedthroughs [get_designs *]
set_scenario_options -scenarios [all_scenarios]  -setup true  -leakage_power true  -dynamic_power true 

compile_ultra -inc -timi

sh mkdir -p ./reports

foreach scen [all_active_scenarios] {
    report_timing  -scenarios $scen -voltage > reports/cluster_domain_timing_$scen.rpt  
}


#source scripts/genReportsLS.tcl


#13)
sh mkdir -p ./mapped
write -f ddc -hierarchy  -output ./mapped/$OUT_FILENAME.ddc

change_names -rules verilog -hier
define_name_rules fixbackslashes -allowed "A-Za-z0-9_" -first_restricted "\\" -remove_chars
change_names -rule fixbackslashes -h

sh mkdir -p ./export
write_sdc -nosplit ./export/$OUT_FILENAME.sdc
write -format verilog -hier -o ./export/$OUT_FILENAME.v
#check_mv_design -level_shifters -verbose > reports/$OUT_FILENAME\_level_shifter.rpt
write_parasitics -format distributed -output export/$OUT_FILENAME.spef
write_sdf export/$OUT_FILENAME\.sdf

#14)
# exit
