set NUM_CORES 8

set DESIGN_NAME     "icache_hier_top"
set DESIGN_PATH     "../RTL"
set INCDIR          "../SIM"

set PRI_NB_WAYS    "256"
set SH_CACHE_SIZE  "4096"


#CHOSE ONLY ONE CORE
set reAnalyzeRTL   "TRUE"
set doDFT          "FALSE"
set OUT_FILENAME   "ulpcluster"

#SCENARIOS (Select at least one scenario, or Both to MMMC synthesis)
set USE_LOW_VOLTAGE_SCENARIO "FALSE"
set USE_NOM_VOLTAGE_SCENARIO "TRUE"

set USE_LVT "FALSE"
set USE_RVT "TRUE"
set USE_HVT "FALSE"



set search_path [ join "$INCDIR       
                        $search_path" 
                ]

define_design_lib work -path ./work
