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
// Module Name:    pri_icache_controller                                      //
// Project Name:   icache exploration                                         //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Private Cache controller for a 128b fetch interface proc   //
//                 Support bypass and flush command                           //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "pulp_soc_defines.sv"

module pri_icache_controller
#(
   parameter FETCH_ADDR_WIDTH     = 32,
   parameter FETCH_DATA_WIDTH     = 32,
   parameter REFILL_DATA_WIDTH    = 128,

   parameter NB_CORES             = 4,
   parameter NB_WAYS              = 4,
   parameter CACHE_LINE           = 4,

   parameter SCM_TAG_ADDR_WIDTH   = 4,
   parameter SCM_DATA_ADDR_WIDTH  = 6,
   parameter SCM_TAG_WIDTH        = 8,
   parameter SCM_DATA_WIDTH       = 128,

   parameter SET_ID_LSB           = $clog2(SCM_DATA_WIDTH*CACHE_LINE)-3,
   parameter SET_ID_MSB           = SET_ID_LSB + SCM_TAG_ADDR_WIDTH - 1,
   parameter TAG_LSB              = SET_ID_MSB + 1,
   parameter TAG_MSB              = TAG_LSB + SCM_TAG_WIDTH - 2
)
(
   input logic                                              clk,
   input logic                                              rst_n,

   input  logic                                             bypass_icache_i,
   output logic                                             cache_is_bypassed_o,
   input  logic                                             flush_icache_i,
   output logic                                             cache_is_flushed_o,

   input  logic                                             flush_set_ID_req_i,
   input  logic [FETCH_ADDR_WIDTH-1:0]                      flush_set_ID_addr_i,
   output logic                                             flush_set_ID_ack_o,

`ifdef FEATURE_ICACHE_STAT
    output logic [31:0]                                     bank_hit_count_o,
    output logic [31:0]                                     bank_trans_count_o,
    output logic [31:0]                                     bank_miss_count_o,

    input  logic                                            ctrl_clear_regs_i,
    input  logic                                            ctrl_enable_regs_i,
`endif
   input  logic                                             enable_l1_l15_prefetch_i,

   // interface with processor
   input  logic                                             fetch_req_i,
   input  logic [FETCH_ADDR_WIDTH-1:0]                      fetch_addr_i,
   output logic                                             fetch_gnt_o,
   output logic                                             fetch_rvalid_o,
   output logic [FETCH_DATA_WIDTH-1:0]                      fetch_rdata_o,


   // interface with READ PORT --> SCM DATA
   output logic [NB_WAYS-1:0]                               DATA_rd_req_o,
   output logic [NB_WAYS-1:0]                               DATA_wr_req_o,
   output logic [SCM_DATA_ADDR_WIDTH-1:0]                   DATA_rd_addr_o,
   output logic [SCM_DATA_ADDR_WIDTH-1:0]                   DATA_wr_addr_o,
   input  logic [NB_WAYS-1:0][SCM_DATA_WIDTH-1:0]           DATA_rdata_i,
   output logic [REFILL_DATA_WIDTH-1:0]                     DATA_wdata_o,

   // interface with READ PORT --> SCM TAG
   output logic [1:0][NB_WAYS-1:0]                          TAG_req_o,
   output logic [1:0][SCM_TAG_ADDR_WIDTH-1:0]               TAG_addr_o,
   input  logic [NB_WAYS-1:0][1:0][SCM_TAG_WIDTH-1:0]       TAG_rdata_i,
   output logic [SCM_TAG_WIDTH-1:0]                         TAG_wdata_o,
   output logic                                             TAG_we_o,


   // Interface to cache_controller_to uDMA L2 port
   output logic                                             pre_refill_req_o,
   input  logic                                             pre_refill_gnt_i,
   output logic [FETCH_ADDR_WIDTH-1:0]                      pre_refill_addr_o,
   input  logic                                             pre_refill_r_valid_i,
   input  logic [REFILL_DATA_WIDTH-1:0]                     pre_refill_r_data_i,

   output logic                                             refill_req_o,
   input  logic                                             refill_gnt_i,
   output logic [FETCH_ADDR_WIDTH-1:0]                      refill_addr_o,
   input  logic                                             refill_r_valid_i,
   input  logic [REFILL_DATA_WIDTH-1:0]                     refill_r_data_i
);

   typedef logic [NB_WAYS-1:0]                              logic_nbways;

   logic [FETCH_ADDR_WIDTH-1:0]                             fetch_addr_Q;
   logic [NB_WAYS-1:0]                                      fetch_way_Q;

   logic [FETCH_ADDR_WIDTH-1:0]                             fetch_addr_P;
   logic                                                    fetch_req_P;
   logic                                                    fetch_req_C;
   logic [NB_WAYS-1:0]                                      fetch_way_P;

   logic                                                    refill_wait_bypass;

   logic                                                    clear_pipe;
   logic                                                    enable_pipe;
   logic                                                    save_fetch_way;
   logic                                                    save_fetch_way_p;

   logic                                                    prefetch_enable;
   logic                                                    prefetch_start;
   logic                                                    prefetch_hit;
   logic                                                    prefetch_stop;
   logic                                                    s_is_branch;

   logic [NB_WAYS-1:0]                                      DATA_rd_req_int;
   logic [NB_WAYS-1:0]                                      DATA_wr_req_int;
   logic [SCM_DATA_ADDR_WIDTH-1:0]                          DATA_addr_int;
   logic [REFILL_DATA_WIDTH-1:0]                            DATA_wdata_int;

   logic [NB_WAYS-1:0]                                      TAG_req_int;
   logic [SCM_TAG_ADDR_WIDTH-1:0]                           TAG_addr_int;
   logic [SCM_TAG_WIDTH-1:0]                                TAG_wdata_int;
   logic                                                    TAG_we_int;

   logic [NB_WAYS-1:0]                                      DATA_wr_req_q;
   logic [SCM_DATA_ADDR_WIDTH-1:0]                          DATA_addr_q;
   logic [REFILL_DATA_WIDTH-1:0]                            DATA_wdata_q;

   logic [NB_WAYS-1:0]                                      TAG_req_q;
   logic [SCM_TAG_ADDR_WIDTH-1:0]                           TAG_addr_q;
   logic [SCM_TAG_WIDTH-1:0]                                TAG_wdata_q;
   logic                                                    TAG_we_q;

   logic [REFILL_DATA_WIDTH/FETCH_DATA_WIDTH-1:0][FETCH_DATA_WIDTH-1:0] refill_r_data_int;
   logic [REFILL_DATA_WIDTH/FETCH_DATA_WIDTH-1:0][FETCH_DATA_WIDTH-1:0] pre_refill_r_data_int;
   logic [REFILL_DATA_WIDTH/FETCH_DATA_WIDTH-1:0][FETCH_DATA_WIDTH-1:0] DATA_rdata_hit_int;

   assign s_is_branch = (fetch_addr_i[31:4] != fetch_addr_P[31:4]);

   assign DATA_rd_req_o   = DATA_rd_req_int;
   assign DATA_rd_addr_o  = DATA_addr_int;
   assign DATA_wr_req_o   = TAG_req_int     ? DATA_wr_req_int: DATA_wr_req_q;
   assign DATA_wr_addr_o  = DATA_wr_req_int ? DATA_addr_int  : DATA_addr_q;
   assign DATA_wdata_o    = DATA_wr_req_int ? DATA_wdata_int : DATA_wdata_q;

   assign TAG_req_o[0]    = TAG_req_int ? TAG_req_int   : TAG_req_q;
   assign TAG_addr_o[0]   = TAG_req_int ? TAG_addr_int  : TAG_addr_q;
   assign TAG_wdata_o     = TAG_req_int ? TAG_wdata_int : TAG_wdata_q;
   assign TAG_we_o        = TAG_req_int ? TAG_we_int    : TAG_we_q;

   logic [SCM_TAG_ADDR_WIDTH-1:0]                           counter_FLUSH_NS, counter_FLUSH_CS;

   logic [1:0][NB_WAYS-1:0]                                 way_match;
   logic [1:0][NB_WAYS-1:0]                                 way_valid;

   logic [NB_WAYS-1:0]                                      random_way;
   logic [$clog2(NB_WAYS)-1:0]                              first_available_way;
   logic [NB_WAYS-1:0]                                      first_available_way_OH;
   logic [$clog2(NB_WAYS)-1:0]                              first_available_way_p;
   logic [NB_WAYS-1:0]                                      first_available_way_p_OH;

   logic [$clog2(NB_WAYS)-1:0]                              HIT_WAY;
   logic [$clog2(NB_WAYS)-1:0]                              HIT_WAY_p;

   assign refill_r_data_int      = refill_r_data_i;
   assign pre_refill_r_data_int  = pre_refill_r_data_i;
   assign DATA_rdata_hit_int     = DATA_rdata_i[HIT_WAY];

   assign cache_is_busy_o        = refill_wait_bypass;

   assign first_available_way_OH   = logic_nbways'(1 << first_available_way);
   assign first_available_way_p_OH = logic_nbways'(1 << first_available_way_p);

   enum                                                     logic [3:0] { DISABLED_ICACHE, BYPASS_REFILL, BYPASS_WAIT_REFILL_DONE, CONFLICT_REFILL, WAIT_PREFETCH, WAIT_REFILL_GNT, WAIT_REFILL_DONE, IDLE_ENABLED, TAG_LOOKUP, FLUSH_ICACHE, FLUSH_SET_ID } CS, NS;
   enum                                                     logic [2:0] { PRE_DISABLE, PRE_IDLE, PRE_TAG_LOOKUP, PRE_WAIT_REFILL_GNT, PRE_WAIT_REFILL_DONE } PRE_CS, PRE_NS;

   int unsigned                                             i,j,index;

   logic [NB_WAYS-1:0]                                      fetch_way_int;
   logic [NB_WAYS-1:0]                                      fetch_way_p_int;
   logic                                                    update_lfsr;
   logic                                                    update_lfsr_p;


   logic                                                    hit_counter_enable;
   logic                                                    miss_counter_enable;
   logic                                                    miss_counter_enable_delay;

`ifdef FEATURE_ICACHE_STAT

   logic [31:0]                                             eviction_counter;

   always_ff @(posedge clk, negedge rst_n)
     begin
        if(~rst_n)
          begin
             bank_trans_count_o      <= '0;
             bank_hit_count_o        <= '0;
             bank_miss_count_o       <= '0;
             eviction_counter        <= '0;
             miss_counter_enable_delay     <= '0;
          end
        else
          begin
             miss_counter_enable_delay     <= miss_counter_enable;

             if(ctrl_clear_regs_i)
               begin
                  bank_trans_count_o      <= '0;
                  bank_hit_count_o        <= '0;
                  bank_miss_count_o       <= '0;
                  eviction_counter        <= '0;
               end
             else
               begin
                  if(ctrl_enable_regs_i)
                    begin
                       if(fetch_req_i & fetch_gnt_o)
                         bank_trans_count_o <=  bank_trans_count_o + 1;

                       if(hit_counter_enable)
                         bank_hit_count_o <=  bank_hit_count_o + 1;

                       if(miss_counter_enable & ~miss_counter_enable_delay)
                         bank_miss_count_o <=  bank_miss_count_o + 1;

                       if( update_lfsr & (&way_valid[0]) )
                         eviction_counter <=  eviction_counter + 1;
                    end
               end
          end
     end
`endif


   always_ff @(posedge clk, negedge rst_n)
     begin
        if(~rst_n)
          begin
             CS                       <= DISABLED_ICACHE;
             fetch_addr_Q             <= '0;
             fetch_way_Q              <= '0;
             counter_FLUSH_CS         <= '0;
          end
        else
          begin
             CS <= NS;
             counter_FLUSH_CS <= counter_FLUSH_NS;

             if(save_fetch_way)
               fetch_way_Q <= fetch_way_int;

             if(enable_pipe)
               fetch_addr_Q <= fetch_addr_i;
          end
     end

`ifdef HIERARCHY_ICACHE_32BIT
   logic                                                    r_is_not_branch;
   logic                                                    r_pre_refill_r_valid_Q;
   always_ff @(posedge clk, negedge rst_n)
     begin
        if(~rst_n)
          begin
             r_is_not_branch <= 1'b0;
             r_pre_refill_r_valid_Q <= 1'b0;
          end
        else
          begin
             if(enable_l1_l15_prefetch_i) begin
                r_pre_refill_r_valid_Q <= pre_refill_r_valid_i;

                if (fetch_req_i)
                  r_is_not_branch <= ~s_is_branch & ((prefetch_start & ~prefetch_hit) | pre_refill_r_valid_i);
             end else begin // if (enable_l1_l15_prefetch_i)
                r_is_not_branch <= 1'b0;
                r_pre_refill_r_valid_Q <= 1'b0;
             end
          end
     end
`endif   

   // PREFETCH
   always_ff @(posedge clk, negedge rst_n)
     begin
        if(~rst_n)
          begin
             PRE_CS         <= PRE_DISABLE;
             fetch_addr_P   <= '0;
             fetch_way_P    <= '0;
             fetch_req_P    <= 1'b0;
             fetch_req_C    <= 1'b0;
          end
        else
          begin
             PRE_CS <= PRE_NS;

             if(save_fetch_way_p)
               fetch_way_P <= fetch_way_p_int;

             if(enable_l1_l15_prefetch_i)
               begin
                  if (fetch_req_i & prefetch_start) begin
                     fetch_req_C    <= 1'b1;
                  end

                  if (fetch_req_i & ~prefetch_start) begin
                     fetch_addr_P  <= {fetch_addr_i[31:4], 4'h0} + 'h10;
                     fetch_req_P   <= 1'b1;
                  end else if (fetch_req_C & fetch_rvalid_o & ~prefetch_start) begin
                     fetch_addr_P  <= {fetch_addr_Q[31:4], 4'h0} + 'h10;
                     fetch_req_P   <= 1'b1;
                     fetch_req_C   <= 1'b0;
                  end else begin
                     fetch_req_P   <= 1'b0;
                  end
               end else begin // if (enable_l1_l15_prefetch_i)
                  fetch_addr_P   <= '0;
                  fetch_way_P    <= '0;
                  fetch_req_P    <= 1'b0;
                  fetch_req_C    <= 1'b0;
               end
          end
     end

   always_ff @(posedge clk, negedge rst_n)
     begin
        if(~rst_n)
          begin
             refill_wait_bypass             <= 1'b0;
          end
        else
          begin
             if( CS == DISABLED_ICACHE || CS == BYPASS_WAIT_REFILL_DONE) begin
                //Use this code to be sure thhat there is not apending transaction when enable cache request is asserted
                case({fetch_req_i & fetch_gnt_o , refill_r_valid_i})
                  2'b00: begin refill_wait_bypass <= refill_wait_bypass;      end
                  2'b01: begin refill_wait_bypass <= 1'b0;                    end
                  2'b10: begin refill_wait_bypass <= 1'b1;                    end
                  2'b11: begin refill_wait_bypass <= 1'b1;                    end
                endcase // case ({fetch_req_i & fetch_gnt_o , refill_r_valid_i})
             end
          end
     end

   // --------------------- //
   // TAG CHECK MULTI WAY   //
   // --------------------- //
   genvar k;
   generate
      for(k=0; k<NB_WAYS; k++)
        begin : TAG_CHECK
           assign way_valid[0][k]  = (TAG_rdata_i[k][0][SCM_TAG_WIDTH-1] == 1'b1);
           assign way_match[0][k]  = (way_valid[0][k] && (TAG_rdata_i[k][0][SCM_TAG_WIDTH-2:0] == fetch_addr_Q[TAG_MSB:TAG_LSB]));

           assign way_valid[1][k]  = (TAG_rdata_i[k][1][SCM_TAG_WIDTH-1] == 1'b1);
           assign way_match[1][k]  = (way_valid[1][k] && (TAG_rdata_i[k][1][SCM_TAG_WIDTH-2:0] == fetch_addr_P[TAG_MSB:TAG_LSB]));
        end
   endgenerate

   always_comb
     begin : FETCH
        TAG_req_int          = '0;
        TAG_we_int           = 1'b0;
        TAG_addr_int         = fetch_addr_i[SET_ID_MSB:SET_ID_LSB];
        TAG_wdata_int        = {1'b1,fetch_addr_Q[TAG_MSB:TAG_LSB]};

        DATA_rd_req_int      = {NB_WAYS{fetch_req_i}};
        DATA_wr_req_int      = fetch_way_Q & {NB_WAYS{refill_r_valid_i}};
        DATA_addr_int        = fetch_addr_i[SET_ID_MSB:SET_ID_LSB];
        DATA_wdata_int       = refill_r_data_int;

        fetch_gnt_o        = 1'b0;
        fetch_rvalid_o     = 1'b0;

        `ifdef HIERARCHY_ICACHE_32BIT
        fetch_rdata_o      = refill_r_data_int[fetch_addr_Q[3:2]];
        `else
        fetch_rdata_o      = refill_r_data_int[0];
        `endif

        refill_req_o       = 1'b0;
        refill_addr_o      = fetch_addr_Q;
        fetch_way_int      = '0;

        save_fetch_way          = '0;

        enable_pipe             = 1'b0;
        clear_pipe              = 1'b0;

        NS                      = CS;
        update_lfsr             = 1'b0;

        cache_is_bypassed_o     = 1'b0;
        cache_is_flushed_o      = 1'b0;

        counter_FLUSH_NS        = counter_FLUSH_CS;

        flush_set_ID_ack_o      = 1'b0;

        hit_counter_enable      = 1'b0;
        miss_counter_enable     = 1'b0;

        case(CS)

          DISABLED_ICACHE:
            begin
               flush_set_ID_ack_o  = 1'b1;

               counter_FLUSH_NS    = '0;
               enable_pipe         = 1'b1; // enable addr delay 1 cycle
               cache_is_bypassed_o = 1'b1;
               cache_is_flushed_o  = 1'b1;

               fetch_rvalid_o      = refill_r_valid_i; // Must a single beat transaction

               if(bypass_icache_i | refill_wait_bypass) // Already Bypassed
                 begin
                    // gnt = 1 directly when there is request
                    if (bypass_icache_i) begin
                       fetch_gnt_o  = fetch_req_i;

                       if(fetch_req_i)
                         NS = BYPASS_REFILL;
                       else
                         NS = DISABLED_ICACHE;
                    end
                 end
               else
                 begin // Enable ICache
                    clear_pipe    = 1'b1;
                    fetch_gnt_o   = 1'b0;
                    NS            = FLUSH_ICACHE;
                 end
            end

          BYPASS_REFILL:
            begin
               flush_set_ID_ack_o  = 1'b1;

               counter_FLUSH_NS    = '0;
               clear_pipe          = 1'b1;
               cache_is_bypassed_o = 1'b1;
               cache_is_flushed_o  = 1'b1;

               refill_req_o        = 1'b1;
               refill_addr_o       = fetch_addr_Q;

               if(refill_gnt_i)
                 NS = BYPASS_WAIT_REFILL_DONE;
               else
                 NS = BYPASS_REFILL;
            end

          BYPASS_WAIT_REFILL_DONE:
            begin
               flush_set_ID_ack_o  = 1'b1;

               counter_FLUSH_NS    = '0;
               clear_pipe          = 1'b1;
               cache_is_bypassed_o = 1'b1;
               cache_is_flushed_o  = 1'b1;

               fetch_rvalid_o      = refill_r_valid_i; // Must a single beat transaction

               if(refill_r_valid_i)
                 NS = DISABLED_ICACHE;
               else
                 NS = BYPASS_WAIT_REFILL_DONE;
            end

          FLUSH_ICACHE:
            begin
               fetch_gnt_o           = 1'b0;
               flush_set_ID_ack_o    = 1'b1;

               if(counter_FLUSH_CS < 2**SCM_TAG_ADDR_WIDTH-1)
                 begin
                    NS = FLUSH_ICACHE;
                    counter_FLUSH_NS = counter_FLUSH_CS + 1'b1;
                 end
               else
                 begin
                    NS = IDLE_ENABLED;
                    cache_is_flushed_o  = 1'b1;
                    counter_FLUSH_NS    = '0;
                 end

               TAG_req_int   = '1;
               TAG_we_int    = 1'b1;
               TAG_addr_int  = counter_FLUSH_CS;
               TAG_wdata_int = '0;
            end //~FLUSH_ICACHE

          FLUSH_SET_ID:
            begin
               fetch_gnt_o           = 1'b0;
               flush_set_ID_ack_o    = 1'b1;

               NS = IDLE_ENABLED;

               TAG_req_int   = '1;
               TAG_we_int    = 1'b1;
               TAG_addr_int  = flush_set_ID_addr_i[SET_ID_MSB:SET_ID_LSB];
               TAG_wdata_int = '0;
            end //~FLUSH_SET_ID

          IDLE_ENABLED:
            begin
               fetch_gnt_o          = fetch_req_i & ~(bypass_icache_i | flush_icache_i | flush_set_ID_req_i );

               if(bypass_icache_i | flush_icache_i | flush_set_ID_req_i ) // first check if the previous fetch has a miss or HIT
                 begin
                    if(bypass_icache_i)
                      NS = DISABLED_ICACHE;
                    else if (flush_icache_i)
                      NS = FLUSH_ICACHE;
                    else
                      NS = FLUSH_SET_ID;

                    clear_pipe = 1'b1;
                 end // if (bypass_icache_i | flush_icache_i | flush_set_ID_req_i )
               else // NO Bypass ,FLUSH or SET_IF FLUSH request
                 begin
                    //Read the DATA and TAG
                    TAG_req_int   = {NB_WAYS{fetch_req_i}};

                    enable_pipe = fetch_req_i;

                    if(fetch_req_i)
                      if (enable_l1_l15_prefetch_i)
                        if(s_is_branch)
                          NS = TAG_LOOKUP;
                        else
                          if(prefetch_hit)
                            NS = TAG_LOOKUP;
                          else if(pre_refill_r_valid_i)
                            NS = CONFLICT_REFILL;
                          else if (prefetch_start)
                            NS = WAIT_PREFETCH;
                          else
                            NS = TAG_LOOKUP;
                      else
                        NS = TAG_LOOKUP;
                    else
                      NS = IDLE_ENABLED;
                 end
            end // case: IDLE_ENABLED

          CONFLICT_REFILL:
            begin
               hit_counter_enable = 1'b1;

               fetch_rvalid_o  = 1'b1;

               `ifdef HIERARCHY_ICACHE_32BIT
               fetch_rdata_o = pre_refill_r_data_int[fetch_addr_Q[3:2]];
               `else
               fetch_rdata_o = pre_refill_r_data_int[0];
               `endif

               NS = IDLE_ENABLED;
            end

          WAIT_PREFETCH:
            begin
               fetch_rvalid_o  = pre_refill_r_valid_i;

               `ifdef HIERARCHY_ICACHE_32BIT
               fetch_rdata_o      = pre_refill_r_data_int[fetch_addr_Q[3:2]];
               `else
               fetch_rdata_o      = pre_refill_r_data_int[0];
               `endif

               if (pre_refill_r_valid_i)
                 begin
                    hit_counter_enable = 1'b1;
                    clear_pipe = 1'b1;
                    NS = IDLE_ENABLED;
                 end
               else
                 begin
                    NS = WAIT_PREFETCH;
                 end
            end

          TAG_LOOKUP:
            begin
               fetch_gnt_o          = fetch_req_i;
               enable_pipe          = fetch_req_i;

               //Read the DATA and TAG
               TAG_req_int   = {NB_WAYS{fetch_req_i}};

               `ifdef HIERARCHY_ICACHE_32BIT
               fetch_rdata_o      = DATA_rdata_hit_int[fetch_addr_Q[3:2]];
               `else
               fetch_rdata_o      = DATA_rdata_hit_int[0];
               `endif

               if(|way_match[0])
                 begin : HIT
                    hit_counter_enable = 1'b1;

                    if(fetch_req_i == 1'b0)
                      begin
                         clear_pipe = 1'b1;
                         NS = IDLE_ENABLED;
                      end
                    else
                      begin
                         NS = TAG_LOOKUP;
                      end
                    fetch_rvalid_o  = 1'b1;
                 end
        `ifdef HIERARCHY_ICACHE_32BIT
               else if (r_is_not_branch) begin
                 hit_counter_enable = 1'b1;

                  if (pre_refill_r_valid_i | r_pre_refill_r_valid_Q)
                    NS = CONFLICT_REFILL;
                  else
                    NS = WAIT_PREFETCH;
               end
	`endif
               else
                 begin : MISS
                    miss_counter_enable      = 1'b1;

                    enable_pipe      = 1'b0;

                    refill_req_o     = 1'b1;
                    refill_addr_o    = fetch_addr_Q;

                    save_fetch_way   = 1'b1;
                    // This check is postponed because the tag Check is complex. better to do
                    // one cycle later;
                    if(&way_valid[0]) // all the lines are valid, invalidate one random line
                      begin
                         fetch_way_int = random_way;
                         update_lfsr = 1'b1;
                      end
                    else
                      begin
                         fetch_way_int = first_available_way_OH;
                         update_lfsr = 1'b0;
                      end

                    if(refill_gnt_i)
                      NS = WAIT_REFILL_DONE;
                    else
                      NS = WAIT_REFILL_GNT;
                 end
            end //~TAG_LOOKUP

          WAIT_REFILL_GNT:
            begin
               refill_req_o     = 1'b1;
               refill_addr_o    = fetch_addr_Q;

               if(refill_gnt_i)
                 NS = WAIT_REFILL_DONE;
               else
                 NS = WAIT_REFILL_GNT;
            end

          WAIT_REFILL_DONE:
            begin
               fetch_rvalid_o  = refill_r_valid_i;

               DATA_addr_int     = fetch_addr_Q[SET_ID_MSB:SET_ID_LSB];

               TAG_req_int       = fetch_way_Q & {NB_WAYS{refill_r_valid_i}};
               TAG_we_int        = 1'b1;
               TAG_addr_int      = fetch_addr_Q[SET_ID_MSB:SET_ID_LSB];
               TAG_wdata_int     = {1'b1,fetch_addr_Q[TAG_MSB:TAG_LSB]};

               if(refill_r_valid_i)
                 begin
                    NS = IDLE_ENABLED;
                    clear_pipe = 1'b1;
                 end
               else
                 begin
                    NS = WAIT_REFILL_DONE;
                 end
            end //~WAIT_REFILL_DONE

          default:
            begin
               NS = DISABLED_ICACHE;
            end
        endcase // case (CS)
     end // block: FETCH


   // PREFETCH
   always_comb
     begin : PREFETCH
        // FSM
        PRE_NS           = PRE_CS;

        // Prefetch read dual port
        TAG_req_o[1]  = '0;
        TAG_addr_o[1] = fetch_addr_P[SET_ID_MSB:SET_ID_LSB];

        // Select WAY
        fetch_way_p_int  = '0;
        save_fetch_way_p = '0;
        update_lfsr_p    = 1'b0;

        // Prefetch refill
        pre_refill_req_o  = 1'b0;
        pre_refill_addr_o = fetch_addr_P;

        // Prefetch write single port
        DATA_wr_req_q   = fetch_way_P & {NB_WAYS{pre_refill_r_valid_i}};
        DATA_addr_q     = fetch_addr_P[SET_ID_MSB:SET_ID_LSB];
        DATA_wdata_q    = pre_refill_r_data_int;

        TAG_req_q       = fetch_way_P & {NB_WAYS{pre_refill_r_valid_i}};
        TAG_we_q        = 1'b0;
        TAG_addr_q      = fetch_addr_P[SET_ID_MSB:SET_ID_LSB];
        TAG_wdata_q     = {1'b1,fetch_addr_P[TAG_MSB:TAG_LSB]};

        // Communication with FSM FETCH
        prefetch_enable  = 1'b0;
        prefetch_start   = 1'b0;
        prefetch_hit     = 1'b0;
        prefetch_stop    = 1'b0;

        case(PRE_CS)
          PRE_DISABLE:
            begin
               if (~bypass_icache_i & enable_l1_l15_prefetch_i)
                 PRE_NS = PRE_IDLE;
               else
                 PRE_NS = PRE_DISABLE;
            end

          PRE_IDLE:
            begin
               //Read the DATA and TAG
               TAG_req_o[1]   = {NB_WAYS{fetch_req_P}};
               TAG_addr_o[1]  = fetch_addr_P[SET_ID_MSB:SET_ID_LSB];

               prefetch_enable  = 1'b1;

               if (bypass_icache_i | ~enable_l1_l15_prefetch_i) begin
                  PRE_NS = PRE_DISABLE;
        `ifdef HIERARCHY_ICACHE_32BIT
               end else if (fetch_req_P & s_is_branch) begin
	`else
               end else if (fetch_req_P & ~fetch_req_i) begin
	`endif
                  PRE_NS = PRE_TAG_LOOKUP;
               end else begin
                  PRE_NS = PRE_IDLE;
               end
            end

          PRE_TAG_LOOKUP:
            begin
               prefetch_start = 1'b1;

               if(|way_match[1])
                 begin : PRE_HIT
                    prefetch_hit = 1'b1;

                    PRE_NS = PRE_IDLE;
                 end
               else
                 begin : PRE_MISS
                    pre_refill_req_o  = 1'b1;

                    save_fetch_way_p   = 1'b1;
                    // This check is postponed because the tag Check is complex. better to do
                    // one cycle later;
                    if(&way_valid[1]) // all the lines are valid, invalidate one random line
                      begin
                         fetch_way_p_int = random_way;
                         update_lfsr_p = 1'b1;
                      end
                    else
                      begin
                         fetch_way_p_int = first_available_way_p_OH;
                         update_lfsr_p = 1'b0;
                      end

                    if(pre_refill_gnt_i)
                      PRE_NS = PRE_WAIT_REFILL_DONE;
                    else
                      PRE_NS = PRE_WAIT_REFILL_GNT;
                 end
            end

          PRE_WAIT_REFILL_GNT:
            begin
               prefetch_start = 1'b1;

               pre_refill_req_o  = 1'b1;

               if(pre_refill_gnt_i)
                 PRE_NS = PRE_WAIT_REFILL_DONE;
               else
                 PRE_NS = PRE_WAIT_REFILL_GNT;
            end

          PRE_WAIT_REFILL_DONE:
            begin
               TAG_we_q        = 1'b1;

               if(pre_refill_r_valid_i) begin
                  prefetch_stop    = 1'b1;
                  PRE_NS = PRE_IDLE;
               end else begin
                  prefetch_start = 1'b1;
                  PRE_NS = PRE_WAIT_REFILL_DONE;
               end
            end
          default:
            begin
               PRE_NS = PRE_DISABLE;
            end
        endcase // case (PRE_CS)
     end // block: PREFETCH


   lfsr_8bit
     #(
       .WIDTH(NB_WAYS),
       .SEED(0)
       )
   i_LFSR_Way_Repl
     (
      .refill_way_oh  ( random_way                   ),
      .refill_way_bin (                              ),
      .en_i           ( update_lfsr | update_lfsr_p  ),
      .clk_i          ( clk                          ),
      .rst_ni         ( rst_n                        )
      );

   always_comb
     begin
        first_available_way = 0;
        first_available_way_p = 0;

        for(index=0;index<NB_WAYS;index++)
          begin
             if(way_valid[0][index]==0)
               first_available_way=index;
          end
        for(index=0;index<NB_WAYS;index++)
          begin
             if(way_valid[1][index]==0)
               first_available_way_p=index;
          end

        HIT_WAY = 0;
        HIT_WAY_p = 0;

        for(index=0;index<NB_WAYS;index++)
          begin
             if(way_match[0][index]==1)
               HIT_WAY=index;
          end
        for(index=0;index<NB_WAYS;index++)
          begin
             if(way_match[1][index]==1)
               HIT_WAY_p=index;
          end

     end


endmodule // fc_icache_controller
