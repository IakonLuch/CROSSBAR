module xbar_v2 #(

    ADDR_SIZE  = 32,
    WDATA_SIZE = 32,
    RDATA_SIZE = 32

)   (

    input                   master_0_req,
    input                   master_1_req,
  
    input  [ADDR_SIZE-1:0]  master_0_addr,
    input  [ADDR_SIZE-1:0]  master_1_addr,
 
    input                   master_0_cmd,
    input                   master_1_cmd,
 
    input  [WDATA_SIZE-1:0] master_0_wdata,
    input  [WDATA_SIZE-1:0] master_1_wdata,
 
    output                  master_0_ack,
    output                  master_1_ack,
 
    output [RDATA_SIZE-1:0] master_0_rdata,
    output [RDATA_SIZE-1:0] master_1_rdata,

    output                  slave_0_req,                      
    output                  slave_1_req,

    output  [ADDR_SIZE-1:0] slave_0_addr,
    output  [ADDR_SIZE-1:0] slave_1_addr,
    
    output                  slave_0_cmd,
    output                  slave_1_cmd,

    output [WDATA_SIZE-1:0] slave_0_wdata,
    output [WDATA_SIZE-1:0] slave_1_wdata,

    input                   slave_0_ack,
    input                   slave_1_ack,

    input  [RDATA_SIZE-1:0] slave_0_rdata,
    input  [RDATA_SIZE-1:0] slave_1_rdata,

    input                   reset_n,
    input                   clk
);

    // regs decode st
    logic [ADDR_SIZE-1:0]  master_0_addr_st_decode;
    logic [ADDR_SIZE-1:0]  master_1_addr_st_decode;
    logic                  master_0_cmd_st_decode;
    logic                  master_1_cmd_st_decode;
    logic [WDATA_SIZE-1:0] master_0_wdata_st_decode;
    logic [WDATA_SIZE-1:0] master_1_wdata_st_decode;

    logic       m0_to_s0_req_st_decode;
    logic       m0_to_s1_req_st_decode;
    logic       m1_to_s0_req_st_decode;
    logic       m1_to_s1_req_st_decode;

    //regs arbitrage st
    logic [ADDR_SIZE-1:0]  master_0_addr_st_arbitrage;
    logic [ADDR_SIZE-1:0]  master_1_addr_st_arbitrage;
    logic                  master_0_cmd_st_arbitrage;
    logic                  master_1_cmd_st_arbitrage;
    logic [WDATA_SIZE-1:0] master_0_wdata_st_arbitrage;
    logic [WDATA_SIZE-1:0] master_1_wdata_st_arbitrage;

    logic [1:0] grants_to_slave_0_st_arbitrage;
    logic [1:0] grants_to_slave_1_st_arbitrage;

    
    // inputs/outputs of arbiter
    logic [1:0] reqs_to_slave_0;
    logic [1:0] reqs_to_slave_1;
    logic [1:0] grants_to_slave_0;
    logic [1:0] grants_to_slave_1;


//   assign slave_0_req    = master_0_req;
//   assign slave_0_addr   = master_0_addr;
//   assign slave_0_cmd    = master_0_cmd;
//   assign slave_0_wdata  = master_0_wdata;
//   assign master_0_ack   = slave_0_ack;
//   assign master_0_rdata = slave_0_rdata;
//   
//   assign slave_1_req    = master_1_req;
//   assign slave_1_addr   = master_1_addr;
//   assign slave_1_cmd    = master_1_cmd;
//   assign slave_1_wdata  = master_1_wdata;
//   assign master_1_ack   = slave_1_ack;
//   assign master_1_rdata = slave_1_rdata;

//decoder 

always_ff @( posedge clk or negedge reset_n ) begin : st_decode
    if ( reset_n ) begin
        m0_to_s0_req_st_decode <= '0;
        m0_to_s1_req_st_decode <= '0;
        m1_to_s0_req_st_decode <= '0;
        m1_to_s1_req_st_decode <= '0;

        master_0_addr_st_decode  <= '0;
        master_1_addr_st_decode  <= '0;
        master_0_cmd_st_decode   <= '0;
        master_1_cmd_st_decode   <= '0;
        master_0_wdata_st_decode <= '0;
        master_1_wdata_st_decode <= '0;
    end else begin
        m0_to_s0_req_st_decode <= master_0_req & ~master_0_addr[31];
        m0_to_s1_req_st_decode <= master_0_req &  master_0_addr[31];
        m1_to_s0_req_st_decode <= master_1_req & ~master_1_addr[31];
        m1_to_s1_req_st_decode <= master_1_req &  master_1_addr[31];

        master_0_addr_st_decode  <= master_0_addr;
        master_1_addr_st_decode  <= master_1_addr;
        master_0_cmd_st_decode   <= master_0_cmd;
        master_1_cmd_st_decode   <= master_1_cmd;
        master_0_wdata_st_decode <= master_0_wdata;
        master_1_wdata_st_decode <= master_1_wdata;
    end
end


//    assign m0_to_s0_req = master_0_req & ~master_0_addr[31];
//    assign m0_to_s1_req = master_0_req &  master_0_addr[31];
//    assign m1_to_s0_req = master_1_req & ~master_1_addr[31];
//    assign m1_to_s1_req = master_1_req &  master_1_addr[31];

//

assign reqs_to_slave_0 = { m1_to_s0_req_st_decode, 
                           m0_to_s0_req_st_decode };

assign reqs_to_slave_1 = { m1_to_s1_req_st_decode, 
                           m0_to_s1_req_st_decode };
 //arbiter

round_robin_arbiter arb0 (

    .reset_n  ( reset_n           ),
    .clk      ( clk               ),
     
    .requests ( reqs_to_slave_0   ),
    .grants   ( grants_to_slave_0 )

);

round_robin_arbiter arb1 (

    .reset_n  ( reset_n           ),
    .clk      ( clk               ),
     
    .requests ( reqs_to_slave_1   ),
    .grants   ( grants_to_slave_1 )

);


always_ff @( posedge clk or negedge reset_n ) begin : st_arbitrage
    if ( reset_n ) begin
        grants_to_slave_0_st_arbitrage <= '0;
        grants_to_slave_1_st_arbitrage <= '0;

        master_0_addr_st_arbitrage  <= '0;
        master_1_addr_st_arbitrage  <= '0;
        master_0_cmd_st_arbitrage   <= '0;
        master_1_cmd_st_arbitrage   <= '0;
        master_0_wdata_st_arbitrage <= '0;
        master_1_wdata_st_arbitrage <= '0;
    end else begin
        grants_to_slave_0_st_arbitrage <= grants_to_slave_0;
        grants_to_slave_1_st_arbitrage <= grants_to_slave_1;

        master_0_addr_st_arbitrage  <= master_0_addr_st_decode;
        master_1_addr_st_arbitrage  <= master_1_addr_st_decode;
        master_0_cmd_st_arbitrage   <= master_0_cmd_st_decode;
        master_1_cmd_st_arbitrage   <= master_1_cmd_st_decode;
        master_0_wdata_st_arbitrage <= master_0_wdata_st_decode;
        master_1_wdata_st_arbitrage <= master_1_wdata_st_decode;
    end
end


////////////////////////////mux


assign slave_0_req    = grants_to_slave_0[1] & master_1_req  
                      | grants_to_slave_0[0] & master_0_req;  
  
assign slave_1_req    = grants_to_slave_1[1] & master_1_req
                      | grants_to_slave_1[0] & master_0_req;
//assign slave_0_req    = | grants_to_slave_0;
//assign slave_1_req    = | grants_to_slave_1;
  
assign slave_0_addr   = grants_to_slave_0[1] ? master_1_addr 
                      : grants_to_slave_0[0] ? master_0_addr
                      :                        32'b0;
  
assign slave_1_addr   = grants_to_slave_1[1] ? master_1_addr 
                      : grants_to_slave_1[0] ? master_0_addr
                      :                        32'b0;
 
 
assign slave_0_cmd    = grants_to_slave_0[1] & master_1_cmd
                      | grants_to_slave_0[0] & master_0_cmd;
                      
                      
assign slave_1_cmd    = grants_to_slave_1[1] & master_1_cmd
                      | grants_to_slave_1[0] & master_0_cmd;
 
 
assign slave_0_wdata  = grants_to_slave_0[1] ? master_1_wdata
                      : grants_to_slave_0[0] ? master_0_wdata
                      :                        32'b0;
 
assign slave_1_wdata  = grants_to_slave_1[1] ? master_1_wdata
                      : grants_to_slave_1[0] ? master_0_wdata
                      :                        32'b0;

// сделать регистр с запомнинанием, чтобы он отправлял на нужный мастер обратно чтение
assign master_0_ack   = grants_to_slave_1[0] & slave_1_ack
                      | grants_to_slave_0[0] & slave_0_ack;

assign master_1_ack   = grants_to_slave_1[1] & slave_1_ack
                      | grants_to_slave_0[1] & slave_0_ack;


assign master_1_rdata = grants_to_slave_1[1] ? slave_1_rdata
                      : grants_to_slave_0[1] ? slave_0_rdata
                                             : 32'b0;

assign master_0_rdata = grants_to_slave_1[0] ? slave_1_rdata 
                      : grants_to_slave_0[0] ? slave_0_rdata
                                             : 32'b0; 


endmodule