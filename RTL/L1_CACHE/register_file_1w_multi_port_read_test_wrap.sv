// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module register_file_1w_multi_port_read_test_wrap
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,

    parameter N_READ        = 2
)
(
    input  logic                                   clk,
    input  logic                                   rst_n,
    input  logic                                   test_en_i,

    // Read port
    input  logic [N_READ-1:0]                      ReadEnable,
    input  logic [N_READ-1:0][ADDR_WIDTH-1:0]      ReadAddr,
    output logic [N_READ-1:0][DATA_WIDTH-1:0]      ReadData,

    // Write port
    input  logic                                   WriteEnable,
    input  logic [ADDR_WIDTH-1:0]                  WriteAddr,
    input  logic [DATA_WIDTH-1:0]                  WriteData,

    // BIST ENABLE
    input  logic                                  BIST,
    //BIST ports
    input  logic                                  CSN_T,
    input  logic                                  WEN_T,
    input  logic [ADDR_WIDTH-1:0]                 A_T,
    input  logic [DATA_WIDTH-1:0]                 D_T,
    output logic [DATA_WIDTH-1:0]                 Q_T
);

   logic [N_READ-1:0]                        ReadEnable_muxed;
   logic [N_READ-1:0][ADDR_WIDTH-1:0]        ReadAddr_muxed;

   logic                                     WriteEnable_muxed;
   logic [ADDR_WIDTH-1:0]                    WriteAddr_muxed;
   logic [DATA_WIDTH-1:0]                    WriteData_muxed;


   always_comb
   begin

      ReadEnable_muxed  = ReadEnable;
      ReadAddr_muxed    = ReadAddr;

      if(BIST)
      begin
         ReadEnable_muxed[0]  = (( CSN_T == 1'b0 ) && ( WEN_T == 1'b1));
         ReadAddr_muxed[0]    = A_T;

         ReadEnable_muxed[N_READ-1:1]  = ReadEnable[N_READ-1:1];
         ReadAddr_muxed[N_READ-1:1]    = ReadAddr[N_READ-1:1];


         WriteEnable_muxed = (( CSN_T == 1'b0 ) && ( WEN_T == 1'b0));
         WriteAddr_muxed   = A_T;
         WriteData_muxed   = D_T;
      end
      else
      begin
         ReadEnable_muxed  = ReadEnable;
         ReadAddr_muxed    = ReadAddr;

         WriteEnable_muxed = WriteEnable;
         WriteAddr_muxed   = WriteAddr;
         WriteData_muxed   = WriteData;
      end
   end

   assign Q_T = ReadData[0];


    register_file_1w_multi_port_read
    #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH ),

        .N_READ     ( N_READ     ),
        .N_WRITE    ( 1          )
    )
    register_file_1w_multi_port_read_i
    (
        .clk         ( clk               ),
        .rst_n       ( rst_n             ),
        .test_en_i   ( test_en_i         ),

        .ReadEnable  ( ReadEnable_muxed  ),
        .ReadAddr    ( ReadAddr_muxed    ),
        .ReadData    ( ReadData          ),

        .WriteEnable  ( WriteEnable_muxed ),
        .WriteAddr    ( WriteAddr_muxed   ),
        .WriteData    ( WriteData_muxed   )
    );

endmodule
