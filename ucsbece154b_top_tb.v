module ucsbece154b_top_tb ();

// Clock generation (2ns period for faster simulation)
reg clk = 1;
always #1 clk = ~clk;
reg reset;

// Instantiate DUT with configurable parameters
ucsbece154b_top #(
    .NUM_BTB_ENTRIES(32),
    .NUM_GHR_BITS(5)
) top (
    .clk(clk),
    .reset(reset)
);

// Register file connections
wire [31:0] reg_t3 = top.riscv.dp.rf.t3;

// Performance counters
reg [31:0] cycle_count;
reg [31:0] instruction_count;
reg [31:0] jump_count;
reg [31:0] jump_mispredict_count;
reg [31:0] branch_count;
reg [31:0] branch_mispredict_count;

// Prediction monitoring
wire is_branch = (top.riscv.dp.op_o == top.riscv.dp.instr_branch_op);
wire is_jump = (top.riscv.dp.op_o == top.riscv.dp.instr_jal_op) || 
               (top.riscv.dp.op_o == top.riscv.dp.instr_jalr_op);
wire predicted_taken = top.riscv.dp.BranchTakenF;
wire actual_taken = top.riscv.c.PCSrcE_o;

// Output file for data collection
integer results_file;
initial begin
    results_file = $fopen("performance_results.csv");
    $fdisplay(results_file, "Cycles,Instructions,Jumps,JumpMisses,Branches,BranchMisses,CPI,JumpMissRate,BranchMissRate");
end

initial begin
    $display("=== Starting Performance Analysis ===");
    
    // Initialize counters
    cycle_count = 0;
    instruction_count = 0;
    jump_count = 0;
    jump_mispredict_count = 0;
    branch_count = 0;
    branch_mispredict_count = 0;
    
    // Reset sequence
    reset = 1;
    #4;
    reset = 0;
    
    // Main simulation loop
    while (cycle_count < 1000 && reg_t3 !== 10) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Instruction count (approximate)
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
        
        // Periodic reporting
        if (cycle_count % 100 == 0) begin
            $display("Cycle: %d, t3: %d", cycle_count, reg_t3);
            // Write intermediate results
            $fdisplay(results_file, "%d,%d,%d,%d,%d,%d,%f,%f,%f",
                cycle_count,
                instruction_count,
                jump_count,
                jump_mispredict_count,
                branch_count,
                branch_mispredict_count,
                $itor(cycle_count)/$itor(instruction_count),
                (jump_count > 0) ? ($itor(jump_mispredict_count)/$itor(jump_count)) : 0,
                (branch_count > 0) ? ($itor(branch_mispredict_count)/$itor(branch_count)) : 0);
        end
    end
    
    // Final results
    $display("\n=== Final Performance Metrics ===");
    $display("Total cycles: %d", cycle_count);
    $display("Instructions: %d", instruction_count);
    $display("CPI: %f", $itor(cycle_count)/$itor(instruction_count));
    
    if (jump_count > 0) begin
        $display("Jumps: %d (Miss Rate: %0.1f%%)", 
               jump_count, 
               100.0*$itor(jump_mispredict_count)/$itor(jump_count));
    end
    
    if (branch_count > 0) begin
        $display("Branches: %d (Miss Rate: %0.1f%%)", 
               branch_count,
               100.0*$itor(branch_mispredict_count)/$itor(branch_count));
    end
    
    // Write final results
    $fdisplay(results_file, "%d,%d,%d,%d,%d,%d,%f,%f,%f",
        cycle_count,
        instruction_count,
        jump_count,
        jump_mispredict_count,
        branch_count,
        branch_mispredict_count,
        $itor(cycle_count)/$itor(instruction_count),
        (jump_count > 0) ? ($itor(jump_mispredict_count)/$itor(jump_count)) : 0,
        (branch_count > 0) ? ($itor(branch_mispredict_count)/$itor(branch_count)) : 0);
    
    $fclose(results_file);
    $display("\nResults saved to performance_results.csv");
    $finish;
end

// Waveform dumping
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
end

endmodule