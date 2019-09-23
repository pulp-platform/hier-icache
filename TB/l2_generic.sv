//********************************************************
//************* L2 RAM MEMORY WRAPPER ********************
//********************************************************

module l2_generic
#(
  parameter            ADDR_WIDTH = 12
)
(
  input logic                    CLK,
  input logic                    RSTN,

  input logic                    CEN,
  input logic                    WEN,
  input logic [ADDR_WIDTH-1:0]   A,
  input logic [63:0]             D,
  input logic [7:0]              BE,
  output logic [63:0]            Q
);
   
    logic           s_cen;
    logic           s_wen;
            
    // GENERATION OF CEN
    always_comb
    begin
      s_cen = 1'b1;
      if (CEN == 1'b0)
        s_cen = 1'b0;         
    end
   
    // GENERATION OF WEN
    always_comb
    begin
      s_wen = 1'b1;
      if (WEN == 1'b0)
        s_wen = 1'b0;       
    end



   generic_memory_with_grant
   #(
      .ADDR_WIDTH (ADDR_WIDTH),
      .DATA_WIDTH (64)
   )
   cut
   (
      .CLK   (CLK),  
      .INITN (RSTN),

      .CEN   (s_cen),  
      .A     (A[ADDR_WIDTH-1:0]),    
      .GNT   (),  
      .WEN   (s_wen),  
      .D     (D),    
      .BE    (BE),   
      .Q     (Q),    
      .RVAL  ()
   );
      
endmodule