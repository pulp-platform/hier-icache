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

module ram_ws_rs_data_scm
#(
    parameter data_width     = 64,
    parameter addr_width     = 7,
    parameter be_width       = data_width/8
)
(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic [addr_width-1:0]       addr,
    input  logic                        req,
    input  logic                        write,
    input  logic [be_width-1:0][7:0]    wdata,
    input  logic [be_width-1:0]         be,
    output logic [data_width-1:0]       rdata
);

`ifdef USE_SRAM_DATA_CACHE
 `ifdef SYNTHESIS
   logic cs_n;
   logic we_n;

   assign  cs_n = ~req;
   assign  we_n = ~write;
   if (data_width==128) begin : SRAM_CUT
      case (addr_width)
        5: begin

           logic [6:0]   n_aw;
           logic         n_ac;
           logic [127:0] bw;

           // Current available GF22 memory macros have 256 rows, which means a wider address width (8 bits)
           assign {n_aw, n_ac} = {3'b0, addr};
           assign bw = (we_n) ?  '0 : '1;

           // GF22
           IN22FDX_R1PH_NFHN_W00256B128M02C256 sram_data
             (
              .CLK      ( clk   ), // input
              .CEN      ( cs_n  ), // input
              .RDWEN    ( we_n  ), // input
              .AW       ( n_aw  ), // input [6:0]
              .AC       ( n_ac  ), // input
              .D        ( wdata ), // input [127:0]
              .BW       ( bw    ), // input [127:0]
              .T_LOGIC  ( 1'b0  ), // input
              .MA_SAWL  ( '0    ), // input
              .MA_WL    ( '0    ), // input
              .MA_WRAS  ( '0    ), // input
              .MA_WRASD ( '0    ), // input
              .Q        ( rdata ), // output [127:0]
              .OBSV_CTL (       )  // output
              );
        end // case: 5
        6: begin

           logic [6:0]   n_aw;
           logic         n_ac;
           logic [127:0] bw;

           // Current memory macros have 256 lines, which means a wider address width (8 bits)
           assign {n_aw, n_ac} = {2'b0, addr};
           assign bw = (we_n) ?  '0 : '1;

           // GF22
           IN22FDX_R1PH_NFHN_W00256B128M02C256 sram_data
             (
              .CLK      ( clk   ), // input
              .CEN      ( cs_n  ), // input
              .RDWEN    ( we_n  ), // input
              .AW       ( n_aw  ), // input [6:0]
              .AC       ( n_ac  ), // input
              .D        ( wdata ), // input [127:0]
              .BW       ( bw    ), // input [127:0]
              .T_LOGIC  ( 1'b0  ), // input
              .MA_SAWL  ( '0    ), // input
              .MA_WL    ( '0    ), // input
              .MA_WRAS  ( '0    ), // input
              .MA_WRASD ( '0    ), // input
              .Q        ( rdata ), // output [127:0]
              .OBSV_CTL (       )  // output
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
   ) sram_data (
     .clk_i   (clk),
     .rst_ni  (rst_n),
     .req_i   (req),
     .we_i    (write),
     .addr_i  (addr),
     .wdata_i (wdata),
     .be_i    (be),
     .rdata_o (rdata)
   );

 `endif // !`ifdef SYNTHESIS

`else

 `ifdef PULP_FPGA_EMUL
    register_file_1r_1w
 `elsif USE_FF_DATA_CACHE
    register_file_1r_1w_test_wrap
 `endif
    #(
        .ADDR_WIDTH(addr_width),
        .DATA_WIDTH(data_width)
    )
    scm_data
    (
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),

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
