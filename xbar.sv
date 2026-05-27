module xbar #(

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

    logic       m0_to_s0_req;
    logic       m0_to_s1_req;
    logic       m1_to_s0_req;
    logic       m1_to_s1_req;
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
    assign m0_to_s0_req = master_0_req & ~master_0_addr[31];
    assign m0_to_s1_req = master_0_req &  master_0_addr[31];
    assign m1_to_s0_req = master_1_req & ~master_1_addr[31];
    assign m1_to_s1_req = master_1_req &  master_1_addr[31];

//

assign reqs_to_slave_0 = { m1_to_s0_req, 
                           m0_to_s0_req };

assign reqs_to_slave_1 = { m1_to_s1_req, 
                           m0_to_s1_req };
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