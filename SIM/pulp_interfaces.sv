
interface PRI_ICACHE_CTRL_UNIT_BUS;
    // ICACHE_CTRL UNIT INTERFACE
    //***************************************
    logic                 bypass_req;
    logic                 bypass_ack;
    logic                 flush_req;
    logic                 flush_ack;

    logic                 sel_flush_req;
    logic [31:0]          sel_flush_addr;
    logic                 sel_flush_ack;

`ifdef FEATURE_ICACHE_STAT
    logic [31:0]          ctrl_hit_count;
    logic [31:0]          ctrl_trans_count;
    logic [31:0]          ctrl_miss_count;
    logic [31:0]          ctrl_cong_count;

    logic                 ctrl_clear_regs;
    logic                 ctrl_enable_regs;
`endif

    // Master Side
    //***************************************
    modport Master
    (
        output bypass_req,
        output flush_req,
        input  bypass_ack,
        input  flush_ack,

        output sel_flush_req,
        output sel_flush_addr,
        input  sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        input  ctrl_hit_count,
        input  ctrl_trans_count,
        input  ctrl_miss_count,
        input  ctrl_cong_count,

        output ctrl_clear_regs,
        output ctrl_enable_regs
    `endif
    );

    // Slave Side
    //***************************************
    modport Slave
    (
        input  bypass_req,
        input  flush_req,
        output bypass_ack,
        output flush_ack,

        input  sel_flush_req,
        input  sel_flush_addr,
        output sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        output ctrl_hit_count,
        output ctrl_trans_count,
        output ctrl_miss_count,
        output ctrl_cong_count,

        input  ctrl_clear_regs,
        input  ctrl_enable_regs
    `endif
    );

endinterface //~ PRI_ICACHE_CTRL_UNIT_BUS




interface SP_ICACHE_CTRL_UNIT_BUS;
    // ICACHE_CTRL UNIT INTERFACE
    //***************************************
    logic                 ctrl_req_enable;
    logic                 ctrl_ack_enable;
    logic                 ctrl_req_disable;
    logic                 ctrl_ack_disable;
    logic                 ctrl_pending_trans;
    logic                 ctrl_flush_req;
    logic                 ctrl_flush_ack;
    logic                 icache_is_private;


    logic                 sel_flush_req;
    logic [31:0]          sel_flush_addr;
    logic                 sel_flush_ack;

`ifdef FEATURE_ICACHE_STAT
    logic [31:0]          ctrl_hit_count;
    logic [31:0]          ctrl_trans_count;
    logic [31:0]          ctrl_miss_count;

    logic                 ctrl_clear_regs;
    logic                 ctrl_enable_regs;

`endif

    // Master Side
    //***************************************
    modport Master
    (
        output ctrl_req_enable,
        output ctrl_req_disable,
        output ctrl_flush_req,
        output icache_is_private,

        input  ctrl_flush_ack,
        input  ctrl_ack_enable,
        input  ctrl_ack_disable,
        input  ctrl_pending_trans,

        output        sel_flush_req,
        output        sel_flush_addr,
        input         sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        input  ctrl_hit_count,
        input  ctrl_trans_count,
        input  ctrl_miss_count,
        output ctrl_clear_regs,
        output ctrl_enable_regs
    `endif
    );

    // Slave Side
    //***************************************
    modport Slave
    (
        input  ctrl_req_enable,
        input  ctrl_req_disable,
        input  ctrl_flush_req,
        input  icache_is_private,

        output ctrl_flush_ack,
        output ctrl_ack_enable,
        output ctrl_ack_disable,
        output ctrl_pending_trans,

        input        sel_flush_req,
        input        sel_flush_addr,
        output       sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        output ctrl_hit_count,
        output ctrl_trans_count,
        output ctrl_miss_count,
        input  ctrl_clear_regs,
        input  ctrl_enable_regs
    `endif
    );

endinterface //~ SP_ICACHE_CTRL_UNIT_BUS







interface MP_ICACHE_CTRL_UNIT_BUS;
    // ICACHE_CTRL UNIT INTERFACE
    //***************************************
    logic                 bypass_req;
    logic [`NB_CORES:0]   bypass_ack; // NB_CORES + 1
    logic                 flush_req;
    logic                 flush_ack;

    logic                 sel_flush_req;
    logic [31:0]          sel_flush_addr;
    logic                 sel_flush_ack;

`ifdef FEATURE_ICACHE_STAT
    logic [31:0]          global_hit_count;
    logic [31:0]          global_trans_count;
    logic [31:0]          global_miss_count;
    logic [31:0]          global_cong_count;

    logic [`NB_CORES-1:0][31:0]  bank_hit_count;
    logic [`NB_CORES-1:0][31:0]  bank_trans_count;
    logic [`NB_CORES-1:0][31:0]  bank_miss_count;
    logic [`NB_CORES-1:0][31:0]  bank_cong_count;

    logic                 ctrl_clear_regs;
    logic                 ctrl_enable_regs;
`endif

    // Master Side
    //***************************************
    modport Master
    (
        output bypass_req,
        output flush_req,
        input  bypass_ack,
        input  flush_ack,

        output sel_flush_req,
        output sel_flush_addr,
        input  sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        input  global_hit_count,
        input  global_trans_count,
        input  global_miss_count,
        input  global_cong_count,

        input  bank_hit_count,
        input  bank_trans_count,
        input  bank_miss_count,
        input  bank_cong_count,

        output ctrl_clear_regs,
        output ctrl_enable_regs
    `endif
    );

    // Slave Side
    //***************************************
    modport Slave
    (
        input  bypass_req,
        input  flush_req,
        output bypass_ack,
        output flush_ack,

        input  sel_flush_req,
        input  sel_flush_addr,
        output sel_flush_ack

    `ifdef FEATURE_ICACHE_STAT
        ,
        output global_hit_count,
        output global_trans_count,
        output global_miss_count,
        output global_cong_count,

        output bank_hit_count,
        output bank_trans_count,
        output bank_miss_count,
        output bank_cong_count,

        input  ctrl_clear_regs,
        input  ctrl_enable_regs
    `endif
    );
endinterface //~ MP_ICACHE_CTRL_UNIT_BUS
