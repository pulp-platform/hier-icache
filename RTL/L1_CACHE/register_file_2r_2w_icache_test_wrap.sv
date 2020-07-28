// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Company:        Institute of Integrated Systems // ETH Zurich              //
//                                                                            //
// Engineer:      Igor Loi - igor.loi@unibo.it                                //
//                                                                            //
// Additional contributions by:                                               //
//                 Davide Rossi                                               //
//                 Michael Gautschi                                           //
//                 Antonio Pullini                                            //
//                                                                            //
// Create Date:    12/03/2015                                                 // 
// Design Name:    scm memory multiport                                       // 
// Module Name:    register_file_2r_2w                                        //
// Project Name:   PULP                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    scm memory multiport: 2 read Ports, 2 Write ports          //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
// Revision v0.2 - Improved Identation                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module register_file_2r_2w_icache_test_wrap
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32
)
(
    // Clock and Reset
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        testmode_i,

    //Read port R1
    input  logic                        ren_a_i,
    input  logic [ADDR_WIDTH-1:0]       raddr_a_i,
    output logic [DATA_WIDTH-1:0]       rdata_a_o,

    //Read port R2
    input  logic                        ren_b_i,
    input  logic [ADDR_WIDTH-1:0]       raddr_b_i,
    output logic [DATA_WIDTH-1:0]       rdata_b_o,

    // Write port W1
    input logic [ADDR_WIDTH-1:0]        waddr_a_i,
    input logic [DATA_WIDTH-1:0]        wdata_a_i,
    input logic                         we_a_i,

    // Write port W2
    input logic [ADDR_WIDTH-1:0]        waddr_b_i,
    input logic [DATA_WIDTH-1:0]        wdata_b_i,
    input logic                         we_b_i
);
    logic ren_a_i_muxed  ;
    logic [ADDR_WIDTH-1:0] raddr_a_i_muxed;
    logic ren_b_i_muxed  ;
    logic [ADDR_WIDTH-1:0] raddr_b_i_muxed;
    logic we_a_i_muxed   ;
    logic [ADDR_WIDTH-1:0] waddr_a_i_muxed;
    logic [DATA_WIDTH-1:0] wdata_a_i_muxed;
    logic we_b_i_muxed   ;

    always_comb
    begin
        if(testmode_i)
        begin
            ren_a_i_muxed   = 1'b1;
            raddr_a_i_muxed = '0;
            ren_b_i_muxed   = 1'b1;
            raddr_b_i_muxed = '0;
            we_a_i_muxed    = 1'b1;
            waddr_a_i_muxed = '0;
            wdata_a_i_muxed = '0;
            we_b_i_muxed    = 1'b0;
        end
        else begin
            ren_a_i_muxed   = ren_a_i; 
            raddr_a_i_muxed = raddr_a_i;
            ren_b_i_muxed   = ren_b_i;  
            raddr_b_i_muxed = raddr_b_i;
            we_a_i_muxed    = we_a_i;   
            waddr_a_i_muxed = waddr_a_i;
            wdata_a_i_muxed = wdata_a_i;
            we_b_i_muxed    = we_b_i;             
        end
    end

    register_file_2r_2w_icache #(
        .ADDR_WIDTH  ( ADDR_WIDTH          ),
        .DATA_WIDTH  ( DATA_WIDTH          )
    ) register_file_2r_2w_icache_i (
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),

        // Read port
        .ren_a_i     ( ren_a_i_muxed       ),
        .raddr_a_i   ( raddr_a_i_muxed     ),
        .rdata_a_o   ( rdata_a_o           ),

        .ren_b_i     ( ren_b_i_muxed       ),
        .raddr_b_i   ( raddr_b_i_muxed     ),
        .rdata_b_o   ( rdata_b_o     ),

        // Write port
        .we_a_i      ( we_a_i_muxed        ),
        .waddr_a_i   ( waddr_a_i_muxed     ),
        .wdata_a_i   ( wdata_a_i_muxed     ),

        .we_b_i      ( we_b_i_muxed        ),
        .waddr_b_i   ( waddr_b_i           ),
        .wdata_b_i   ( wdata_b_i           )
    );

endmodule
