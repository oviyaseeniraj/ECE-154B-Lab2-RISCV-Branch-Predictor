module ucsbece154b_top_tb();

// Clock generation (10ns period -> 100MHz)
reg clk = 1;
always #5 clk = ~clk;
reg reset;

// Instantiate DUT
ucsbece154b_top top(
    .clk(clk),
    .reset(reset)
);

// Register file connections
wire [31:0] s0 = top.riscv.dp.rf.s0;  // countx
wire [31:0] s1 = top.riscv.dp.rf.s1;  // county
wire [31:0] s2 = top.riscv.dp.rf.s2;  // countz
wire [31:0] s3 = top.riscv.dp.rf.s3;  // innercount
wire [31:0] t3 = top.riscv.dp.rf.t3;  // outer loop counter

// Performance monitoring
reg [31:0] cycle_count;

initial begin
    $display("=== Starting Simulation ===");
    
    // Initialize
    cycle_count = 0;
    
    // Reset sequence
    reset = 1;
    #20;  // 2 clock cycles
    reset = 0;
    
    // Main simulation loop
    while (cycle_count < 1000 && t3 != 10) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Progress reporting
        if (cycle_count % 50 == 0) begin
            $display("Cycle: %d, Outer Loop (t3): %d", cycle_count, t3);
        end
    end
    
    // Final checks
    $display("\n=== Simulation Complete ===");
    $display("Total cycles: %d", cycle_count);
    $display("Final values:");
    $display("countx (s0): %d", s0);
    $display("county (s1): %d", s1);
    $display("countz (s2): %d", s2);
    $display("innercount (s3): %d", s3);
    
    // Expected values based on your assembly code
    $display("\nExpected values:");
    $display("countx (s0): 10 (should equal outer loop iterations)");
    $display("county (s1): 5 (should be half of outer iterations)");
    $display("countz (s2): 5 (x&y when both are 1)");
    $display("innercount (s3): 40 (10 outer * 4 inner)");
    
    // Verification
    if (s0 != 10) $display("ERROR: countx should be 10");
    if (s1 != 5) $display("ERROR: county should be 5");
    if (s2 != 5) $display("ERROR: countz should be 5");
    if (s3 != 40) $display("ERROR: innercount should be 40");
    
    $finish;
end

// Waveform dumping
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
end

endmodule