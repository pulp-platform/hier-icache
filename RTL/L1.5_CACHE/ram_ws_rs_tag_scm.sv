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


module ram_ws_rs_tag_scm #(
    parameter data_width = 7,
    parameter addr_width = 6,
    parameter BEHAV_MEM  = 1
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [addr_width-1:0] addr,
    input  logic                  req,
    input  logic                  write,
    input  logic [data_width-1:0] wdata,
    output logic [data_width-1:0] rdata
);

`ifndef PULP_FPGA_EMUL

  // TAG CACHE RAM
  icache_tag_sram_wrap #(
      .BehavMem (BEHAV_MEM),
      .NumWords (2 ** addr_width),  //32 words
      .DataWidth(data_width)
  ) i_tag_cache_ram_wrap (
      .clk_i (clk),
      .rst_ni(rst_n),
      .req_i (req),
      .we_i  (write),
      .addr_i(addr),
      .wdata_i(wdata),
      .be_i   (2'b11),
      .rdata_o(rdata)
  );

`else  // !`ifndef PULP_FPGA_EMUL

  //      register_file_1r_1w
  //      #(
  //        .ADDR_WIDTH(addr_width),
  //        .DATA_WIDTH(data_width)
  //      )
  //      scm_tag
  //      (
  //        .clk           (clk),
  //        .rst_n         (rst_n),
  //
  //        // Read port
  //        .ReadEnable  ( req & ~write ),
  //        .ReadAddr    ( addr         ),
  //        .ReadData    ( rdata        ),
  //
  //        // Write port
  //        .WriteEnable ( req & write  ),
  //        .WriteAddr   ( addr         ),
  //        .WriteData   ( wdata        )
  //      );

  logic                    ena;
  logic [  addr_width-1:0] add;
  logic [data_width/8-1:0] wea;
  logic [  data_width-1:0] wdata_bram;

  assign ena = 1'b1;
  assign wdata_bram = {6'b0, wdata};  // Pad with zeros to get 16 data tag width from 10 bit width
  // Xilinx BRAM does not support sizes not multiple of ByteSize (1B = 8 bits)
  assign wea = {(data_width / 8) {req}} & {(data_width / 8) {write}};

  xilinx_tag_cache_32x10 i_tag_cache_ram_32x10_fpga (
      .clka (clk),
      .rsta (~rst_n),
      .ena  (ena),
      .wea  (wea),
      .addra(addr),
      .dina (wdata),
      .douta(rdata)
  );

`endif  // !`ifndef PULP_FPGA_EMUL

endmodule
