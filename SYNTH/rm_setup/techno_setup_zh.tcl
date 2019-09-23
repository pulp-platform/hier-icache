#
#  12-oct-06, braendli
#  .synopsys_dc.setup template for dcsh *AND* dctcl mode 
#
#  important: the first character of this file has to 
#             be '#' or dcsh mode wont work... honestly
#


#****** identification ******
set designer {Your Name}
set company  {ETH IIS/DZ}


#****** search path ******
set search_path [concat  \
/usr/pack//umc-65-kgf/faraday/ll/memaker/201301.1.1/synopsys.dz/2014.09 \
/usr/pack/umc-65-kgf/umc/ll/u065gioll25mvir/b04/synopsys \
/usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbh/b03/synopsys \
/usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbl/b03/synopsys \
/usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbr/b03/synopsys \
$search_path]


#****** std.cells/pads, macro cell: symbol, target and link library ******
#set link_library   [list "*" uk65lscllmvbbl_120c25_tc.db uk65lscllmvbbr_120c25_tc.db uk65lscllmvbbh_120c25_tc.db u065gioll25mvir_25_tc.db SHKA65_8192X8X4CM16_tt1p2v25c.db SYKA65_512X8X4CM4_tt1p2v25c.db SHKA65_2048X8X4CM8_tt1p2v25c.db SHKA65_1024X8X4CM8_tt1p2v25c.db]
#set target_library [list uk65lscllmvbbl_120c25_tc.db uk65lscllmvbbr_120c25_tc.db uk65lscllmvbbh_120c25_tc.db u065gioll25mvir_25_tc.db]

set link_library   [list "*" uk65lscllmvbbl_108c125_wc.db uk65lscllmvbbr_108c125_wc.db uk65lscllmvbbh_108c125_wc.db u065gioll25mvir_25_wc.db SHKA65_8192X8X4CM16_ss1p08v125c.db SYKA65_512X8X4CM4_ss1p08v125c.db SHKA65_2048X8X4CM8_ss1p08v125c.db SHKA65_1024X8X4CM8_ss1p08v125c.db]
set target_library [list uk65lscllmvbbl_108c125_wc.db uk65lscllmvbbr_108c125_wc.db uk65lscllmvbbh_108c125_wc.db u065gioll25mvir_25_wc.db]
set symbol_library [list uk65lscllmvbbl.sdb uk65lscllmvbbr.sdb uk65lscllmvbbh.sdb u065gioll25mvir.sdb]
set alib_library_analysis_path "./alib"

#****** Using different Corners and models ******
#**  
#**  The standard cell library for UMC65 has 2 operating voltages 1.2 and 1.0 V
#**  Since the Pad library is characterized for a 1.2V I/O, by default this version is
#**  used. The library extensions change according to library:
#**  
#**                      I/O       1.2V           1.0V
#**    Typical        :  _25_tc    _120c25_tc     _100c25_tc
#**    Worst Case     :  _25_wc    _108c125_wc    _090c125_wc
#**    Best Case      :  _25_bc    _132c0_bc      _110c0_bc
#**
#**  By default the typical values will be used. You can change the lines manually or
#**  uncomment the corresponding line below
#** 
#** WORST CASE: 
#** set target_library [list uk65lscllmvbbl_108c125_wc.db uk65lscllmvbbr_108c125_wc.db uk65lscllmvbbh_108c125_wc.db u065gioll25mvir_25_wc.db]
#** 
#** BEST CASE: 
#** set target_library [list uk65lscllmvbbl_132c0_bc.db uk65lscllmvbbr_132c0_bc.db uk65lscllmvbbh_132c0_bc.db u065gioll25mvir_25_bc.db]
#**
#**  You can change to one of these models. If you have questions 
#**  send e-mail to: dz@ee.ethz.ch
#**
#**********************************************

#****** libraries for DesignWare components synthesis ******
set synthetic_library [concat  $synthetic_library dw_foundation.sldb]
set link_library      [concat  $link_library      dw_foundation.sldb]


#****** work, std.cells/pads, macro cell: design libraries ******
define_design_lib work -path ./WORK

define_design_lib uk65lscllmvbbl -path /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbl/b03/synopsys.dz/2014.09/WORK
define_design_lib uk65lscllmvbbr -path /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbr/b03/synopsys.dz/2014.09/WORK
define_design_lib uk65lscllmvbbh -path /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbh/b03/synopsys.dz/2014.09/WORK
define_design_lib u065gioll25mvir -path /usr/pack/umc-65-kgf/umc/ll/u065gioll25mvir/b04/synopsys.dz/2014.09/WORK



#****** define command aliases ******
alias h   "history"
alias cud "current_design"
alias rad "remove_design -all"


#****** report inferred latches after elaborate ******
set hdlin_check_no_latch true
set hdlin_latch_always_async_set_reset true                


#****** variable for saif export (power estimation) ******
set power_preserve_rtl_hier_names true


#****** vhdl/verilog export variables ******
set vhdlout_dont_write_types true
set vhdlout_write_components false
set verilogout_no_tri true

#***** This should make sure nets are named consistently ********               
set hdlin_presto_net_name_prefix n   

#***** reports with more accuracy ***********************
set report_default_significant_digits  4

#***** Scan ports with better names ********************
set test_scan_in_port_naming_style "SynopsysScanIn%s%s_TI"
set test_scan_out_port_naming_style "SynopsysScanOut%s%s_TO"
set test_scan_enable_port_naming_style "SynopsysScanEn%s_TI"

#***** User customization *******************************
#**
#** if the file .synopsys_user.setup exists it will be sourced

if {[file readable .synopsys_user.setup]} {
  source .synopsys_user.setup
}
