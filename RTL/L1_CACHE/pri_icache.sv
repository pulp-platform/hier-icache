// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.




////////////////////////////////////////////////////////////////////////////////
// Company:        Multitherman Laboratory @ DEIS - University of Bologna     //
//                    Viale Risorgimento 2 40136                              //
//                    Bologna - fax 0512093785 -                              //
//                                                                            //
// Engineer:       Igor Loi - igor.loi@unibo.it                               //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
// Create Date:    22/03/2016                                                 //
// Design Name:    ULPSoC                                                     //
// Module Name:    pri_icache                                                 //
// Project Name:   icache_expl                                                //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Top module for the private program cache, which istanciates//
//                 the cache controller and SCM banks.                        //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`define USE_REQ_BUFF
`include "pulp_soc_defines.sv"

module pri_icache
#(
   parameter FETCH_ADDR_WIDTH = 32,       // Size of the fetch address
   parameter FETCH_DATA_WIDTH = 32,      // Size of the fetch data
   parameter REFILL_DATA_WIDTH = 128,      // Size of the fetch data

   parameter NB_WAYS          = 4,        // Cache associativity
   parameter CACHE_SIZE       = 4096,     // Ccache capacity in Byte
   parameter CACHE_LINE       = 1,        // in word of [FETCH_DATA_WIDTH]

   parameter USE_REDUCED_TAG  = "TRUE",   // TRUE | FALSE
   parameter L2_SIZE          = 512*1024  // Size of max(L2 ,ROM) program memory in Byte
)
(
   input logic                            clk,
   input logic                            rst_n,
   input logic                            test_en_i,

   // interface with processor
   input  logic                           fetch_req_i,
   input  logic [FETCH_ADDR_WIDTH-1:0]    fetch_addr_i,
   output logic                           fetch_gnt_o,
   output logic                           fetch_rvalid_o,
   output logic [FETCH_DATA_WIDTH-1:0]    fetch_rdata_o,

   output logic                           refill_req_o,
   input  logic                           refill_gnt_i,
   output logic [31:0]                    refill_addr_o,
   input  logic                           refill_r_valid_i,
   input  logic [REFILL_DATA_WIDTH-1:0]   refill_r_data_i,

   input  logic                           enable_l1_l15_prefetch_i,

   input  logic                           bypass_icache_i,
   output logic                           cache_is_bypassed_o,
   input  logic                           flush_icache_i,
   output logic                           cache_is_flushed_o,
   input  logic                           flush_set_ID_req_i,
   input  logic [FETCH_ADDR_WIDTH-1:0]    flush_set_ID_addr_i,
   output logic                           flush_set_ID_ack_o

`ifdef FEATURE_ICACHE_STAT
    ,
    output logic [31:0]                   bank_hit_count_o,
    output logic [31:0]                   bank_trans_count_o,
    output logic [31:0]                   bank_miss_count_o,

    input  logic                          ctrl_clear_regs_i,
    input  logic                          ctrl_enable_regs_i
`endif
);

   localparam REDUCE_TAG_WIDTH   = $clog2(L2_SIZE/CACHE_SIZE)+$clog2(NB_WAYS)+1; // add one bit for TAG valid info field

   localparam OFFSET             = $clog2(REFILL_DATA_WIDTH)-3;
   localparam WAY_SIZE           = CACHE_SIZE/NB_WAYS;
   localparam SCM_NUM_ROWS       = WAY_SIZE/(CACHE_LINE*REFILL_DATA_WIDTH/8); // TAG
   localparam SCM_TAG_ADDR_WIDTH = $clog2(SCM_NUM_ROWS);

   localparam TAG_WIDTH          = (USE_REDUCED_TAG == "TRUE") ? REDUCE_TAG_WIDTH : (FETCH_ADDR_WIDTH - SCM_TAG_ADDR_WIDTH - $clog2(CACHE_LINE) - OFFSET + 1);

   localparam DATA_WIDTH          = REFILL_DATA_WIDTH;
   localparam SCM_DATA_ADDR_WIDTH = $clog2(SCM_NUM_ROWS)+$clog2(CACHE_LINE);  // Because of 32 Access

   localparam SET_ID_LSB = $clog2(DATA_WIDTH*CACHE_LINE)-3;
   localparam SET_ID_MSB = SET_ID_LSB + SCM_TAG_ADDR_WIDTH - 1;
   localparam TAG_LSB    = SET_ID_MSB + 1;
   localparam TAG_MSB    = TAG_LSB + TAG_WIDTH - 2 ; //1 bit is count for valid



   // interface with READ PORT --> SCM DATA
   logic [NB_WAYS-1:0]                    DATA_rd_req_int;
   logic [NB_WAYS-1:0]                    DATA_wr_req_int;
   logic [SCM_DATA_ADDR_WIDTH-1:0]        DATA_rd_addr_int;
   logic [SCM_DATA_ADDR_WIDTH-1:0]        DATA_wr_addr_int;
   logic [NB_WAYS-1:0][DATA_WIDTH-1:0]    DATA_rdata_int;
   logic [DATA_WIDTH-1:0]                 DATA_wdata_int;

   // interface with READ PORT --> SCM TAG
   logic [1:0][NB_WAYS-1:0]               TAG_req_int;
   logic                                  TAG_we_int;
   logic [1:0][SCM_TAG_ADDR_WIDTH-1:0]    TAG_addr_int;
   logic [NB_WAYS-1:0][1:0][TAG_WIDTH-1:0]TAG_rdata_int;
   logic [TAG_WIDTH-1:0]                  TAG_wdata_int;

   logic [NB_WAYS-1:0][1:0]               TAG_read_enable;
   logic [NB_WAYS-1:0]                    TAG_write_enable;

   logic [31:0]                           refill_addr_int;
   logic                                  refill_req_int;
   logic                                  refill_gnt_int;
   logic                                  refill_r_valid_int;
   logic [REFILL_DATA_WIDTH-1:0]          refill_r_data_int;

   logic [31:0]                           pre_refill_addr_int;
   logic                                  pre_refill_req_int;
   logic                                  pre_refill_gnt_int;
   logic                                  pre_refill_r_valid_int;
   logic [REFILL_DATA_WIDTH-1:0]          pre_refill_r_data_int;


   //  ██████╗ █████╗  ██████╗██╗  ██╗███████╗         ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗     ██╗     ███████╗██████╗
   // ██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝        ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║     ██║     ██╔════╝██╔══██╗
   // ██║     ███████║██║     ███████║█████╗          ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║     ██║     █████╗  ██████╔╝
   // ██║     ██╔══██║██║     ██╔══██║██╔══╝          ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║     ██║     ██╔══╝  ██╔══██╗
   // ╚██████╗██║  ██║╚██████╗██║  ██║███████╗███████╗╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗███████╗███████╗██║  ██║
   //  ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
   pri_icache_controller
   #(
      .FETCH_ADDR_WIDTH         ( FETCH_ADDR_WIDTH         ),
      .FETCH_DATA_WIDTH         ( FETCH_DATA_WIDTH         ),
      .REFILL_DATA_WIDTH        ( REFILL_DATA_WIDTH        ),

      .NB_CORES                 ( 1                        ),
      .NB_WAYS                  ( NB_WAYS                  ),
      .CACHE_LINE               ( CACHE_LINE               ),

      .SCM_TAG_ADDR_WIDTH       ( SCM_TAG_ADDR_WIDTH       ),
      .SCM_DATA_ADDR_WIDTH      ( SCM_DATA_ADDR_WIDTH      ),
      .SCM_TAG_WIDTH            ( TAG_WIDTH                ),
      .SCM_DATA_WIDTH           ( DATA_WIDTH               ),

      .SET_ID_LSB               ( SET_ID_LSB               ),
      .SET_ID_MSB               ( SET_ID_MSB               ),
      .TAG_LSB                  ( TAG_LSB                  ),
      .TAG_MSB                  ( TAG_MSB                  )
   )
   i_pri_icache_controller
   (
      .clk                      ( clk                      ),
      .rst_n                    ( rst_n                    ),

      .bypass_icache_i          ( bypass_icache_i          ),
      .cache_is_bypassed_o      ( cache_is_bypassed_o      ),
      .flush_icache_i           ( flush_icache_i           ),
      .cache_is_flushed_o       ( cache_is_flushed_o       ),
      .flush_set_ID_req_i       ( flush_set_ID_req_i       ),
      .flush_set_ID_addr_i      ( flush_set_ID_addr_i      ),
      .flush_set_ID_ack_o       ( flush_set_ID_ack_o       ),

`ifdef FEATURE_ICACHE_STAT
      .bank_hit_count_o         ( bank_hit_count_o         ),
      .bank_trans_count_o       ( bank_trans_count_o       ),
      .bank_miss_count_o        ( bank_miss_count_o        ),

      .ctrl_clear_regs_i        ( ctrl_clear_regs_i        ),
      .ctrl_enable_regs_i       ( ctrl_enable_regs_i       ),
`endif

      .enable_l1_l15_prefetch_i ( enable_l1_l15_prefetch_i ),

      // interface with processor
      .fetch_req_i              ( fetch_req_i              ),
      .fetch_addr_i             ( fetch_addr_i             ),
      .fetch_gnt_o              ( fetch_gnt_o              ),
      .fetch_rvalid_o           ( fetch_rvalid_o           ),
      .fetch_rdata_o            ( fetch_rdata_o            ),


      // interface with READ PORT --> SCM DATA
      .DATA_rd_req_o            ( DATA_rd_req_int          ),
      .DATA_wr_req_o            ( DATA_wr_req_int          ),
      .DATA_rd_addr_o           ( DATA_rd_addr_int         ),
      .DATA_wr_addr_o           ( DATA_wr_addr_int         ),
      .DATA_rdata_i             ( DATA_rdata_int           ),
      .DATA_wdata_o             ( DATA_wdata_int           ),

      // interface with READ PORT --> SCM TAG
      .TAG_req_o                ( TAG_req_int              ),
      .TAG_addr_o               ( TAG_addr_int             ),
      .TAG_rdata_i              ( TAG_rdata_int            ),
      .TAG_wdata_o              ( TAG_wdata_int            ),
      .TAG_we_o                 ( TAG_we_int               ),

      // Interface to cache_controller_to Icache L1.5 port
      .pre_refill_req_o         ( pre_refill_req_int       ),
      .pre_refill_gnt_i         ( pre_refill_gnt_int       ),
      .pre_refill_addr_o        ( pre_refill_addr_int      ),
      .pre_refill_r_valid_i     ( pre_refill_r_valid_int   ),
      .pre_refill_r_data_i      ( pre_refill_r_data_int    ),

      .refill_req_o             ( refill_req_int           ),
      .refill_gnt_i             ( refill_gnt_int           ),
      .refill_addr_o            ( refill_addr_int          ),
      .refill_r_valid_i         ( refill_r_valid_int       ),
      .refill_r_data_i          ( refill_r_data_int        )
   );


   genvar i;
   generate

      // ████████╗ █████╗  ██████╗         ███████╗ ██████╗███╗   ███╗
      // ╚══██╔══╝██╔══██╗██╔════╝         ██╔════╝██╔════╝████╗ ████║
      //    ██║   ███████║██║  ███╗        ███████╗██║     ██╔████╔██║
      //    ██║   ██╔══██║██║   ██║        ╚════██║██║     ██║╚██╔╝██║
      //    ██║   ██║  ██║╚██████╔╝███████╗███████║╚██████╗██║ ╚═╝ ██║
      //    ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝ ╚═════╝╚═╝     ╚═╝
      for(i=0; i<NB_WAYS; i++)
      begin : _TAG_WAY_
         assign TAG_read_enable[i][0]  = TAG_req_int[0][i] & ~TAG_we_int;
         assign TAG_read_enable[i][1]  = TAG_req_int[1][i] & ~TAG_we_int;
         assign TAG_write_enable[i] = TAG_req_int[0][i] &  TAG_we_int;


     `ifdef PULP_FPGA_EMUL
         register_file_1w_multi_port_read
      `else
         register_file_1w_multi_port_read_test_wrap
     `endif
         #(
            .ADDR_WIDTH  ( SCM_TAG_ADDR_WIDTH ),
            .DATA_WIDTH  ( TAG_WIDTH          ),
 	    .N_READ      ( 2                  )
         )
         TAG_BANK
         (
            .clk         ( clk          ),
            .rst_n       ( rst_n        ),
            .test_en_i   ( test_en_i    ),
            
            // Read port
            .ReadEnable  ( TAG_read_enable[i]  ),
            .ReadAddr    ( TAG_addr_int        ),
            .ReadData    ( TAG_rdata_int[i]    ),

            // Write port
            .WriteEnable ( TAG_write_enable[i] ),
            .WriteAddr   ( TAG_addr_int[0]     ),
            .WriteData   ( TAG_wdata_int       )
        `ifndef PULP_FPGA_EMUL
            ,
            // BIST ENABLE
            .BIST        ( 1'b0                ), // PLEASE CONNECT ME;

            // BIST ports
            .CSN_T       (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .WEN_T       (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .A_T         (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .D_T         (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .Q_T         (                     )
        `endif
         );
      end

      // ██████╗  █████╗ ████████╗ █████╗         ███████╗ ██████╗███╗   ███╗
      // ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗        ██╔════╝██╔════╝████╗ ████║
      // ██║  ██║███████║   ██║   ███████║        ███████╗██║     ██╔████╔██║
      // ██║  ██║██╔══██║   ██║   ██╔══██║        ╚════██║██║     ██║╚██╔╝██║
      // ██████╔╝██║  ██║   ██║   ██║  ██║███████╗███████║╚██████╗██║ ╚═╝ ██║
      // ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝╚═╝     ╚═╝


      for(i=0; i<NB_WAYS; i++)
      begin : _DATA_WAY_

     `ifdef PULP_FPGA_EMUL
         register_file_1r_1w
     `else
         register_file_1r_1w_test_wrap
     `endif
         #(
            .ADDR_WIDTH  ( SCM_DATA_ADDR_WIDTH ),
            .DATA_WIDTH  ( DATA_WIDTH         )
         )
         DATA_BANK
         (
            .clk         ( clk          ),

            // Read port
            .ReadEnable  ( DATA_rd_req_int[i]    ),
            .ReadAddr    ( DATA_rd_addr_int      ),
            .ReadData    ( DATA_rdata_int[i]     ),

            // Write port
            .WriteEnable ( DATA_wr_req_int[i]    ),
            .WriteAddr   ( DATA_wr_addr_int      ),
            .WriteData   ( DATA_wdata_int        )
        `ifndef PULP_FPGA_EMUL
            ,
            // BIST ENABLE
            .BIST        ( 1'b0                ), // PLEASE CONNECT ME;

            // BIST ports
            .CSN_T       (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .WEN_T       (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .A_T         (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .D_T         (                     ), // PLEASE CONNECT ME; Synthesis will remove me if unconnected
            .Q_T         (                     )
        `endif
         );
      end
   endgenerate


  refill_arbiter
    #(
      .FETCH_ADDR_WIDTH         ( FETCH_ADDR_WIDTH         ),
      .REFILL_DATA_WIDTH        ( REFILL_DATA_WIDTH        )
      )
  i_refill_arbiter
    (
     .clk                      ( clk                      ),
     .rst_n                    ( rst_n                    ),
     .test_en_i                ( test_en_i                ),

     .refill_req_i             ( refill_req_int           ),
     .refill_gnt_o             ( refill_gnt_int           ),
     .refill_addr_i            ( refill_addr_int          ),
     .refill_r_valid_o         ( refill_r_valid_int       ),
     .refill_r_data_o          ( refill_r_data_int        ),

     // Interface to cache_controller_to Icache L1.5 port
     .pre_refill_req_i         ( pre_refill_req_int       ),
     .pre_refill_gnt_o         ( pre_refill_gnt_int       ),
     .pre_refill_addr_i        ( pre_refill_addr_int      ),
     .pre_refill_r_valid_o     ( pre_refill_r_valid_int   ),
     .pre_refill_r_data_o      ( pre_refill_r_data_int    ),

     .arbiter_req_o             ( refill_req_o             ),
     .arbiter_gnt_i             ( refill_gnt_i             ),
     .arbiter_addr_o            ( refill_addr_o            ),
     .arbiter_r_valid_i         ( refill_r_valid_i         ),
     .arbiter_r_data_i          ( refill_r_data_i          )
     );

endmodule // pri_icache
