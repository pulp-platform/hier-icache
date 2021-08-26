////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//                                                                            //
// Company:        Micrel Lab @ DEIS - University of Bologna                  //
//                    Viale Risorgimento 2 40136                              //
//                    Bologna - fax 0512093785 -                              //
//                                                                            //
// Engineer:       Igor Loi - igor.loi@unibo.it                               //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    20/10/2019                                                 //
// Design Name:    ICACHE EXPL                                                //
// Module Name:    icache_hier_top                                            //
// Project Name:   PULP                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This block represents the top module for the shared cache  //
//                 It instanciates the master cache controller, the TAG/DATA  //
//                 array and the HW prefetcher.                               //
//                                                                            //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - 23/01/2018 : File Created                                  //
// Additional Comments:                                                       //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
`include "pulp_soc_defines.sv"

module icache_hier_top
#(
  parameter FETCH_ADDR_WIDTH     = 32,
  parameter PRI_FETCH_DATA_WIDTH = 32,
  parameter SH_FETCH_DATA_WIDTH  = 128,

  parameter NB_CORES             = 9,

  parameter SH_NB_BANKS          = 2,
  parameter SH_NB_WAYS           = 4,
  parameter SH_CACHE_SIZE        = 4*1024,  // in Byte
  parameter SH_CACHE_LINE        = 1,       // in word of [SH_FETCH_DATA_WIDTH]

  parameter PRI_NB_WAYS          = 2,
  parameter PRI_CACHE_SIZE       = 512,     // in Byte
  parameter PRI_CACHE_LINE       = 1,       // in word of [PRI_FETCH_DATA_WIDTH]

  parameter AXI_ID               = 6,
  parameter AXI_ADDR             = 32,
  parameter AXI_USER             = 6,
  parameter AXI_DATA             = 64,

  parameter USE_REDUCED_TAG      = "TRUE",  // TRUE | FALSE
  parameter L2_SIZE              = 512*1024 // Size of max(L2 ,ROM) program memory in Byte
)
(
  input logic                                          clk,
  input logic                                          rst_n,
  input logic                                          test_en_i,

  // interface with processors
  input  logic [NB_CORES-1:0]                          fetch_req_i,
  input  logic [NB_CORES-1:0][FETCH_ADDR_WIDTH-1:0]    fetch_addr_i,
  output logic [NB_CORES-1:0]                          fetch_gnt_o,

  output logic [NB_CORES-1:0]                          fetch_rvalid_o,
  output logic [NB_CORES-1:0][PRI_FETCH_DATA_WIDTH-1:0]fetch_rdata_o,



  //AXI read address bus -------------------------------------------
  output  logic [AXI_ID-1:0]                           axi_master_arid_o,
  output  logic [AXI_ADDR-1:0]                         axi_master_araddr_o,
  output  logic [ 7:0]                                 axi_master_arlen_o,    //burst length - 1 to 16
  output  logic [ 2:0]                                 axi_master_arsize_o,   //size of each transfer in burst
  output  logic [ 1:0]                                 axi_master_arburst_o,  //for bursts>1, accept only incr burst=01
  output  logic                                        axi_master_arlock_o,   //only normal access supported axs_awlock=00
  output  logic [ 3:0]                                 axi_master_arcache_o,
  output  logic [ 2:0]                                 axi_master_arprot_o,
  output  logic [ 3:0]                                 axi_master_arregion_o, //
  output  logic [ AXI_USER-1:0]                        axi_master_aruser_o,   //
  output  logic [ 3:0]                                 axi_master_arqos_o,    //
  output  logic                                        axi_master_arvalid_o,  //master addr valid
  input logic                                          axi_master_arready_i,  //slave ready to accept
  // --------------------------------------------------------------


  //AXI BACKWARD read data bus ---------------------------------------------
  input   logic [AXI_ID-1:0]                           axi_master_rid_i,
  input   logic [AXI_DATA-1:0]                         axi_master_rdata_i,
  input   logic [1:0]                                  axi_master_rresp_i,
  input   logic                                        axi_master_rlast_i,    //last transfer in burst
  input   logic [AXI_USER-1:0]                         axi_master_ruser_i,
  input   logic                                        axi_master_rvalid_i,   //slave data valid
  output  logic                                        axi_master_rready_o,    //master ready to accept

  // NOT USED ----------------------------------------------
  output logic [AXI_ID-1:0]                            axi_master_awid_o,
  output logic [AXI_ADDR-1:0]                          axi_master_awaddr_o,
  output logic [ 7:0]                                  axi_master_awlen_o,
  output logic [ 2:0]                                  axi_master_awsize_o,
  output logic [ 1:0]                                  axi_master_awburst_o,
  output logic                                         axi_master_awlock_o,
  output logic [ 3:0]                                  axi_master_awcache_o,
  output logic [ 2:0]                                  axi_master_awprot_o,
  output logic [ 3:0]                                  axi_master_awregion_o,
  output logic [ AXI_USER-1:0]                         axi_master_awuser_o,
  output logic [ 3:0]                                  axi_master_awqos_o,
  output logic                                         axi_master_awvalid_o,
  input  logic                                         axi_master_awready_i,

  // NOT USED ----------------------------------------------
  output logic  [AXI_DATA-1:0]                         axi_master_wdata_o,
  output logic  [AXI_DATA/8-1:0]                       axi_master_wstrb_o,
  output logic                                         axi_master_wlast_o,
  output logic  [ AXI_USER-1:0]                        axi_master_wuser_o,
  output logic                                         axi_master_wvalid_o,
  input  logic                                         axi_master_wready_i,
  // ---------------------------------------------------------------

  // NOT USED ----------------------------------------------
  input  logic  [AXI_ID-1:0]                           axi_master_bid_i,
  input  logic  [ 1:0]                                 axi_master_bresp_i,
  input  logic  [ AXI_USER-1:0]                        axi_master_buser_i,
  input  logic                                         axi_master_bvalid_i,
  output logic                                         axi_master_bready_o,
  // ---------------------------------------------------------------

  input  logic [NB_CORES-1:0]                          enable_l1_l15_prefetch_i,

  SP_ICACHE_CTRL_UNIT_BUS.Slave                        IC_ctrl_unit_bus_main[SH_NB_BANKS],
  PRI_ICACHE_CTRL_UNIT_BUS.Slave                       IC_ctrl_unit_bus_pri[NB_CORES]
);

  // signals from PRI cache and interconnect
  logic [NB_CORES-1:0]                          refill_req_int;
  logic [NB_CORES-1:0]                          refill_gnt_int;
  logic [NB_CORES-1:0][   FETCH_ADDR_WIDTH-1:0] refill_addr_int;
  logic [NB_CORES-1:0]                          refill_r_valid_int;
  logic [NB_CORES-1:0][SH_FETCH_DATA_WIDTH-1:0] refill_r_data_int;

  // signal from icache-int to main icache
  logic [SH_NB_BANKS-1:0]                          fetch_req_to_main_cache;
  logic [SH_NB_BANKS-1:0][   FETCH_ADDR_WIDTH-1:0] fetch_addr_to_main_cache;
  logic [SH_NB_BANKS-1:0][           NB_CORES-1:0] fetch_ID_to_main_cache;
  logic [SH_NB_BANKS-1:0]                          fetch_gnt_from_main_cache;
  logic [SH_NB_BANKS-1:0][SH_FETCH_DATA_WIDTH-1:0] fetch_rdata_from_main_cache;
  logic [SH_NB_BANKS-1:0]                          fetch_rvalid_from_to_main_cache;
  logic [SH_NB_BANKS-1:0][           NB_CORES-1:0] fetch_rID_from_main_cache;

  // signal from icache-sh banks to axi node
  localparam AXI_ID_INT  = 1;
  localparam AXI_ID_OUT  = $clog2(SH_NB_BANKS) + AXI_ID_INT;
  localparam ADDR_OFFSET = $clog2(SH_FETCH_DATA_WIDTH)-3;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR   ),
    .AXI_DATA_WIDTH ( AXI_DATA   ),
    .AXI_ID_WIDTH   ( AXI_ID_INT ),
    .AXI_USER_WIDTH ( AXI_USER   )
  ) axi_master_int_intf [SH_NB_BANKS-1:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR   ),
    .AXI_DATA_WIDTH ( AXI_DATA   ),
    .AXI_ID_WIDTH   ( AXI_ID_OUT ),
    .AXI_USER_WIDTH ( AXI_USER   )
  ) axi_out_intf ();

  logic [NB_CORES-1:0][31:0] congestion_counter;

`ifdef FEATURE_ICACHE_STAT

  case (SH_NB_BANKS)
    1: begin
      for(genvar i=0;i<NB_CORES;i++) begin : STAT_CONGESTION_COUNT_SINGLE_BANK
        always_ff @(posedge clk, negedge rst_n) begin
          if(~rst_n) begin
            congestion_counter[i] <= '0;
          end else begin
            if( IC_ctrl_unit_bus_pri[i].ctrl_clear_regs ) begin
              congestion_counter[i] <= '0;
            end else begin
              if( IC_ctrl_unit_bus_pri[i].ctrl_enable_regs ) begin
                if( refill_req_int[i] & ~refill_gnt_int[i] & fetch_gnt_from_main_cache[0] )
                  congestion_counter[i] <= congestion_counter[i] + 1'b1;
              end
            end
          end
        end
      end
    end

    default : begin
      for(genvar i=0;i<NB_CORES;i++) begin : STAT_CONGESTION_COUNT_MULTI_BANK
        always_ff @(posedge clk, negedge rst_n) begin
          if(~rst_n) begin
            congestion_counter[i] <= '0;
          end else begin
            if( IC_ctrl_unit_bus_pri[i].ctrl_clear_regs ) begin
              congestion_counter[i] <= '0;
            end else begin
              if( IC_ctrl_unit_bus_pri[i].ctrl_enable_regs ) begin
                if( refill_req_int[i] & ~refill_gnt_int[i] & fetch_gnt_from_main_cache[ refill_addr_int[i][ADDR_OFFSET+$clog2(SH_NB_BANKS)-1:ADDR_OFFSET] ]   )
                  congestion_counter[i] <= congestion_counter[i] + 1'b1;
              end
            end
          end
        end
      end
    end

  endcase
`endif

  ////////////////////////////////////////////////////////////////////////////////////
  // ██████╗ ██████╗ ██╗        ██╗ ██████╗ █████╗  ██████╗██╗  ██╗███████╗███████╗ //
  // ██╔══██╗██╔══██╗██║        ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝██╔════╝ //
  // ██████╔╝██████╔╝██║        ██║██║     ███████║██║     ███████║█████╗  ███████╗ //
  // ██╔═══╝ ██╔══██╗██║        ██║██║     ██╔══██║██║     ██╔══██║██╔══╝  ╚════██║ //
  // ██║     ██║  ██║██║███████╗██║╚██████╗██║  ██║╚██████╗██║  ██║███████╗███████║ //
  // ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ //
  ////////////////////////////////////////////////////////////////////////////////////
  for(genvar i=0; i<NB_CORES; i++) begin : PRI_ICACHE

    assign IC_ctrl_unit_bus_pri[i].ctrl_cong_count = congestion_counter[i];

    pri_icache #(
      .FETCH_ADDR_WIDTH (FETCH_ADDR_WIDTH    ), //= 32,       // Size of the fetch address
      .FETCH_DATA_WIDTH (PRI_FETCH_DATA_WIDTH), //= 128,      // Size of the fetch data
      .REFILL_DATA_WIDTH(SH_FETCH_DATA_WIDTH ), //= 128,      // Size of the fetch data
      
      .NB_WAYS          (PRI_NB_WAYS         ), //= 4,        // Cache associativity
      .CACHE_SIZE       (PRI_CACHE_SIZE      ), //= 512      // Ccache capacity in Byte
      .CACHE_LINE       (PRI_CACHE_LINE      ), //= 1,        // in word of [PRI_FETCH_DATA_WIDTH]
      
      .USE_REDUCED_TAG  (USE_REDUCED_TAG     ), //= "TRUE",   // TRUE | FALSE
      .L2_SIZE          (L2_SIZE             )  //= 512*1024  // Size of max(L2 ,ROM) program memory in Byte
    ) i_pri_icache (
      .clk                     (clk                                     ),
      .rst_n                   (rst_n                                   ),
      .test_en_i               (test_en_i                               ),
      
      .fetch_req_i             (fetch_req_i[i]                          ),
      .fetch_addr_i            (fetch_addr_i[i]                         ),
      .fetch_gnt_o             (fetch_gnt_o[i]                          ),
      .fetch_rvalid_o          (fetch_rvalid_o[i]                       ),
      .fetch_rdata_o           (fetch_rdata_o[i]                        ),
      
      .refill_req_o            (refill_req_int[i]                       ),
      .refill_gnt_i            (refill_gnt_int[i]                       ),
      .refill_addr_o           (refill_addr_int[i]                      ),
      .refill_r_valid_i        (refill_r_valid_int[i]                   ),
      .refill_r_data_i         (refill_r_data_int[i]                    ),
      
      .enable_l1_l15_prefetch_i(enable_l1_l15_prefetch_i[i]             ),
      
      .bypass_icache_i         (IC_ctrl_unit_bus_pri[i].bypass_req      ),
      .cache_is_bypassed_o     (IC_ctrl_unit_bus_pri[i].bypass_ack      ),
      .flush_icache_i          (IC_ctrl_unit_bus_pri[i].flush_req       ),
      .cache_is_flushed_o      (IC_ctrl_unit_bus_pri[i].flush_ack       ),
      .flush_set_ID_req_i      (IC_ctrl_unit_bus_pri[i].sel_flush_req   ),
      .flush_set_ID_addr_i     (IC_ctrl_unit_bus_pri[i].sel_flush_addr  ),
      .flush_set_ID_ack_o      (IC_ctrl_unit_bus_pri[i].sel_flush_ack   )
      
`ifdef FEATURE_ICACHE_STAT
      ,
      .bank_hit_count_o        (IC_ctrl_unit_bus_pri[i].ctrl_hit_count  ),
      .bank_trans_count_o      (IC_ctrl_unit_bus_pri[i].ctrl_trans_count),
      .bank_miss_count_o       (IC_ctrl_unit_bus_pri[i].ctrl_miss_count ),
      
      .ctrl_clear_regs_i       (IC_ctrl_unit_bus_pri[i].ctrl_clear_regs ),
      .ctrl_enable_regs_i      (IC_ctrl_unit_bus_pri[i].ctrl_enable_regs)
`endif
    );
  end


  ////////////////////////////////////////////////////////////////////////////////////
  // ██╗ ██████╗ █████╗  ██████╗██╗  ██╗███████╗    ██╗███╗   ██╗████████╗ ██████╗  //
  // ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝    ██║████╗  ██║╚══██╔══╝██╔════╝  //
  // ██║██║     ███████║██║     ███████║█████╗      ██║██╔██╗ ██║   ██║   ██║       //
  // ██║██║     ██╔══██║██║     ██╔══██║██╔══╝      ██║██║╚██╗██║   ██║   ██║       //
  // ██║╚██████╗██║  ██║╚██████╗██║  ██║███████╗    ██║██║ ╚████║   ██║   ╚██████╗  //
  // ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝    ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝  //
  ////////////////////////////////////////////////////////////////////////////////////
  // -----------------------------------------------------------------------------------------
  // Read Only INTERCONNECT   MULTIPLEX different request from cores (not the HW PF)  --------
  // SHARED_ICACHE_INTERCONNECT                                                       --------
  // -----------------------------------------------------------------------------------------

  // Eg 9 COres: --> NCH_0 = 8, NCH_1= 1;
  localparam N_CH0 = (2**$clog2( NB_CORES ) == NB_CORES) ? NB_CORES : 2**($clog2( NB_CORES)-1);
  localparam N_CH1 = (2**$clog2( NB_CORES ) == NB_CORES) ? 0       : NB_CORES - 2**($clog2( NB_CORES)-1);

  icache_intc #(
    .ADDRESS_WIDTH(FETCH_ADDR_WIDTH   ),
    .N_CORES      (N_CH0              ),
    .N_AUX_CHANNEL(N_CH1              ),
    .UID_WIDTH    (NB_CORES           ),
    .DATA_WIDTH   (SH_FETCH_DATA_WIDTH),
    .N_CACHE_BANKS(SH_NB_BANKS        )  // Single L1.5 cache
  ) ICACHE_INTERCONNECT (
    .clk_i         (clk                            ),
    .rst_ni        (rst_n                          ),
    
    .request_i     (refill_req_int                 ), // Data request
    .address_i     (refill_addr_int                ), // Data request Address
    .grant_o       (refill_gnt_int                 ), //
    .response_o    (refill_r_valid_int             ), // Data Response Valid (For LOAD/STORE commands)
    .read_data_o   (refill_r_data_int              ), // Data Response DATA (For LOAD commands)
    
    .request_o     (fetch_req_to_main_cache        ), // Data request
    .address_o     (fetch_addr_to_main_cache       ), // Data request Address
    .UID_o         (fetch_ID_to_main_cache         ), // Data request Address
    .grant_i       (fetch_gnt_from_main_cache      ), // Data Grant
    .read_data_i   (fetch_rdata_from_main_cache    ), // valid REspone (must be accepted always)
    .response_i    (fetch_rvalid_from_to_main_cache), // Data Response ID (For LOAD commands)
    .response_UID_i(fetch_rID_from_main_cache      )  // Data Response DATA (For LOAD and STORE)
  );






  /////////////////////////////////////////////////////////////////////////////////////////
  // ███╗   ███╗ █████╗ ██╗███╗   ██╗        ██╗ ██████╗ █████╗  ██████╗██╗  ██╗███████╗ //
  // ████╗ ████║██╔══██╗██║████╗  ██║        ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝ //
  // ██╔████╔██║███████║██║██╔██╗ ██║        ██║██║     ███████║██║     ███████║█████╗   //
  // ██║╚██╔╝██║██╔══██║██║██║╚██╗██║        ██║██║     ██╔══██║██║     ██╔══██║██╔══╝   //
  // ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║███████╗██║╚██████╗██║  ██║╚██████╗██║  ██║███████╗ //
  // ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝ //
  /////////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<  SH_NB_BANKS; i++) begin : Main_Icache
    share_icache #(
      .N_BANKS                ( SH_NB_BANKS                    ),
      .SET_ASSOCIATIVE        ( SH_NB_WAYS                     ),
      .CACHE_LINE             ( SH_CACHE_LINE                  ),
      .CACHE_SIZE             ( SH_CACHE_SIZE/SH_NB_BANKS      ),  //In Byte
      .CACHE_ID               ( i                              ),
      .FIFO_DEPTH             ( 4                              ),

      .ICACHE_DATA_WIDTH      ( SH_FETCH_DATA_WIDTH            ),
      .ICACHE_ID_WIDTH        ( NB_CORES                       ),
      .ICACHE_ADDR_WIDTH      ( FETCH_ADDR_WIDTH               ),

      .DIRECT_MAPPED_FEATURE  ( "DISABLED"                     ),

      .AXI_ID                 ( AXI_ID_INT                     ),
      .AXI_ADDR               ( AXI_ADDR                       ),
      .AXI_DATA               ( AXI_DATA                       ),
      .AXI_USER               ( AXI_USER                       ),

      .USE_REDUCED_TAG        ( USE_REDUCED_TAG                ),
      .L2_SIZE                ( L2_SIZE                        )
    ) i_main_shared_icache (
      // ---------------------------------------------------------------
      // I/O Port Declarations -----------------------------------------
      // ---------------------------------------------------------------
      .clk                           ( clk                        ),
      .rst_n                         ( rst_n                      ),
      .test_en_i                     ( test_en_i                  ),

      // ---------------------------------------------------------------
      // SHARED_ICACHE_INTERCONNECT Port Declarations -----------------------------------------
      // -----------------           ----------------------------------------------
      .fetch_req_i                   (  fetch_req_to_main_cache[i]         ),
      .fetch_grant_o                 (  fetch_gnt_from_main_cache[i]       ),
      .fetch_addr_i                  (  fetch_addr_to_main_cache[i]        ),
      .fetch_ID_i                    (  fetch_ID_to_main_cache[i]          ),
      .fetch_r_rdata_o               (  fetch_rdata_from_main_cache[i]     ),
      .fetch_r_valid_o               (  fetch_rvalid_from_to_main_cache[i] ),
      .fetch_r_ID_o                  (  fetch_rID_from_main_cache[i]       ),

      // §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ //
      // §§§§§§§§§§§§§§§§§§§    REFILL Request side  §§§§§§§§§§§§§§§§§§§§§§§ //
      // §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§ //
      .init_awid_o                   ( axi_master_int_intf[i].aw_id     ),
      .init_awaddr_o                 ( axi_master_int_intf[i].aw_addr   ),
      .init_awlen_o                  ( axi_master_int_intf[i].aw_len    ),
      .init_awsize_o                 ( axi_master_int_intf[i].aw_size   ),
      .init_awburst_o                ( axi_master_int_intf[i].aw_burst  ),
      .init_awlock_o                 ( axi_master_int_intf[i].aw_lock   ),
      .init_awcache_o                ( axi_master_int_intf[i].aw_cache  ),
      .init_awprot_o                 ( axi_master_int_intf[i].aw_prot   ),
      .init_awregion_o               ( axi_master_int_intf[i].aw_region ),
      .init_awuser_o                 ( axi_master_int_intf[i].aw_user   ),
      .init_awqos_o                  ( axi_master_int_intf[i].aw_qos    ),
      .init_awvalid_o                ( axi_master_int_intf[i].aw_valid  ),
      .init_awready_i                ( axi_master_int_intf[i].aw_ready  ),

      .init_wdata_o                  ( axi_master_int_intf[i].w_data    ),
      .init_wstrb_o                  ( axi_master_int_intf[i].w_strb    ),
      .init_wlast_o                  ( axi_master_int_intf[i].w_last    ),
      .init_wuser_o                  ( axi_master_int_intf[i].w_user    ),
      .init_wvalid_o                 ( axi_master_int_intf[i].w_valid   ),
      .init_wready_i                 ( axi_master_int_intf[i].w_ready   ),

      .init_bid_i                    ( axi_master_int_intf[i].b_id      ),
      .init_bresp_i                  ( axi_master_int_intf[i].b_resp    ),
      .init_buser_i                  ( axi_master_int_intf[i].b_user    ),
      .init_bvalid_i                 ( axi_master_int_intf[i].b_valid   ),
      .init_bready_o                 ( axi_master_int_intf[i].b_ready   ),

      .init_arid_o                   ( axi_master_int_intf[i].ar_id     ),
      .init_araddr_o                 ( axi_master_int_intf[i].ar_addr   ),
      .init_arlen_o                  ( axi_master_int_intf[i].ar_len    ),
      .init_arsize_o                 ( axi_master_int_intf[i].ar_size   ),
      .init_arburst_o                ( axi_master_int_intf[i].ar_burst  ),
      .init_arlock_o                 ( axi_master_int_intf[i].ar_lock   ),
      .init_arcache_o                ( axi_master_int_intf[i].ar_cache  ),
      .init_arprot_o                 ( axi_master_int_intf[i].ar_prot   ),
      .init_arregion_o               ( axi_master_int_intf[i].ar_region ),
      .init_aruser_o                 ( axi_master_int_intf[i].ar_user   ),
      .init_arqos_o                  ( axi_master_int_intf[i].ar_qos    ),
      .init_arvalid_o                ( axi_master_int_intf[i].ar_valid  ),
      .init_arready_i                ( axi_master_int_intf[i].ar_ready  ),

      .init_rid_i                    ( axi_master_int_intf[i].r_id       ),
      .init_rdata_i                  ( axi_master_int_intf[i].r_data     ),
      .init_rresp_i                  ( axi_master_int_intf[i].r_resp     ),
      .init_rlast_i                  ( axi_master_int_intf[i].r_last     ),
      .init_ruser_i                  ( axi_master_int_intf[i].r_user     ),
      .init_rvalid_i                 ( axi_master_int_intf[i].r_valid    ),
      .init_rready_o                 ( axi_master_int_intf[i].r_ready    ),

      // Control ports
      .ctrl_req_enable_icache_i      ( IC_ctrl_unit_bus_main[i].ctrl_req_enable      ),
      .ctrl_ack_enable_icache_o      ( IC_ctrl_unit_bus_main[i].ctrl_ack_enable      ),
      .ctrl_req_disable_icache_i     ( IC_ctrl_unit_bus_main[i].ctrl_req_disable     ),
      .ctrl_ack_disable_icache_o     ( IC_ctrl_unit_bus_main[i].ctrl_ack_disable     ),
      .ctrl_req_flush_icache_i       ( IC_ctrl_unit_bus_main[i].ctrl_flush_req       ),
      .ctrl_ack_flush_icache_o       ( IC_ctrl_unit_bus_main[i].ctrl_flush_ack       ),
      .ctrl_pending_trans_icache_o   ( IC_ctrl_unit_bus_main[i].ctrl_pending_trans   ),
      .ctrl_sel_flush_req_i          ( IC_ctrl_unit_bus_main[i].sel_flush_req        ),
      .ctrl_sel_flush_addr_i         ( IC_ctrl_unit_bus_main[i].sel_flush_addr       ),
      .ctrl_sel_flush_ack_o          ( IC_ctrl_unit_bus_main[i].sel_flush_ack        )
`ifdef FEATURE_ICACHE_STAT
      ,
      .ctrl_hit_count_icache_o       ( IC_ctrl_unit_bus_main[i].ctrl_hit_count    ),
      .ctrl_trans_count_icache_o     ( IC_ctrl_unit_bus_main[i].ctrl_trans_count  ),
      .ctrl_miss_count_icache_o      ( IC_ctrl_unit_bus_main[i].ctrl_miss_count   ),
      .ctrl_clear_regs_icache_i      ( IC_ctrl_unit_bus_main[i].ctrl_clear_regs   ),
      .ctrl_enable_regs_icache_i     ( IC_ctrl_unit_bus_main[i].ctrl_enable_regs   )
`endif
    );
  end




  

  /////////////////////////////////////////////////////////////////
  //  █████╗ ██╗  ██╗██╗    ███╗   ██╗ ██████╗ ██████╗ ███████╗  //
  // ██╔══██╗╚██╗██╔╝██║    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝  //
  // ███████║ ╚███╔╝ ██║    ██╔██╗ ██║██║   ██║██║  ██║█████╗    //
  // ██╔══██║ ██╔██╗ ██║    ██║╚██╗██║██║   ██║██║  ██║██╔══╝    //
  // ██║  ██║██╔╝ ██╗██║    ██║ ╚████║╚██████╔╝██████╔╝███████╗  //
  // ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝  //
  /////////////////////////////////////////////////////////////////
  

  assign axi_master_awid_o     = axi_out_intf.aw_id;
  assign axi_master_awaddr_o   = axi_out_intf.aw_addr;
  assign axi_master_awlen_o    = axi_out_intf.aw_len;
  assign axi_master_awsize_o   = axi_out_intf.aw_size;
  assign axi_master_awburst_o  = axi_out_intf.aw_burst;
  assign axi_master_awlock_o   = axi_out_intf.aw_lock;
  assign axi_master_awcache_o  = axi_out_intf.aw_cache;
  assign axi_master_awprot_o   = axi_out_intf.aw_prot;
  assign axi_master_awregion_o = axi_out_intf.aw_region;
  assign axi_master_awuser_o   = axi_out_intf.aw_user;
  assign axi_master_awqos_o    = axi_out_intf.aw_qos;
  assign axi_master_awvalid_o  = axi_out_intf.aw_valid;
  assign axi_out_intf.aw_ready = axi_master_awready_i;

  assign axi_master_wdata_o  = axi_out_intf.w_data;
  assign axi_master_wstrb_o  = axi_out_intf.w_strb;
  assign axi_master_wlast_o  = axi_out_intf.w_last;
  assign axi_master_wuser_o  = axi_out_intf.w_user;
  assign axi_master_wvalid_o = axi_out_intf.w_valid;
  assign axi_out_intf.w_ready    = axi_master_wready_i;

  assign axi_out_intf.b_id    = axi_master_bid_i;
  assign axi_out_intf.b_resp  = axi_master_bresp_i;
  assign axi_out_intf.b_user  = axi_master_buser_i;
  assign axi_out_intf.b_valid = axi_master_bvalid_i;
  assign axi_master_bready_o  = axi_out_intf.b_ready;

  assign axi_master_arid_o     = axi_out_intf.ar_id;
  assign axi_master_araddr_o   = axi_out_intf.ar_addr;
  assign axi_master_arlen_o    = axi_out_intf.ar_len;
  assign axi_master_arsize_o   = axi_out_intf.ar_size;
  assign axi_master_arburst_o  = axi_out_intf.ar_burst;
  assign axi_master_arlock_o   = axi_out_intf.ar_lock;
  assign axi_master_arcache_o  = axi_out_intf.ar_cache;
  assign axi_master_arprot_o   = axi_out_intf.ar_prot;
  assign axi_master_arregion_o = axi_out_intf.ar_region;
  assign axi_master_aruser_o   = axi_out_intf.ar_user;
  assign axi_master_arqos_o    = axi_out_intf.ar_qos;
  assign axi_master_arvalid_o  = axi_out_intf.ar_valid;
  assign axi_out_intf.ar_ready = axi_master_arready_i;

  assign axi_out_intf.r_id    = axi_master_rid_i;
  assign axi_out_intf.r_data  = axi_master_rdata_i;
  assign axi_out_intf.r_resp  = axi_master_rresp_i;
  assign axi_out_intf.r_last  = axi_master_rlast_i;
  assign axi_out_intf.r_user  = axi_master_ruser_i;
  assign axi_out_intf.r_valid = axi_master_rvalid_i;
  assign axi_master_rready_o  = axi_out_intf.r_ready;

  axi_mux_intf #(
    .SLV_AXI_ID_WIDTH( AXI_ID_INT  ),
    .MST_AXI_ID_WIDTH( AXI_ID_OUT  ),
    .AXI_ADDR_WIDTH  ( AXI_ADDR    ),
    .AXI_DATA_WIDTH  ( AXI_DATA    ),
    .AXI_USER_WIDTH  ( AXI_USER    ),
    .NO_SLV_PORTS    ( SH_NB_BANKS ),
    .MAX_W_TRANS     ( 32'd1       ), // no writes through this interface
    .FALL_THROUGH    ( 1'b0        ),
    .SPILL_AW        ( 1'b0        ),
    .SPILL_W         ( 1'b0        ),
    .SPILL_B         ( 1'b0        ),
    .SPILL_AR        ( 1'b0        ),
    .SPILL_R         ( 1'b0        )
  ) i_axi_mux (
    .clk_i ( clk                 ),
    .rst_ni( rst_n               ),
    .test_i( test_en_i           ),
    .slv   ( axi_master_int_intf ),
    .mst   ( axi_out_intf        )
  );

endmodule // icache_hier_top
