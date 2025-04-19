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

// Instruction memory debug
wire [31:0] current_pc = top.riscv.dp.PCF_o;
wire [31:0] current_instr = top.riscv.dp.InstrF_i;

// Performance monitoring
reg [31:0] cycle_count;

initial begin
    $display("=== Starting Simulation ===");
    $dumpfile("waveform.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
    
    // Initialize
    cycle_count = 0;
    
    // Reset sequence
    reset = 1;
    #20;  // 2 clock cycles
    reset = 0;
    $display("Reset released at %0t ns", $time);
    
    // Main simulation loop
    while (cycle_count < 1000) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Display PC and instruction
        $display("Cycle %0d: PC = %h, Instr = %h", 
                cycle_count, current_pc, current_instr);
        
        // Exit when we reach the END label (PC stops changing)
        if (current_pc == 32'h0000003C) begin  // Update this to match your END label PC
            $display("Reached END label at cycle %0d", cycle_count);
            #20; // Let final writes complete
            break;
        end
        
        // Safety timeout
        if (cycle_count >= 999) begin
            $display("Warning: Simulation timeout at cycle %0d", cycle_count);
            break;
        end
    end
    
    // Final checks
    $display("\n=== Simulation Complete ===");
    $display("Total cycles: %0d", cycle_count);
    $display("Final values:");
    $display("countx (s0): %0d", s0);
    $display("county (s1): %0d", s1);
    $display("countz (s2): %0d", s2);
    $display("innercount (s3): %0d", s3);
    
    $finish;
end

endmodule