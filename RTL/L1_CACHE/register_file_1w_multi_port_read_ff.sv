// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module register_file_1w_multi_port_read_ff
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,

    parameter N_READ        = 2,
    parameter N_WRITE       = 1
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
    input  logic [DATA_WIDTH-1:0]                  WriteData
);

    localparam    NUM_WORDS = 2**ADDR_WIDTH;

    // Read address register, located at the input of the address decoder
    logic [N_READ-1:0][ADDR_WIDTH-1:0]             RAddrRegxDP;
    logic [N_READ-1:0][NUM_WORDS-1:0]              RAddrOneHotxD;

    logic [DATA_WIDTH-1:0]                         MemContentxDP[NUM_WORDS];

    logic [NUM_WORDS-1:0]                          WAddrEn;

    int unsigned i;
    int unsigned k;

    genvar       x;
    genvar       z;


    //-----------------------------------------------------------------------------
    //-- READ : Read address register
    //-----------------------------------------------------------------------------

    generate
        for(z=0; z<N_READ; z++ )
        begin
            always_ff @(posedge clk)
            begin : p_RAddrReg
                if(rst_n == 1'b0)
                begin
                    RAddrRegxDP[z] <= '0;
                end
                else
                begin
                    if( ReadEnable[z] )
                        RAddrRegxDP[z] <= ReadAddr[z];
                end
            end



    //-----------------------------------------------------------------------------
    //-- READ : Read address decoder RAD
    //-----------------------------------------------------------------------------
            always @(*)
            begin : p_RAD
              RAddrOneHotxD[z] = '0;
              RAddrOneHotxD[z][RAddrRegxDP[z]] = 1'b1;
            end
            assign ReadData[z] = MemContentxDP[RAddrRegxDP[z]];

        end
    endgenerate

    //-----------------------------------------------------------------------------
    //-- WRITE : Write Address Decoder (WAD), combinatorial process
    //-----------------------------------------------------------------------------
    always_comb
    begin : p_WAD
      for(i=0; i<NUM_WORDS; i++)
        begin : p_WordIter
          WAddrEn[i] = ((WriteEnable == 1'b1 ) && (WriteAddr == i)) ? 1'b1 : 1'b0;
      end
    end

    //-----------------------------------------------------------------------------
    //-- WRITE : Write operation
    //-----------------------------------------------------------------------------

    generate
       for(genvar k=0; k<NUM_WORDS; k++)
         begin: gen_rf
            
           always_ff @(posedge clk or negedge rst_n)
           begin: reg_wdata
              if (rst_n == 1'b0) begin
                 MemContentxDP[k] = '0;
              end else begin
                 if (WAddrEn[k] == 1'b1) begin
                    MemContentxDP[k] = WriteData;
                 end
              end
           end
         end // block: gen_rf
    endgenerate   
   
endmodule
