module ucsbece154b_top_tb ();

// Clock generation (2ns period for faster simulation)
reg clk = 1;
always #1 clk = ~clk;  // 500MHz clock for simulation speed
reg reset;

// Instantiate DUT
ucsbece154b_top top (
    .clk(clk),
    .reset(reset)
);

// Register file connections
wire [31:0] reg_zero = top.riscv.dp.rf.zero;
wire [31:0] reg_s0 = top.riscv.dp.rf.s0;
wire [31:0] reg_s1 = top.riscv.dp.rf.s1;
wire [31:0] reg_s2 = top.riscv.dp.rf.s2;
wire [31:0] reg_s3 = top.riscv.dp.rf.s3;
wire [31:0] reg_t0 = top.riscv.dp.rf.t0;
wire [31:0] reg_t3 = top.riscv.dp.rf.t3;

// Performance monitoring
reg [31:0] cycle_count;

initial begin
    $display("=== Simulation Start ===");
    
    // Initialize
    cycle_count = 0;
    
    // Fast reset sequence
    reset = 1;
    #4;  // 2 clock cycles
    reset = 0;
    
    // Main simulation loop (runs for 500ns)
    while (cycle_count < 250) begin  // 250 cycles * 2ns = 500ns
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Early termination if t3 reaches 10
        if (reg_t3 == 10) begin
            $display("Early termination at cycle %d (t3 reached 10)", cycle_count);
            break;
        end
        
        // Progress reporting
        if (cycle_count % 50 == 0) begin
            $display("Cycle: %d, t3: %d", cycle_count, reg_t3);
        end
    end
    
    // Final checks
    $display("\n=== Final Register Values @ %d ns ===", cycle_count*2);
    $display("s0: %d (should be 10)", reg_s0);
    $display("s1: %d (should be 5)", reg_s1);
    $display("s2: %d (should be 5)", reg_s2);
    $display("s3: %d (should be 40)", reg_s3);
    $display("t3: %d (should be 10)", reg_t3);
    
    if (reg_s0 !== 10) $display("ERROR: s0 should be 10");
    if (reg_s1 !== 5) $display("ERROR: s1 should be 5");
    if (reg_s2 !== 5) $display("ERROR: s2 should be 5");
    if (reg_s3 !== 40) $display("ERROR: s3 should be 40");
    if (reg_t3 !== 10) $display("ERROR: t3 should be 10");
    
    $display("\n=== Simulation Complete ===");
    $display("Total simulation time: %d ns", cycle_count*2);
    $finish;
end

// Waveform dumping (limited to 500ns)
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
    #500;  // Limit waveform to 500ns
    $dumpoff;
end

endmodule