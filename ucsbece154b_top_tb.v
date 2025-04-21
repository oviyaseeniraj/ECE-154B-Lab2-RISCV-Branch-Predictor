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
reg [31:0] instruction_count;

// Prediction monitoring
wire is_branch = (top.riscv.dp.op_o == top.riscv.dp.instr_branch_op);
wire is_jump = (top.riscv.dp.op_o == top.riscv.dp.instr_jal_op) || 
               (top.riscv.dp.op_o == top.riscv.dp.instr_jalr_op);
wire predicted_taken = top.riscv.dp.BranchTakenF;
wire actual_taken = top.riscv.c.PCSrcE_o;

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
        
        // Count instructions (simplified)
        if (!top.riscv.c.StallF_o) begin
            instruction_count = instruction_count + 1;
        end
        
        // Track predictions in execute stage
        if (top.riscv.c.FlushE_o) begin
            if (is_jump) begin
                jump_count = jump_count + 1;
                if (actual_taken !== predicted_taken) begin
                    jump_mispredict_count = jump_mispredict_count + 1;
                end
            end
            else if (is_branch) begin
                branch_count = branch_count + 1;
                if (actual_taken !== predicted_taken) begin
                    branch_mispredict_count = branch_mispredict_count + 1;
                end
            end
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