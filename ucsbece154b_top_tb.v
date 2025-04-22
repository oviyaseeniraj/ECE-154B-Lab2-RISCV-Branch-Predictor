module ucsbece154b_top_tb ();

// Clock generation (2ns period for faster simulation)
reg clk = 1;
always #1 clk = ~clk;
reg reset;

// Instantiate DUT with configurable parameters
// Simple instantiation without parameters
ucsbece154b_top top (
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
wire is_branch = top.riscv.dp.is_branchE;
wire is_jump = top.riscv.dp.is_jumpE;
wire predicted_taken = top.riscv.dp.BranchTakenD;
wire actual_taken = top.riscv.c.PCSrcE_o;

// Pipeline tracking registers
reg is_branch_prev, is_jump_prev;
reg predicted_taken_prev;
reg [31:0] pc_prev;

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
    is_branch_prev = 0;
    is_jump_prev = 0;
    predicted_taken_prev = 0;
    pc_prev = 0;
    
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
        
        // Track instructions through pipeline
        is_branch_prev <= is_branch;
        is_jump_prev <= is_jump;
        predicted_taken_prev <= predicted_taken;
        pc_prev <= top.riscv.dp.PCF_o;
        
        // Check mispredictions one cycle after Execute
        if (is_branch_prev) begin
            branch_count <= branch_count + 1;
            if (actual_taken !== predicted_taken_prev) begin
                branch_mispredict_count <= branch_mispredict_count + 1;
                $display("Branch misprediction at PC %h: Predicted %b, Actual %b",
                         pc_prev, predicted_taken_prev, actual_taken);
            end
        end
        
        if (is_jump_prev) begin
            jump_count <= jump_count + 1;
            if (actual_taken !== predicted_taken_prev) begin
                jump_mispredict_count <= jump_mispredict_count + 1;
                $display("Jump misprediction at PC %h: Predicted %b, Actual %b",
                         pc_prev, predicted_taken_prev, actual_taken);
            end
        end
        
        // Debug prints
        if (is_branch) begin
            $display("Cycle %d: Branch at PC %h: Predicted %b", 
                    cycle_count, top.riscv.dp.PCF_o, predicted_taken);
        end
        if (is_jump) begin
            $display("Cycle %d: Jump at PC %h: Predicted %b", 
                    cycle_count, top.riscv.dp.PCF_o, predicted_taken);
        end
        if (actual_taken) begin
            $display("Cycle %d: Taken at PC %h", 
                    cycle_count, top.riscv.dp.PCE);
        end
        
        // Predictor update debug
        if (top.riscv.dp.PHTweE) begin
            $display("Cycle %d: Updating PHT[%h] to %b (increment: %b)",
                    cycle_count,
                    top.riscv.dp.branch.PHTwriteaddress_i,
                    top.riscv.dp.branch.PHT[top.riscv.branch.PHTwriteaddress_i],
                    top.riscv.dp.PHTincrementE);
        end
        if (top.riscv.dp.branch.BTB_we) begin
            $display("Cycle %d: Updating BTB[%h] with target %h",
                    cycle_count,
                    top.riscv.dp.branch.BTBwriteaddress_i,
                    top.riscv.dp.branch.BTBwritedata_i);
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