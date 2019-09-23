#!/bin/tcsh
source /home/cad/synopsys/synopsys.tcsh
setenv SITE BOLOGNA
dc_shell-xg-t -topo -64 -output_log_file synt.log -f scripts/go_synth.tcl 
