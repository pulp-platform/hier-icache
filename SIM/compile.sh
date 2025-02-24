#!/bin/bash

BITS=$1
rm -rf work

#Dependancies!!!!
set REPO_PATH="../RTL"

cd ../RTL
git clone git@github.com:pulp-platform/axi.git --branch v0.29.1
git clone git@github.com:pulp-platform/axi_slice.git --branch v1.1.0
git clone git@github.com:pulp-platform/common_cells.git --branch v1.21.0
git clone git@github.com:pulp-platform/tech_cells_generic.git --branch v0.2.3
# cd tech_cells_generic
# git checkout 812f60a4a46
# cd ..
git clone git@github.com:pulp-platform/icache-intc.git --branch pulp-v1.0
git clone git@github.com:pulp-platform/scm.git --branch v1.0.0
cd ../SIM

# COMPILE THE RTL
 vlog -sv -work work -quiet ../RTL/axi/src/axi_pkg.sv +incdir+../RTL/axi/include +incdir+../RTL/common_cells/include
 vlog -sv -work work -quiet ../RTL/axi/src/axi_intf.sv +incdir+../RTL/axi/include +incdir+../RTL/common_cells/include
 vlog -sv -work work -quiet ../RTL/axi/src/axi_mux.sv +incdir+../RTL/axi/include +incdir+../RTL/common_cells/include
 vlog -sv -work work -quiet ../RTL/axi/src/axi_id_prepend.sv +incdir+../RTL/axi/include +incdir+../RTL/common_cells/include

 vlog -quiet -sv ../RTL/TOP/icache_hier_top.sv +incdir+../RTL/axi/include
 echo "--------------------------------------"
 if [ "$BITS" == "32" ]
 then
     echo "CORE USE 32 BITS INTERFACE"
     echo "--------------------------------------"
     vlog -quiet -sv ../RTL/L1_CACHE/pri_icache_controller.sv +define+HIERARCHY_ICACHE_32BIT
 else
     echo "CORE USE 128 BITS INTERFACE"
     echo "--------------------------------------"
     vlog -quiet -sv ../RTL/L1_CACHE/pri_icache_controller.sv
 fi

 vlog -quiet -sv ../RTL/L1_CACHE/pri_icache.sv
 vlog -quiet -sv ../RTL/L1_CACHE/register_file_1w_multi_port_read.sv
 vlog -quiet -sv ../RTL/L1_CACHE/register_file_1w_multi_port_read_test_wrap.sv
 vlog -quiet -sv ../RTL/L1_CACHE/refill_arbiter.sv

 vlog -quiet -sv ../RTL/L1.5_CACHE/AXI4_REFILL_Resp_Deserializer.sv
 vlog -quiet -sv ../RTL/L1.5_CACHE/share_icache.sv
 vlog -quiet -sv ../RTL/L1.5_CACHE/share_icache_controller.sv
 vlog -quiet -sv ../RTL/L1.5_CACHE/RefillTracker_4.sv
 vlog -quiet -sv ../RTL/L1.5_CACHE/REP_buffer_4.sv
 vlog -quiet -sv ../RTL/L1.5_CACHE/ram_ws_rs_data_scm.sv +define+USE_SRAM
 vlog -quiet -sv ../RTL/L1.5_CACHE/ram_ws_rs_tag_scm.sv  +define+USE_SRAM




 # COMPILE RTL from other Repositories

 vlog -sv -work work -quiet ../RTL/axi_slice/axi_r_buffer.sv
 vlog -sv -work work -quiet ../RTL/axi_slice/axi_ar_buffer.sv
 vlog -sv -work work -quiet ../RTL/axi_slice/axi_aw_buffer.sv
 vlog -sv -work work -quiet ../RTL/axi_slice/axi_w_buffer.sv
 vlog -sv -work work -quiet ../RTL/axi_slice/axi_b_buffer.sv
 vlog -sv -work work -quiet ../RTL/axi_slice/axi_buffer.sv


 vlog -sv -work work -quiet ../RTL/common_cells/src/fifo_v3.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/fifo_v2.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/deprecated/generic_fifo.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/lfsr_8bit.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/onehot_to_bin.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/cf_math_pkg.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/lzc.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/rr_arb_tree.sv
 vlog -sv -work work -quiet ../RTL/common_cells/src/spill_register.sv

 vlog -sv -work work -quiet ../RTL/tech_cells_generic/src/deprecated/cluster_clk_cells.sv
 vlog -sv -work work -quiet ../RTL/tech_cells_generic/src/rtl/tc_clk.sv

 vlog -sv -work work -quiet ../RTL/icache-intc/DistributedArbitrationNetwork_Req_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/DistributedArbitrationNetwork_Resp_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/Req_Arb_Node_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/Resp_Arb_Node_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/RoutingBlock_Req_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/RoutingBlock_2ch_Req_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/RoutingBlock_Resp_icache_intc.sv
 vlog -sv -work work -quiet ../RTL/icache-intc/lint_mux.sv

 vlog -sv -work work -quiet ../RTL/scm/latch_scm/register_file_1r_1w_test_wrap.sv
 vlog -sv -work work -quiet ../RTL/scm/latch_scm/register_file_1r_1w.sv


 # COMPILE TB STUFF
 vlog -sv -work work -quiet  ../TB/axi_mem_if.sv
 vlog -sv -work work -quiet  ../TB/ibus_lint_memory_128.sv
 vlog -sv -work work -quiet  ../TB/l2_generic.sv
 vlog -sv -work work -quiet  ../TB/tgen_128.sv
 vlog -sv -work work -quiet  ../TB/generic_memory_with_grant.sv

 if [ "$BITS" == "32" ]
 then
     vlog -sv -work work -quiet  ../TB/tb.sv  +define+HIERARCHY_ICACHE_32BIT
 else
     vlog -sv -work work -quiet  ../TB/tb.sv
 fi

 vopt +acc tb -o tb_no_opt
 vsim tb_no_opt -do "do wave.do; run 10us; source enable_icache_no_prefetch.tcl; run 1ms; q"


# To enable the ICACHES
# force -freeze sim:/tb/sh_req_disable   8'b00000_0000 0
# force -freeze sim:/tb/sh_req_enable    8'b11111_1111 0
# force -freeze sim:/tb/pri_bypass_req   8'b00000_0000 0
# force -freeze sim:/tb/enable_l1_l15_prefetch   8'b11111_1111 0
# force -freeze sim:/tb/special_core_icache      1'b0 0
# run 1ms
