 analyze -format sverilog ../RTL/TOP/icache_hier_top.sv

 analyze -format sverilog ../RTL/L1_CACHE/pri_icache_controller.sv
 analyze -format sverilog ../RTL/L1_CACHE/pri_icache.sv
 
 analyze -format sverilog ../RTL/L1.5_CACHE/AXI4_REFILL_Resp_Deserializer.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/share_icache.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/RefillTracker.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/icache_controller.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/LFSR_L2_Way_Repl.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/RefillTracker_4.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/REP_buffer_4.sv
 analyze -format sverilog ../RTL/L1.5_CACHE/ram_ws_rs_data_scm.sv 
 analyze -format sverilog ../RTL/L1.5_CACHE/ram_ws_rs_tag_scm.sv 




 # COMPILE RTL from other Repositories
 analyze -format sverilog ../RTL/axi_node/axi_address_decoder_AR.sv
 analyze -format sverilog ../RTL/axi_node/axi_address_decoder_AW.sv
 analyze -format sverilog ../RTL/axi_node/axi_address_decoder_BR.sv
 analyze -format sverilog ../RTL/axi_node/axi_address_decoder_BW.sv
 analyze -format sverilog ../RTL/axi_node/axi_address_decoder_DW.sv
 analyze -format sverilog ../RTL/axi_node/axi_ArbitrationTree.sv
 analyze -format sverilog ../RTL/axi_node/axi_AR_allocator.sv
 analyze -format sverilog ../RTL/axi_node/axi_AW_allocator.sv
 analyze -format sverilog ../RTL/axi_node/axi_BR_allocator.sv
 analyze -format sverilog ../RTL/axi_node/axi_BW_allocator.sv
 analyze -format sverilog ../RTL/axi_node/axi_DW_allocator.sv
 analyze -format sverilog ../RTL/axi_node/axi_FanInPrimitive_Req.sv
 analyze -format sverilog ../RTL/axi_node/axi_multiplexer.sv
 analyze -format sverilog ../RTL/axi_node/axi_regs_top.sv
 analyze -format sverilog ../RTL/axi_node/axi_node_wrap_with_slices.sv
 analyze -format sverilog ../RTL/axi_node/axi_node_wrap.sv
 analyze -format sverilog ../RTL/axi_node/axi_node.sv
 analyze -format sverilog ../RTL/axi_node/axi_request_block.sv
 analyze -format sverilog ../RTL/axi_node/axi_response_block.sv
 analyze -format sverilog ../RTL/axi_node/axi_RR_Flag_Req.sv

 analyze -format sverilog  ../RTL/axi_slice/axi_r_buffer.sv
 analyze -format sverilog  ../RTL/axi_slice/axi_ar_buffer.sv
 analyze -format sverilog  ../RTL/axi_slice/axi_aw_buffer.sv
 analyze -format sverilog  ../RTL/axi_slice/axi_w_buffer.sv
 analyze -format sverilog  ../RTL/axi_slice/axi_b_buffer.sv
 analyze -format sverilog  ../RTL/axi_slice/axi_buffer.sv

 analyze -format sverilog  ../RTL/common_cells/generic_fifo.sv
 analyze -format sverilog  ../RTL/common_cells/generic_LFSR_8bit.sv
 analyze -format sverilog  ../RTL/common_cells/onehot_to_bin.sv
 analyze -format sverilog  ../RTL/tech_cells_generic/cluster_clock_gating.sv

 analyze -format sverilog  ../RTL/icache-intc/DistributedArbitrationNetwork_Req_icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/DistributedArbitrationNetwork_Resp_icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/Req_Arb_Node_icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/Resp_Arb_Node_icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/RoutingBlock_Req_icache_intc.sv
 analyze -format sverilog  ../RTL/icache-intc/RoutingBlock_Resp_icache_intc.sv
 
 analyze -format sverilog  ../RTL/scm/generic_scm/register_file_1r_1w.sv
