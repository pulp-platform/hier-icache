#PROVA
#BASENAME LIBRARY
set TECHLIB "TSMC_55"
set TRACKS  "9"

#DOLPHIN SPRAM CUT
set MUX     "8"
set SEGMENT "2"


set SERVER_NAME [exec hostname]

switch $SERVER_NAME {
    winnfield { set LIB_PATH "/home/techlibs/tsmc/cln55lp"                 }
    micrel205 { set LIB_PATH "/home/techlibs/tsmc/cln55lp"                 }
    vega      { set LIB_PATH "/home/techlibs/tsmc/cln55lp"                 }
    compute.dei.unibo.it { set LIB_PATH "/tech/tsmc/cln55lp"               }
    VaccaBoia { set LIB_PATH "/home/techlibs/tsmc/cln55lp"                 }
    default   { puts "PLEASE SPECIFY THE MAIN LIBRARY FOLDER!!!!" ; exit 0 }
}


if { $USE_LVT == "TRUE" }  {
   set CLK_GATE_CELL "sc9_cln55lp_base_lvt_ss_typical_max_1p08v_125c/PREICG_X2P5B_A9TL"
} else {
          if { $USE_RVT == "TRUE" }  {
              set CLK_GATE_CELL "sc9_cln55lp_base_rvt_ss_typical_max_1p08v_125c/PREICG_X2P5B_A9TR"
          } else {
              set CLK_GATE_CELL "sc9_cln55lp_base_hvt_ss_typical_max_1p08v_125c/PREICG_X2P5B_A9TH"
          }  
}

  set HVT      "$LIB_PATH/sc9_base_hvt/r0p0/"
  set RVT      "$LIB_PATH/sc9_base_rvt/r0p0/"
  set LVT      "$LIB_PATH/sc9_base_lvt/r0p0/"
  set PMK      "$LIB_PATH/sc9_pmk_rvt_hvt/r0p0/"
  set CLICK    "$LIB_PATH/IPS/SESAME-CLICK_TSMC_55nm_LP_HVT_v4.0.0_FINAL_DELIVERY-2"

set ARM_MEM_CUT_FOLDER   "$LIB_PATH/IPS/TSMC_55_MEM_CUTS"
set DOLPH_MEM_CUT_FOLDER "$LIB_PATH/IPS/DOLPHIN_SRAM"

# setup the Setup...Defaults menusource -echo -verbose /home/techlibs/SAED/common_setup.tcl
set designer "MIcrelLab - Unibo"
set company "ST_Microelectronics"
set snps  [getenv "SYNOPSYS"]
set search_path  [lappend search_path "${snps}/libraries/syn" ]
set search_path  [lappend search_path "${snps}" ]

#Cells Technology_Kit
set search_path  [lappend search_path "$LVT/db"]; #-ccs-tn
set search_path  [lappend search_path "$HVT/db"]; #-ccs-tn
set search_path  [lappend search_path "$RVT/db"]; #-ccs-tn
set search_path  [lappend search_path "$PMK/db"]; #-ccs-tn
set search_path  [lappend search_path "$CLICK/SESAME-CLICK_FrontEnd/SESAME-CLICK_LIB/NLM" ]; #CLICK

set search_path  [lappend search_path "$DOLPH_MEM_CUT_FOLDER/SpRAM_1kx32m8s2/FrontEnd/LIBERTY_v1" ]; #TCDM L1 CLUSTER

set LVT_LIST  [join  "sc9_cln55lp_base_lvt_ss_typical_max_1p08v_125c.db sc9_cln55lp_base_lvt_ss_typical_max_0p90v_125c.db" ]
set HVT_LIST  [join  "sc9_cln55lp_base_hvt_ss_typical_max_1p08v_125c.db sc9_cln55lp_base_hvt_ss_typical_max_0p90v_125c.db" ]
set RVT_LIST  [join  "sc9_cln55lp_base_rvt_ss_typical_max_1p08v_125c.db sc9_cln55lp_base_rvt_ss_typical_max_0p90v_125c.db" ]

set TARGET_LIBRARY_FILES  [list  "sc9_cln55lp_pmk_rvt_hvt_ss_typical_max_1p08v_125c.db sc9_cln55lp_pmk_rvt_hvt_ss_typical_max_0p90v_125c.db" ]


set ADDITIONAL_LINK_LIB_FILES  [list TCDM_1024_32_BE_WC_SS_1V08_125c.db \
                                     TCDM_1024_32_BE_WC_SS_0V9_125c.db  \
                                     SESAME-CLICK_TSMC_55nm_LP_HVT_SS_1V08_125C_nlm.db \
                                     SESAME-CLICK_TSMC_55nm_LP_HVT_SS_0V9_125C_nlm.db ]


if { $USE_RVT == "TRUE" }  {
  set TARGET_LIBRARY_FILES   [ join "$RVT_LIST $TARGET_LIBRARY_FILES" ];
} else {
  set ADDITIONAL_LINK_LIB_FILES   [join "$RVT_LIST $ADDITIONAL_LINK_LIB_FILES" ];
}

if { $USE_LVT == "TRUE" }  {
  set TARGET_LIBRARY_FILES   [join "$LVT_LIST $TARGET_LIBRARY_FILES"];
} else {
  set ADDITIONAL_LINK_LIB_FILES   [join "$LVT_LIST $ADDITIONAL_LINK_LIB_FILES"];
}

if { $USE_HVT == "TRUE" }  {
  set TARGET_LIBRARY_FILES   [join "$HVT_LIST $TARGET_LIBRARY_FILES"];
} else {
  set ADDITIONAL_LINK_LIB_FILES   [join "$HVT_LIST $ADDITIONAL_LINK_LIB_FILES"];
}

set SYMB_LIB                          " "


                                        

set MW_REFERENCE_LIB_DIRS             "$RVT/milkyway/1p7m_4x2z/sc9_cln55lp_base_rvt                     \
                                       $HVT/milkyway/1p7m_4x2z/sc9_cln55lp_base_hvt                     \
                                       $LVT/milkyway/1p7m_4x2z/sc9_cln55lp_base_lvt                     \
                                       $PMK/milkyway/1p7m_4x2z/sc9_cln55lp_pmk_rvt_hvt                  \
                                       $DOLPH_MEM_CUT_FOLDER/SpRAM_1kx32m8s2/BackEnd/MW/TCDM_1024_32_BE \
                                       $CLICK/SESAME-CLICK_BackEnd/SESAME-CLICK_MILKYWAY/SESAME-CLICK_TSMC_55nm_LP_HVT "



set MW_REFERENCE_CONTROL_FILE         ""  ;#  Reference Control file to define the MW ref libs

set TECH_FILE                         "$LIB_PATH/tech/sc12_1p7m_4x2z.tf"; #Milkyway technology file

set MAP_FILE                          "$LIB_PATH/tech/mapfile"  ;#  Mapping file for TLUplus

set TLUPLUS_MAX_FILE                  "$LIB_PATH/tech/cln55lp_1p07m+alrdl_4x2z_rcworst.tluplus"  ;#  MAX TLUplus file

set TLUPLUS_MIN_FILE                  "$LIB_PATH/tech/cln55lp_1p07m+alrdl_4x2z_rcbest.tluplus" ;#  MIN TLUplus file

set TLUPLUS_TYP_FILE                  "" ;#  TYP TLUplus File

set MW_POWER_NET                  "VDD" ;
set MW_POWER_PORT                 "VDD" ;
set MW_GROUND_NET                 "VSS" ;
set MW_GROUND_PORT                "VSS" ;

set MIN_ROUTING_LAYER             "M2"   ;# Min routing layerclock_gating/
set MAX_ROUTING_LAYER             "M9"   ;# Max routing layer is M8 but M7-M8 are used for power Grid

# Site Specific Variables
set SYNTH_LIB "dw_foundation.sldb dft_jtag.sldb  dft_lbist.sldb  dft_mbist.sldb  standard.sldb"

source ./rm_setup/dontUseCells
source ./rm_setup/delayCells
source ./rm_setup/lowDriveCells

echo " Sourcing names rules \n"
