// ucsbece154b_top_tb.v
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited

`define SIM
`define ASSERT(CONDITION, MESSAGE) if ((CONDITION)==1'b1); else begin $error($sformatf MESSAGE); end

module ucsbece154b_top_tb ();

// Clock generation
reg clk = 1;
always #1 clk <= ~clk;
reg reset;

// Instantiate DUT
ucsbece154b_top top (
    .clk(clk), 
    .reset(reset)
);

// Register file connections
wire [31:0] reg_zero = top.riscv.dp.rf.zero;
wire [31:0] reg_ra = top.riscv.dp.rf.ra;
wire [31:0] reg_sp = top.riscv.dp.rf.sp;
wire [31:0] reg_gp = top.riscv.dp.rf.gp;
wire [31:0] reg_tp = top.riscv.dp.rf.tp;
wire [31:0] reg_t0 = top.riscv.dp.rf.t0;
wire [31:0] reg_t1 = top.riscv.dp.rf.t1;
wire [31:0] reg_t2 = top.riscv.dp.rf.t2;
wire [31:0] reg_s0 = top.riscv.dp.rf.s0;
wire [31:0] reg_s1 = top.riscv.dp.rf.s1;
wire [31:0] reg_a0 = top.riscv.dp.rf.a0;
wire [31:0] reg_a1 = top.riscv.dp.rf.a1;
wire [31:0] reg_a2 = top.riscv.dp.rf.a2;
wire [31:0] reg_a3 = top.riscv.dp.rf.a3;
wire [31:0] reg_a4 = top.riscv.dp.rf.a4;
wire [31:0] reg_a5 = top.riscv.dp.rf.a5;
wire [31:0] reg_a6 = top.riscv.dp.rf.a6;
wire [31:0] reg_a7 = top.riscv.dp.rf.a7;
wire [31:0] reg_s2 = top.riscv.dp.rf.s2;
wire [31:0] reg_s3 = top.riscv.dp.rf.s3;
wire [31:0] reg_s4 = top.riscv.dp.rf.s4;
wire [31:0] reg_s5 = top.riscv.dp.rf.s5;
wire [31:0] reg_s6 = top.riscv.dp.rf.s6;
wire [31:0] reg_s7 = top.riscv.dp.rf.s7;
wire [31:0] reg_s8 = top.riscv.dp.rf.s8;
wire [31:0] reg_s9 = top.riscv.dp.rf.s9;
wire [31:0] reg_s10 = top.riscv.dp.rf.s10;
wire [31:0] reg_s11 = top.riscv.dp.rf.s11;
wire [31:0] reg_t3 = top.riscv.dp.rf.t3;
wire [31:0] reg_t4 = top.riscv.dp.rf.t4;
wire [31:0] reg_t5 = top.riscv.dp.rf.t5;
wire [31:0] reg_t6 = top.riscv.dp.rf.t6;

// Performance counters
reg [31:0] jump_count;
reg [31:0] jump_mispredict_count;
reg [31:0] branch_count;
reg [31:0] branch_mispredict_count;
reg [31:0] cycle_count;
reg [31:0] instruction_count;

// Prediction signals
wire is_branch = top.riscv.dp.op_o == top.riscv.dp.instr_branch_op;
wire is_jump = (top.riscv.dp.op_o == top.riscv.dp.instr_jal_op) || 
               (top.riscv.dp.op_o == top.riscv.dp.instr_jalr_op);
wire predicted_taken = top.riscv.dp.BranchTakenF;
wire actual_taken = top.riscv.c.PCSrcE_o;

// Main test sequence
integer i;
initial begin
    $display("Begin simulation.");
    
    // Initialize counters
    jump_count = 0;
    jump_mispredict_count = 0;
    branch_count = 0;
    branch_mispredict_count = 0;
    cycle_count = 0;
    instruction_count = 0;
    
    // Reset sequence
    reset = 1;
    @(negedge clk);
    @(negedge clk);
    reset = 0;
    
    // Run simulation
    for (i = 0; i < 200; i=i+1) begin
        @(negedge clk);
        cycle_count = cycle_count + 1;
        
        // Count instructions (simplified)
        if (!top.riscv.controller.StallF_o) begin
            instruction_count = instruction_count + 1;
        end
        
        // Track predictions in execute stage
        if (top.riscv.controller.FlushE_o) begin
            if (is_jump) begin
                jump_count = jump_count + 1;
                if (actual_taken != predicted_taken) begin
                    jump_mispredict_count = jump_mispredict_count + 1;
                end
            end
            else if (is_branch) begin
                branch_count = branch_count + 1;
                if (actual_taken != predicted_taken) begin
                    branch_mispredict_count = branch_mispredict_count + 1;
                end
            end
        end
    end
    
    // Verification assertions
    `ASSERT(reg_t0==32'd1, ("Register t0 (x) should remain 1, got %0d", reg_t0));
    `ASSERT(reg_s0==32'd10, ("Register s0 (countx) should be 10, got %0d", reg_s0));
    `ASSERT(reg_s1==32'd5, ("Register s1 (county) should be 5, got %0d", reg_s1));
    `ASSERT(reg_s2==32'd5, ("Register s2 (countz) should be 5, got %0d", reg_s2));
    `ASSERT(reg_s3==32'd40, ("Register s3 (innercount) should be 40, got %0d", reg_s3));
    `ASSERT(reg_t3==32'd10, ("Register t3 (outer) should be 10, got %0d", reg_t3));
    `ASSERT(reg_zero==32'b0, ("Register zero should remain 0, got %0d", reg_zero));
    
    // Print performance results
    $display("\n=== Branch Prediction Metrics ===");
    $display("Total cycles: %0d", cycle_count);
    $display("Instructions executed: %0d", instruction_count);
    $display("CPI: %.2f", real'(cycle_count)/instruction_count);
    
    if (jump_count > 0) begin
        $display("Jumps: %0d (%0d mispredictions, %.1f%% miss rate)", 
                jump_count, jump_mispredict_count,
                100.0*real'(jump_mispredict_count)/jump_count);
    end
    
    if (branch_count > 0) begin
        $display("Branches: %0d (%0d mispredictions, %.1f%% miss rate)", 
                branch_count, branch_mispredict_count,
                100.0*real'(branch_mispredict_count)/branch_count);
    end
    
    $display("\nEnd simulation.");
    $stop;
end

endmodule

`undef ASSERT