module tb_xbar  #(

    ADDR_SIZE  = 32,
    WDATA_SIZE = 32,
    RDATA_SIZE = 32

) ();

logic clk;
logic reset_n;

logic master_0_req;
logic master_1_req;


logic [ADDR_SIZE-1:0]  master_0_addr;
logic [ADDR_SIZE-1:0]  master_1_addr;

logic                  master_0_cmd;
logic                  master_1_cmd;

logic [WDATA_SIZE-1:0] master_0_wdata;
logic [WDATA_SIZE-1:0] master_1_wdata;

logic                  master_0_ack;
logic                  master_1_ack;

logic [RDATA_SIZE-1:0] master_0_rdata;
logic [RDATA_SIZE-1:0] master_1_rdata;

logic                  slave_0_req;
logic                  slave_1_req;

logic [ADDR_SIZE-1:0]  slave_0_addr;
logic [ADDR_SIZE-1:0]  slave_1_addr;

logic                  slave_0_cmd;
logic                  slave_1_cmd;

logic [WDATA_SIZE-1:0] slave_0_wdata;
logic [WDATA_SIZE-1:0] slave_1_wdata;

logic                  slave_0_ack;
logic                  slave_1_ack;

logic [RDATA_SIZE-1:0] slave_0_rdata;
logic [RDATA_SIZE-1:0] slave_1_rdata;

initial begin
    clk = 0;
end

always #5 clk = ~clk;


xbar dut (

    .master_0_req   ( master_0_req   ),
    .master_1_req   ( master_1_req   ),

    .master_0_addr  ( master_0_addr  ),
    .master_1_addr  ( master_1_addr  ),

    .master_0_cmd   ( master_0_cmd   ),
    .master_1_cmd   ( master_1_cmd   ),

    .master_0_wdata ( master_0_wdata ),
    .master_1_wdata ( master_1_wdata ),

    .master_0_ack   ( master_0_ack   ),
    .master_1_ack   ( master_1_ack   ),

    .master_0_rdata ( master_0_rdata ),
    .master_1_rdata ( master_1_rdata ),

    .slave_0_req    ( slave_0_req    ),    
    .slave_1_req    ( slave_1_req    ),

    .slave_0_addr   ( slave_0_addr   ),
    .slave_1_addr   ( slave_1_addr   ),

    .slave_0_cmd    ( slave_0_cmd    ),
    .slave_1_cmd    ( slave_1_cmd    ),
     
    .slave_0_wdata  ( slave_0_wdata  ),
    .slave_1_wdata  ( slave_1_wdata  ),

    .slave_0_ack    ( slave_0_ack    ),
    .slave_1_ack    ( slave_1_ack    ),

    .slave_0_rdata  ( slave_0_rdata  ),
    .slave_1_rdata  ( slave_1_rdata  ),

    .reset_n        ( reset_n        ),
    .clk            ( clk            )

);

// Slave 0 behaviour model (with write logging)
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        slave_0_ack <= 1'b0;
        slave_0_rdata <= 32'h0;
    end else begin
        slave_0_ack <= slave_0_req;
        if (slave_0_req && !slave_0_cmd) begin
            // Read
            slave_0_rdata <= 32'hDEAD_BEEF;
            $display("@%0t: SLAVE0 READ addr=%h data=DEAD_BEEF", $time, slave_0_addr);
        end
        if (slave_0_req && slave_0_cmd) begin
            // Write
            $display("@%0t: SLAVE0 WRITE addr=%h data=%h", $time, slave_0_addr, slave_0_wdata);
        end
    end
end

// Slave 1 behaviour model (with write logging)
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        slave_1_ack <= 1'b0;
        slave_1_rdata <= 32'h0;
    end else begin
        slave_1_ack <= slave_1_req;
        if (slave_1_req && !slave_1_cmd) begin
            // Read
            slave_1_rdata <= 32'hCAFE_BABE;
            $display("@%0t: SLAVE1 READ addr=%h data=CAFE_BABE", $time, slave_1_addr);
        end
        if (slave_1_req && slave_1_cmd) begin
            // Write
            $display("@%0t: SLAVE1 WRITE addr=%h data=%h", $time, slave_1_addr, slave_1_wdata);
        end
    end
end

//===========================================================
// TEST 1: Master0 reads from Slave0
//===========================================================
task test1_read_m0_slave0();
    $display("\n=== TEST 1: Master0 reads from Slave0 ===");
    
    // Reset
    reset_n = 1'b0;
    master_0_req = 1'b0;
    master_1_req = 1'b0;
    repeat(2) @(posedge clk);
    reset_n = 1'b1;
    repeat(2) @(posedge clk);
    
    // Send request
    master_0_req = 1'b1;
    master_0_cmd = 1'b0;               // read
    master_0_addr = 32'h0000_1234;    // MSB=0 → slave0
    
    @(posedge clk);
    @(negedge clk);
    
    // Check
    if (master_0_ack && (master_0_rdata == 32'hDEAD_BEEF))
        $display("✅ PASS: Master0 read data = %h", master_0_rdata);
    else
        $display("❌ FAIL: Master0 read - ack=%b data=%h", master_0_ack, master_0_rdata);
    
    master_0_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 2: Master0 writes to Slave0
//===========================================================
task test2_write_m0_slave0();
    $display("\n=== TEST 2: Master0 writes to Slave0 ===");
    
    master_0_req = 1'b1;
    master_0_cmd = 1'b1;               // write
    master_0_addr = 32'h0000_5678;    // MSB=0 → slave0
    master_0_wdata = 32'hA5A5_A5A5;
    
    @(posedge clk);
    @(negedge clk);
    
    // Check
    if (master_0_ack && (slave_0_wdata == master_0_wdata))
        $display("✅ PASS: Master0 write - ACK received, data=%h", master_0_wdata);
    else
        $display("❌ FAIL: Master0 write - ack=%b", master_0_ack);
    
    master_0_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 3: Master1 reads from Slave1
//===========================================================
task test3_read_m1_slave1();
    $display("\n=== TEST 3: Master1 reads from Slave1 ===");
    
    master_1_req = 1'b1;
    master_1_cmd = 1'b0;               // read
    master_1_addr = 32'h8000_1234;    // MSB=1 → slave1
    
    @(posedge clk);
    @(negedge clk);
    
    // Check
    if (master_1_ack && (master_1_rdata == 32'hCAFE_BABE))
        $display("✅ PASS: Master1 read data = %h", master_1_rdata);
    else
        $display("❌ FAIL: Master1 read - ack=%b data=%h", master_1_ack, master_1_rdata);
    
    master_1_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 4: Master1 writes to Slave1
//===========================================================
task test4_write_m1_slave1();
    $display("\n=== TEST 4: Master1 writes to Slave1 ===");
    
    master_1_req = 1'b1;
    master_1_cmd = 1'b1;               // write
    master_1_addr = 32'h8000_5678;    // MSB=1 → slave1
    master_1_wdata = 32'h5A5A_5A5A;
    
    @(posedge clk);
    @(negedge clk);
    
    // Check
    if (master_1_ack && (slave_1_wdata == master_1_wdata))
        $display("✅ PASS: Master1 write - ACK received, data=%h", master_1_wdata);
    else
        $display("❌ FAIL: Master1 write - ack=%b", master_1_ack);
    
    master_1_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 5: Parallel reads to different slaves
//===========================================================
task test5_parallel_reads_diff_slaves();
    $display("\n=== TEST 5: Parallel reads to different slaves ===");
    
    master_0_req = 1'b1;
    master_0_cmd = 1'b0;
    master_0_addr = 32'h0000_0000;    // slave0
    
    master_1_req = 1'b1;
    master_1_cmd = 1'b0;
    master_1_addr = 32'h8000_0000;    // slave1
    
    @(posedge clk);
    @(negedge clk);
    
    if (master_0_ack && master_1_ack)
        $display("✅ PASS: Both masters got ACK, m0_data=%h m1_data=%h", master_0_rdata, master_1_rdata);
    else
        $display("❌ FAIL: m0_ack=%b m1_ack=%b", master_0_ack, master_1_ack);
    
    master_0_req = 1'b0;
    master_1_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 6: Conflict on Slave0 – Round‑Robin (reads)
//===========================================================
task test6_conflict_round_robin_reads();
    $display("\n=== TEST 6: Conflict on Slave0 (Round‑Robin reads) ===");
    
    // Both request slave0
    master_0_req = 1'b1;
    master_0_cmd = 1'b0;
    master_0_addr = 32'h0000_1000;
    
    master_1_req = 1'b1;
    master_1_cmd = 1'b0;
    master_1_addr = 32'h0000_2000;
    
    @(posedge clk);
    @(negedge clk);
    
    // After first arbitration, one gets grant, the other not
    if (master_0_ack && !master_1_ack) begin
        $display("✅ First winner: Master0");
        master_0_req = 1'b0;                 // Master0 finishes
        @(posedge clk);
        @(negedge clk);
        if (!master_0_ack && master_1_ack)
            $display("✅ Second winner: Master1 (round‑robin works)");
        else
            $display("❌ FAIL: Second winner unexpected (m0=%b m1=%b)", master_0_ack, master_1_ack);
    end
    else if (!master_0_ack && master_1_ack) begin
        $display("✅ First winner: Master1");
        master_1_req = 1'b0;                 // Master1 finishes
        @(posedge clk);
        @(negedge clk);
        if (master_0_ack && !master_1_ack)
            $display("✅ Second winner: Master0 (round‑robin works)");
        else
            $display("❌ FAIL: Second winner unexpected (m0=%b m1=%b)", master_0_ack, master_1_ack);
    end
    else begin
        $display("❌ FAIL: No clear winner in conflict");
    end
    
    master_0_req = 1'b0;
    master_1_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// TEST 7: Conflict on Slave1 – Round‑Robin (writes)
//===========================================================
task test7_conflict_round_robin_writes();
    $display("\n=== TEST 7: Conflict on Slave1 (Round‑Robin writes) ===");
    
    // Both request slave1 with write
    master_0_req = 1'b1;
    master_0_cmd = 1'b1;                    // write
    master_0_addr = 32'h8000_1000;         // MSB=1 → slave1
    master_0_wdata = 32'h1111_1111;
    
    master_1_req = 1'b1;
    master_1_cmd = 1'b1;                    // write
    master_1_addr = 32'h8000_2000;         // MSB=1 → slave1
    master_1_wdata = 32'h2222_2222;
    
    @(posedge clk);
    @(negedge clk);
    
    // After first arbitration, one gets grant
    if (master_0_ack && !master_1_ack) begin
        $display("✅ First winner: Master0 (write)");
        master_0_req = 1'b0;
        @(posedge clk);
        @(negedge clk);
        if (!master_0_ack && master_1_ack)
            $display("✅ Second winner: Master1 (round‑robin works)");
        else
            $display("❌ FAIL: Second write winner unexpected");
    end
    else if (!master_0_ack && master_1_ack) begin
        $display("✅ First winner: Master1 (write)");
        master_1_req = 1'b0;
        @(posedge clk);
        @(negedge clk);
        if (master_0_ack && !master_1_ack)
            $display("✅ Second winner: Master0 (round‑robin works)");
        else
            $display("❌ FAIL: Second write winner unexpected");
    end
    else begin
        $display("❌ FAIL: No clear winner in write conflict");
    end
    
    master_0_req = 1'b0;
    master_1_req = 1'b0;
    @(posedge clk);
endtask

//===========================================================
// Main test sequence
//===========================================================
initial begin
    $display("========================================");
    $display("     XBAR TESTBENCH – FULL (READ+WRITE)");
    $display("========================================");
    
    // Basic read/write tests
    test1_read_m0_slave0();
    test2_write_m0_slave0();
    test3_read_m1_slave1();
    test4_write_m1_slave1();
    
    // Parallel tests
    test5_parallel_reads_diff_slaves();
    
    // Conflict / Round-robin tests
    test6_conflict_round_robin_reads();
    test7_conflict_round_robin_writes();
    
    $display("\n========================================");
    $display("     ALL TESTS COMPLETED");
    $display("========================================");
    $finish;
end



endmodule 