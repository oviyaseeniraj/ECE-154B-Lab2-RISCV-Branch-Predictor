`define SIM

`define ASSERT(CONDITION, MESSAGE) if ((CONDITION)==1'b1); else begin $error($sformatf MESSAGE); end

module ucsbece154b_top_tb ();

reg clk = 1;
always #1 clk <= ~clk;
reg reset;

ucsbece154b_top top (
    .clk(clk), .reset(reset)
);

// Register aliases
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
wire [31:0] reg_s2 = top.riscv.dp.rf.s2;
wire [31:0] reg_s3 = top.riscv.dp.rf.s3;
wire [31:0] reg_a1 = top.riscv.dp.rf.a1;

// Performance counters
integer cycle_count;
integer branch_count, branch_miss_count;
integer jump_count, jump_miss_count;

reg [31:0] last_instr = 32'h00000013; // "addi x0, x0, 0"

initial begin
    $display("Begin simulation.");

    reset = 1;
    cycle_count = 0;
    branch_count = 0;
    branch_miss_count = 0;
    jump_count = 0;
    jump_miss_count = 0;

    @(negedge clk); 
    @(negedge clk);
    reset = 0;

    forever begin
        @(negedge clk);
        cycle_count = cycle_count + 1;

        // EXECUTE stage inspection
        // Top path: top.riscv.dp contains all signals

        if (!reset) begin
            // Check op code in Execute stage (InstrD delayed)
            case (top.riscv.dp.op_o)
                7'b1100011: begin // branch
                    branch_count = branch_count + 1;
                    if (top.riscv.dp.BranchTakenF != top.riscv.dp.ZeroE_o) // predicted != actual
                        branch_miss_count = branch_miss_count + 1;
                end
                7'b1101111, 7'b1100111: begin // jal / jalr
                    jump_count = jump_count + 1;
                    if (top.riscv.dp.op_o == 7'b1101111 || top.riscv.dp.op_o == 7'b1100111) begin
                        jump_count = jump_count + 1;
                        if (!top.riscv.dp.BranchTakenF) // jump not predicted taken
                            jump_miss_count = jump_miss_count + 1;
                    end

                end
            endcase
        end

        // Stop condition: loop ends when t0 == 16
        if (reg_t0 == reg_t1) begin
            $display("Final iteration completed. Ending simulation...");
            $display("Cycle count:            %0d", cycle_count);
            $display("Branch count:           %0d", branch_count);
            $display("Branch mispredictions:  %0d", branch_miss_count);
            $display("Jump count:             %0d", jump_count);
            $display("Jump mispredictions:    %0d", jump_miss_count);

            if (branch_count > 0)
                $display("Branch misprediction rate: %0f%%", 100.0 * branch_miss_count / branch_count);
            if (jump_count > 0)
                $display("Jump misprediction rate:   %0f%%", 100.0 * jump_miss_count / jump_count);
            $stop;
        end

    end
end

endmodule

`undef ASSERT
