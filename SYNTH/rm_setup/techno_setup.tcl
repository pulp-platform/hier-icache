#PROVA
#BASENAME LIBRARY
set TECHLIB "UMC_65"
set SERVER_NAME [exec hostname]

switch $SERVER_NAME {
    winnfield { set LIB_PATH "/home/techlibs/faraday"                      }
    micrel205 { set LIB_PATH ""                                            }
    vega      { set LIB_PATH "/home/techlibs/faraday"                      }
    VaccaBoia { set LIB_PATH "/home/techlibs/faraday"                      }
    default   { puts "PLEASE SPECIFY THE MAIN LIBRARY FOLDER!!!!" ; exit 0 }
}

#FARADAY LIBS
set LVT      "$LIB_PATH/ll/lv"
set RVT      "$LIB_PATH/ll/rv"
set HVT      "$LIB_PATH/ll/hv"
set IO       "$LIB_PATH/ll/io"
set LS       "$LIB_PATH/ll/level_shifter"
set IOSC     "$LIB_PATH/ll/iosc_lib"

set MEM_CUT_FOLDER  "$LIB_PATH/mem_cuts"


# setup the Setup...Defaults menusource -echo -verbose /home/techlibs/SAED/common_setup.tcl
set designer "MIcrelLab - Unibo"
set company "ST_Microelectronics"
set snps  [getenv "SYNOPSYS"]
set search_path  [lappend search_path "${snps}/libraries/syn" ]
set search_path  [lappend search_path "${snps}" ]

#Cells Technology_Kit
set search_path  [lappend search_path "$LVT/synopsys"];
set search_path  [lappend search_path "$HVT/synopsys"];
set search_path  [lappend search_path "$RVT/synopsys"];
set search_path  [lappend search_path "$IO/synopsys"];
set search_path  [lappend search_path "$LS/synopsys"];
set search_path  [lappend search_path "$IOSC/synopsys"];
set search_path  [lappend search_path "$MEM_CUT_FOLDER/SHKA65_1024X8X4CM8/synopsys"];  #TCDM_1024
set search_path  [lappend search_path "$MEM_CUT_FOLDER/SHKA65_2048X8X4CM8/synopsys"];  #TCDM_2048
set search_path  [lappend search_path "$MEM_CUT_FOLDER/SHKA65_8192X8X4CM16/synopsys"]; #L2
set search_path  [lappend search_path "$MEM_CUT_FOLDER/SPKA65_1024X64BM1A/synopsys"];  #ROM


set TARGET_LIBRARY_FILES              "uk65lscllmvbbl_108c125_wc.db     \
                                       uk65lscllmvbbh_108c125_wc.db     \
                                       uk65lscllmvbbr_108c125_wc.db     \
                                       level_shifter_090_108c125_wc.db  \
                                       level_shifter_108_090c125_wc.db  \
                                       level_shifter_108_108c125_wc.db  "

set SYMB_LIB                          "uk65lscllmvbbl.sdb  \
                                       uk65lscllmvbbh.sdb  \
                                       uk65lscllmvbbr.sdb  \
                                       u065gioll25mvir.sdb "

set ADDITIONAL_LINK_LIB_FILES         "u065gioll25mvir_18_wc.db             \
                                       iosc_lib_25_wc.db                    \
                                       SHKA65_1024X8X4CM8_ss1p08v125c.db    \
                                       SHKA65_8192X8X4CM16_ss1p08v125c.db   \
                                       SHKA65_2048X8X4CM8_ss1p08v125c.db    \
                                       SPKA65_1024X64BM1A_ss1p08v125c.db    "

set MW_REFERENCE_LIB_DIRS             "$LVT/milkyway/uk65lscllmvbbl                                        \
                                       $HVT/milkyway/uk65lscllmvbbh                                        \
                                       $RVT/milkyway/uk65lscllmvbbr                                        \
                                       $IO/milkyway/u065gioll25mvir_7m2t0f                                 \
                                       $MEM_CUT_FOLDER/SHKA65_1024X8X4CM8/milkyway/SHKA65_1024X8X4CM8      \
                                       $MEM_CUT_FOLDER/SHKA65_8192X8X4CM16/milkyway/SHKA65_8192X8X4CM16    \
                                       $MEM_CUT_FOLDER/SHKA65_2048X8X4CM8/milkyway/SHKA65_2048X8X4CM8      \ 
                                       $MEM_CUT_FOLDER/SPKA65_1024X64BM1A/milkyway/SPKA65_1024X64BM1A      "


set MW_REFERENCE_CONTROL_FILE         ""  ;#  Reference Control file to define the MW ref libs

set TECH_FILE                         "$LIB_PATH/ll/tech/tech.tf"; #Milkyway technology file

set MAP_FILE                          "$LIB_PATH/ll/tech/mapfile"  ;#  Mapping file for TLUplus

set TLUPLUS_MAX_FILE                  "$LIB_PATH/ll/tech/tlu/umc_logic_mixed_mode_65nm_mim_low_k.rcmax.tlu"  ;#  MAX TLUplus file

set TLUPLUS_MIN_FILE                  "$LIB_PATH/ll/tech/tlu/umc_logic_mixed_mode_65nm_mim_low_k.rcmin.tlu" ;#  MIN TLUplus file

set TLUPLUS_TYP_FILE                  "$LIB_PATH/ll/tech/tlu/umc_logic_mixed_mode_65nm_mim_low_k.typ.tlu" ;#  TYP TLUplus File

set MW_POWER_NET                  "VDD" ;
set MW_POWER_PORT                 "VDD" ;
set MW_GROUND_NET                 "VSS" ;
set MW_GROUND_PORT                "VSS" ;

set MIN_ROUTING_LAYER             "ME2"   ;# Min routing layerclock_gating/
set MAX_ROUTING_LAYER             "ME6"   ;# Max routing layer is M8 but M7-M8 are used for power Grid

# Site Specific Variables
set SYNTH_LIB "dw_foundation.sldb dft_jtag.sldb  dft_lbist.sldb  dft_mbist.sldb  standard.sldb"

source ./rm_setup/dontUseCells
source ./rm_setup/delayCells
source ./rm_setup/lowDriveCells

echo " Sourcing names rules \n"
