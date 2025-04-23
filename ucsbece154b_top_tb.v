`define SIM

module ucsbece154b_top_tb ();

reg clk = 1;
always #1 clk <= ~clk;
reg reset;

ucsbece154b_top top (
    .clk(clk), .reset(reset)
);

// Performance counters
integer cycle_count;
integer instruction_count;
integer branch_count, branch_miss_count;
integer jump_count, jump_miss_count;

// Pipeline state tracking
reg BranchTakenD, BranchTakenE;
reg [31:0] BranchPCD, BranchPCE;

always @(posedge clk) begin
    if (reset) begin
        BranchTakenD <= 0;
        BranchTakenE <= 0;
        BranchPCD <= 0;
        BranchPCE <= 0;
    end else begin
        // Track prediction through pipeline
        BranchTakenD <= top.riscv.dp.BranchTakenF;
        BranchPCD <= top.riscv.dp.PCF_o;
        BranchTakenE <= BranchTakenD;
        BranchPCE <= BranchPCD;
    end
end

initial begin
    $display("Begin simulation.");

    reset = 1;
    cycle_count = 0;
    instruction_count = 0;
    branch_count = 0;
    branch_miss_count = 0;
    jump_count = 0;
    jump_miss_count = 0;

    @(posedge clk);
    @(posedge clk);
    reset = 0;

    // Run simulation
    for (integer i = 0; i < 10000; i = i + 1) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;

        if (!reset && top.riscv.dp.InstrD !== 32'b0) begin
            instruction_count = instruction_count + 1;

            // Track branches and jumps
            if (top.riscv.c.BranchE) begin
                branch_count = branch_count + 1;
                if (top.riscv.dp.Mispredict_o)
                    branch_miss_count = branch_miss_count + 1;
            end

            if (top.riscv.c.JumpE) begin
                jump_count = jump_count + 1;
                if (!BranchTakenE)
                    jump_miss_count = jump_miss_count + 1;
            end
        end
    end

    // Print results
    $display("---- PROGRAM COMPLETE ----");
    $display("Performance:");
    $display("Cycle count:            %0d", cycle_count);
    $display("Instruction count:      %0d", instruction_count);
    $display("CPI:                    %0f", 1.0 * cycle_count / instruction_count);
    $display("Branch count:           %0d", branch_count);
    $display("Branch mispredictions:  %0d", branch_miss_count);
    $display("Branch misprediction rate: %0f%%", 
        (branch_count > 0) ? 100.0 * branch_miss_count / branch_count : 0.0);
    $display("Jump count:             %0d", jump_count);
    $display("Jump mispredictions:    %0d", jump_miss_count);
    $display("Jump misprediction rate:   %0f%%",
        (jump_count > 0) ? 100.0 * jump_miss_count / jump_count : 0.0);
    $stop;
end

endmodule
