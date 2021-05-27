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

`ifdef HIER_ICACHE_USE_TAG_SRAM

    tc_sram #(.NumWords(2**addr_width), .DataWidth(data_width), .NumPorts(1)) i_sram_tag (
        .clk_i  (clk    ),
        .rst_ni (rst_n  ),
        .req_i  (req    ),
        .we_i   (write  ),
        .addr_i (addr   ),
        .wdata_i(wdata  ),
        .be_i   ('1     ),
        .rdata_o(rdata  )
    );

`else
   `ifdef PULP_FPGA_EMUL
      register_file_1r_1w
   `else
      `ifdef HIER_ICACHE_TAG_MEM_USE_LATCHES
        latch_register_file_1r_1w_test_wrap
      `else
        ff_register_file_1r_1w_test_wrap
      `endif 
   `endif
      #(
        .ADDR_WIDTH(addr_width),
        .DATA_WIDTH(data_width)
      )
      i_scm_tag
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
