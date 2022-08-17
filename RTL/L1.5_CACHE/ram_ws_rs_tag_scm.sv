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
    parameter BEHAV_MEM  = 1,
    parameter FPGA_MEM   = 0
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [addr_width-1:0] addr,
    input  logic                  req,
    input  logic                  write,
    input  logic [data_width-1:0] wdata,
    output logic [data_width-1:0] rdata
);

  // TAG CACHE RAM
  icache_tag_sram_wrap #(
      .BehavMem (BEHAV_MEM),
      .FPGAMem  (FPGA_MEM),
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

endmodule
