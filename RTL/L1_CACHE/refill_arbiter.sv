//`define USE_REQ_BUFF
`define USE_RESP_BUFF // Must open when use Prefetch mode

module refill_arbiter
  #(
    parameter FETCH_ADDR_WIDTH     = 32,
    parameter REFILL_DATA_WIDTH    = 128
    ) (
       input logic                          clk,
       input logic                          rst_n,
       input logic                          test_en_i,

       // Interface to cache_controller_to uDMA L2 port
       input logic                          refill_req_i,
       output logic                         refill_gnt_o,
       input logic [FETCH_ADDR_WIDTH-1:0]   refill_addr_i,
       output logic                         refill_r_valid_o,
       output logic [REFILL_DATA_WIDTH-1:0] refill_r_data_o,

       input logic                          pre_refill_req_i,
       output logic                         pre_refill_gnt_o,
       input logic [FETCH_ADDR_WIDTH-1:0]   pre_refill_addr_i,
       output logic                         pre_refill_r_valid_o,
       output logic [REFILL_DATA_WIDTH-1:0] pre_refill_r_data_o,

       output logic                         arbiter_req_o,
       input logic                          arbiter_gnt_i,
       output logic [FETCH_ADDR_WIDTH-1:0]  arbiter_addr_o,
       input logic                          arbiter_r_valid_i,
       input logic [REFILL_DATA_WIDTH-1:0]  arbiter_r_data_i
       );


  enum                                      logic[2:0] {IDLE, WAIT_REFILL, WAIT_PREFETCH } cs, ns;


  logic                                     s_arbiter_req;
  logic                                     s_arbiter_gnt;
  logic [FETCH_ADDR_WIDTH-1:0]              s_arbiter_addr;

  logic                                     s_arbiter_r_valid;
  logic [REFILL_DATA_WIDTH-1:0]             s_arbiter_r_data;

  always_ff @(posedge clk or negedge rst_n)
    begin
      if(~rst_n)
        begin
          cs <= IDLE;
        end
      else
        begin
          cs <= ns;
        end
    end

  // offset FSM state transition logic
  always_comb
    begin
      s_arbiter_req        = '0;
      s_arbiter_addr       = '0;

      refill_gnt_o         = '0;
      refill_r_valid_o     = '0;
      refill_r_data_o      = s_arbiter_r_data;

      pre_refill_gnt_o     = '0;
      pre_refill_r_valid_o = '0;
      pre_refill_r_data_o  = s_arbiter_r_data;

      ns = cs;

      case (cs)

        IDLE: begin
          ns = IDLE;

          if (refill_req_i)
            begin

              s_arbiter_req          = refill_req_i;
              s_arbiter_addr         = refill_addr_i;
              `ifndef USE_REQ_BUFF
              refill_gnt_o           = s_arbiter_gnt;
              `else
              refill_gnt_o           = 1'b1;
              `endif
              ns = WAIT_REFILL;
            end
          else if(pre_refill_req_i)
            begin

              s_arbiter_req          = pre_refill_req_i;
              s_arbiter_addr         = pre_refill_addr_i;
              `ifndef USE_REQ_BUFF
              pre_refill_gnt_o       = s_arbiter_gnt;
              `else
              pre_refill_gnt_o       = 1'b1;
              `endif
              ns = WAIT_PREFETCH;
            end
        end

        WAIT_REFILL: begin
          s_arbiter_req          = refill_req_i;
          s_arbiter_addr         = refill_addr_i;
          `ifndef USE_REQ_BUFF
          refill_gnt_o           = s_arbiter_gnt;
          `endif
          refill_r_valid_o       = s_arbiter_r_valid;

          ns = s_arbiter_r_valid ? IDLE : WAIT_REFILL;
        end

        WAIT_PREFETCH: begin
          s_arbiter_req          = pre_refill_req_i;
          s_arbiter_addr         = pre_refill_addr_i;
          `ifndef USE_REQ_BUFF
          pre_refill_gnt_o       = s_arbiter_gnt;
          `endif
          pre_refill_r_valid_o   = s_arbiter_r_valid;

          ns = s_arbiter_r_valid ? IDLE : WAIT_PREFETCH;
        end

        default:
          ns = IDLE;
      endcase
    end



`ifndef USE_REQ_BUFF

  assign arbiter_addr_o       = {s_arbiter_addr[31:4], 4'h0};
  assign arbiter_req_o        = s_arbiter_req;
  assign s_arbiter_gnt        = arbiter_gnt_i;

`else
  logic                        r_arbiter_req;
  logic [FETCH_ADDR_WIDTH-1:4] r_arbiter_addr;

  assign arbiter_req_o        = r_arbiter_req;
  assign arbiter_addr_o       = {r_arbiter_addr[31:4], 4'h0};
  assign s_arbiter_gnt        = arbiter_gnt_i;

  always_ff @(posedge clk, negedge rst_n)
    begin
      if(~rst_n) begin
        r_arbiter_req  <= '0;
        r_arbiter_addr <= '0;
      end else begin

        if (s_arbiter_gnt)
          r_arbiter_req  <= 1'b0;
        else if (s_arbiter_req)
          r_arbiter_req  <= 1'b1;

        if (s_arbiter_req) begin
          r_arbiter_addr <= s_arbiter_addr[31:4];
        end
      end
    end

`endif


`ifndef USE_RESP_BUFF

  assign s_arbiter_r_valid = arbiter_r_valid_i;
  assign s_arbiter_r_data  = arbiter_r_data_i;

`else
  logic                                     r_arbiter_reqing;
  logic                                     r_arbiter_r_valid;
  logic [REFILL_DATA_WIDTH-1:0]             r_arbiter_r_data;

  assign s_arbiter_r_valid = r_arbiter_r_valid;
  assign s_arbiter_r_data  = r_arbiter_r_data;

  always_ff @(posedge clk, negedge rst_n)
    begin
      if(~rst_n) begin
        r_arbiter_reqing  <= '0;
        r_arbiter_r_valid <= '0;
        r_arbiter_r_data  <= '0;
      end else begin
        r_arbiter_r_valid <= arbiter_r_valid_i;

        if (r_arbiter_r_valid)
          r_arbiter_reqing <= 1'b0;
        else if(arbiter_req_o & arbiter_gnt_i)
          r_arbiter_reqing <= 1'b1;

        if (~r_arbiter_r_valid & r_arbiter_reqing)
          r_arbiter_r_data  <= arbiter_r_data_i;
      end
    end

`endif

endmodule // refill_arbiter
