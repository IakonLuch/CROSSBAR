module round_robin_arbiter # (

    parameter N = 2

) (

    input  logic         reset_n,
    input  logic         clk,
      
    input  logic [N-1:0] requests,
    output logic [N-1:0] grants

);

logic [1:0] last_win;

always_ff @(posedge clk or negedge reset_n) 
    if (~reset_n) begin
        last_win <= 2'b01;
    end else begin
        if (grants[0])
            last_win <= 2'b01;
        else if (grants[1])
            last_win <= 2'b10;
        else 
            last_win <= last_win;
    end

always_comb 
    case (requests)
        2'b00, 2'b01, 2'b10: grants = requests;
        2'b11:               grants = {requests[1] & ~last_win[1],
                                       requests[0] & ~last_win[0]};
        default:             grants = 2'b00;
    endcase



endmodule

