// ucsbece154b_top_tb.v
// Verilog-2001 compatible testbench

`timescale 1ns/1ps

module ucsbece154b_top_tb ();

// Clock generation
reg clk = 1;
always #5 clk = ~clk;  // 100MHz clock
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

// Performance counters
reg [31:0] jump_count;
reg [31:0] jump_mispredict_count;
reg [31:0] branch_count;
reg [31:0] branch_mispredict_count;
reg [31:0] cycle_count;
reg [31:0] instruction_count;

// Prediction monitoring
wire is_branch = (top.riscv.dp.op_o == top.riscv.dp.instr_branch_op);
wire is_jump = (top.riscv.dp.op_o == top.riscv.dp.instr_jal_op) || 
               (top.riscv.dp.op_o == top.riscv.dp.instr_jalr_op);
wire predicted_taken = top.riscv.dp.BranchTakenF;
wire actual_taken = top.riscv.controller.PCSrcE_o;

initial begin
    $display("=== Simulation Start ===");
    
    // Initialize counters
    jump_count = 0;
    jump_mispredict_count = 0;
    branch_count = 0;
    branch_mispredict_count = 0;
    cycle_count = 0;
    instruction_count = 0;
    
    // Reset sequence
    reset = 1;
    #100;
    reset = 0;
    
    // Main monitoring loop
    while (reg_t3 !== 10) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Count instructions (simplified)
        if (!top.riscv.controller.StallF_o) begin
            instruction_count = instruction_count + 1;
        end
        
        // Track predictions in execute stage
        if (top.riscv.controller.FlushE_o) begin
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
    
    // Verification checks
    if (reg_s0 !== 10) $display("ERROR: s0 should be 10, got %d", reg_s0);
    if (reg_s1 !== 5) $display("ERROR: s1 should be 5, got %d", reg_s1);
    if (reg_s2 !== 5) $display("ERROR: s2 should be 5, got %d", reg_s2);
    if (reg_s3 !== 40) $display("ERROR: s3 should be 40, got %d", reg_s3);
    
    // Print performance metrics
    $display("\n=== Performance Metrics ===");
    $display("Total cycles: %d", cycle_count);
    $display("Instructions: %d", instruction_count);
    $display("CPI: %f", $itor(cycle_count)/$itor(instruction_count));
    
    if (jump_count > 0) begin
        $display("Jumps: %d (%0.1f%% mispredict)", 
               jump_count, 
               100.0*$itor(jump_mispredict_count)/$itor(jump_count));
    end
    
    if (branch_count > 0) begin
        $display("Branches: %d (%0.1f%% mispredict)", 
               branch_count,
               100.0*$itor(branch_mispredict_count)/$itor(branch_count));
    end
    
    $display("\n=== Simulation Complete ===");
    $finish;
end

endmodule