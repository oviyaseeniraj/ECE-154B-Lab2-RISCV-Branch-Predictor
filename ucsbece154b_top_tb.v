`define SIM

module ucsbece154b_top_tb ();

reg clk = 1;
always #1 clk <= ~clk;
reg reset;

ucsbece154b_top top (
    .clk(clk), .reset(reset)
);

wire [31:0] reg_s0 = top.riscv.dp.rf.s0;
wire [31:0] reg_s1 = top.riscv.dp.rf.s1;
wire [31:0] reg_s2 = top.riscv.dp.rf.s2;
wire [31:0] reg_s3 = top.riscv.dp.rf.s3;
wire [31:0] reg_t0 = top.riscv.dp.rf.t0;
wire [31:0] reg_t1 = top.riscv.dp.rf.t1;
wire [31:0] reg_t2 = top.riscv.dp.rf.t2;
wire [31:0] reg_t3 = top.riscv.dp.rf.t3;
wire [31:0] reg_t4 = top.riscv.dp.rf.t4;
wire [31:0] reg_t5 = top.riscv.dp.rf.t5;
wire [31:0] reg_t6 = top.riscv.dp.rf.t6;

integer cycle_count;
integer instruction_count;
integer branch_count, branch_miss_count;
integer jump_count, jump_miss_count;

reg BranchTakenD, BranchTakenE;
reg [31:0] BranchPCD, BranchPCE;
reg mispredicted;

integer i;

always @(posedge clk) begin
    if (reset) begin
        BranchTakenD <= 0;
        BranchTakenE <= 0;
        BranchPCD <= 0;
        BranchPCE <= 0;
    end else begin
        // Capture prediction in Decode stage
        BranchTakenD <= top.riscv.dp.BranchTakenF;
        BranchPCD <= top.riscv.dp.PCF_o;
        
        // Propagate to Execute stage
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

    for (i = 0; i < 10000; i = i + 1) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;

        if (!reset && top.riscv.dp.InstrD !== 32'b0) begin
            instruction_count = instruction_count + 1;

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

            // case (top.riscv.dp.opE)
            //     instr_branch_op: begin // branch
            //         branch_count = branch_count + 1;

            //         // case (top.riscv.dp.funct3E)
            //         //     3'b000: mispredicted = (BranchTakenE !== top.riscv.dp.ZeroE_o);  // beq
            //         //     3'b001: mispredicted = (BranchTakenE !== ~top.riscv.dp.ZeroE_o); // bne
            //         //     default: mispredicted = 0;
            //         // endcase

            //         if (top.riscv.dp.Mispredict_o)
            //             branch_miss_count = branch_miss_count + 1;

            //         $display("[BRANCH] PC=%h TakenE=%b ZeroE=%b funct3=%b MISP=%b", 
            //             BranchPCE, BranchTakenE, top.riscv.dp.ZeroE_o,
            //             top.riscv.dp.funct3E, top.riscv.dp.Mispredict_o);
            //     end
            //     instr_jal_op, instr_jalr_op: begin // jal / jalr
            //         jump_count = jump_count + 1;
            //         if (!BranchTakenE)
            //             jump_miss_count = jump_miss_count + 1;
            //         $display("[JUMP] PC=%h TakenF=%b MISP=%b", 
            //             BranchPCE, BranchTakenE, !BranchTakenE);
            //     end
            // endcase
        end
    end

    $display("---- PROGRAM COMPLETE ----");
    $display("Register values:");
    $display("s0 (countx)      = %0d", reg_s0);
    $display("s1 (county)      = %0d", reg_s1);
    $display("s2 (countz)      = %0d", reg_s2);
    $display("s3 (innercount)  = %0d", reg_s3);
    $display("t0 = %0d", reg_t0);
    $display("t1 = %0d", reg_t1);
    $display("t2 = %0d", reg_t2);
    $display("t3 = %0d", reg_t3);
    $display("t4 = %0d", reg_t4);
    $display("t5 = %0d", reg_t5);
    $display("t6 = %0d", reg_t6);
    $display("--------------------------");
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
