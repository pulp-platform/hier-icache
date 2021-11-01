// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


`include "pulp_soc_defines.sv"


module ram_ws_rs_tag_scm
#(
    parameter data_width = 7,
    parameter addr_width = 6
)
(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic  [addr_width-1:0]   addr,
    input  logic                     req,
    input  logic                     write,
    input  logic [data_width-1:0]    wdata,
    output logic [data_width-1:0]    rdata
);

`ifdef USE_SRAM_TAG_CACHE
   `ifdef SYNTHESIS
   logic cs_n;
   logic we_n;

   assign  cs_n = ~req;
   assign  we_n = ~write;
   if (data_width==10) begin : SRAM_CUT
      case (addr_width)
        5: begin

           logic [6:0]   n_aw;
           logic         n_ac;
           logic [15:0] bw;
           logic [15:0]  n_wdata, n_rdata;

           // Current memory macros have 256 lines, which means a wider address width (8 bits)
           // Also, tag width is 10 bits, but current macros have wider line width (16 bits)
           assign {n_aw, n_ac} = {3'b0, addr};
           assign bw           = (we_n) ?  '0 : '1;
           assign n_wdata      = {6'b0, wdata};
           assign rdata        = n_rdata[data_width-1:0];

           // GF22
           IN22FDX_R1PH_NFHN_W00256B016M02C256 sram_data
             (
              .CLK      ( clk     ), // input
              .CEN      ( cs_n    ), // input
              .RDWEN    ( we_n    ), // input
              .AW       ( n_aw    ), // input [6:0]
              .AC       ( n_ac    ), // input
              .D        ( n_wdata ), // input [15:0]
              .BW       ( bw      ), // input [15:0]
              .T_LOGIC  ( 1'b0    ), // input
              .MA_SAWL  ( '0      ), // input
              .MA_WL    ( '0      ), // input
              .MA_WRAS  ( '0      ), // input
              .MA_WRASD ( '0      ), // input
              .Q        ( n_rdata ), // output [127:0]
              .OBSV_CTL (         )  // output
              );
        end // case: 5
        6: begin

           logic [6:0]   n_aw;
           logic         n_ac;
           logic [15:0] bw;
           logic [15:0]  n_wdata, n_rdata;

           // Current memory macros have 256 lines, which means a wider address width (8 bits)
           // Also, tag width is 10 bits, but current macros have wider line width (16 bits)
           assign {n_aw, n_ac} = {2'b0, addr};
           assign bw           = (we_n) ?  '0 : '1;
           assign n_wdata      = {6'b0, wdata};
           assign rdata        = n_rdata[data_width-1:0];

           // GF22
           IN22FDX_R1PH_NFHN_W00256B016M02C256 sram_data
             (
              .CLK      ( clk     ), // input
              .CEN      ( cs_n    ), // input
              .RDWEN    ( we_n    ), // input
              .AW       ( n_aw    ), // input [6:0]
              .AC       ( n_ac    ), // input
              .D        ( n_wdata ), // input [15:0]
              .BW       ( bw      ), // input [15:0]
              .T_LOGIC  ( 1'b0    ), // input
              .MA_SAWL  ( '0      ), // input
              .MA_WL    ( '0      ), // input
              .MA_WRAS  ( '0      ), // input
              .MA_WRASD ( '0      ), // input
              .Q        ( n_rdata ), // output [127:0]
              .OBSV_CTL (         )  // output
              );
        end // case: 6
        default : /* default */;
      endcase // case (addr_width)
   end // block: SRAM_CUT
 `else

    tc_sram #(
      .NumWords  (2**addr_width),
      .DataWidth (data_width),
      .AddrWidth (addr_width),
      .PrintSimCfg (1'b1),
      .NumPorts  (1)
    ) sram_tag (
      .clk_i   (clk),
      .rst_ni  (rst_n),
      .req_i   (req),
      .we_i    (write),
      .addr_i  (addr),
      .wdata_i (wdata),
      .be_i    ('1), // TAG does not have Byte Enable. Set it to '1 as default
      .rdata_o (rdata)
    );

 `endif // !`ifdef SYNTHESIS

`else
   `ifdef PULP_FPGA_EMUL
      register_file_1r_1w
   `else
      register_file_1r_1w_test_wrap
   `endif
      #(
        .ADDR_WIDTH(addr_width),
        .DATA_WIDTH(data_width)
      )
      scm_tag
      (
        .clk           (clk),
        .rst_n         (rst_n),

        // Read port
        .ReadEnable  ( req & ~write ),
        .ReadAddr    ( addr         ),
        .ReadData    ( rdata        ),

        // Write port
        .WriteEnable ( req & write  ),
        .WriteAddr   ( addr         ),
        .WriteData   ( wdata        )
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
`endif

endmodule
