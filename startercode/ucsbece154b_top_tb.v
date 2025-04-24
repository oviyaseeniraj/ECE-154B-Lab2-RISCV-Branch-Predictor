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

reg op_e;

always @(posedge clk) begin
    if (reset) begin
        op_e <= 0;
    end else begin
        // propagate op to execute stage
        op_e <= top.riscv.dp.op_o;
    end
end

integer i;
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

    for (i = 0; i < 500 && top.riscv.dp.PCF_o != 32'h00010064; i = i + 1) begin
        @(posedge clk);

        if (op_e == 7'b1100011) begin
            branch_count = branch_count + 1;
            if (top.riscv.dp.PCSrcE_i) begin
                branch_miss_count = branch_miss_count + 1;
            end
        end else if (op_e == 7'b1101111 || op_e == 7'b1100111) begin
            jump_count = jump_count + 1;
            if (top.riscv.dp.PCSrcE_i) begin
                jump_miss_count = jump_miss_count + 1;
            end
        end

        cycle_count = cycle_count + 1;

        if (!reset && top.riscv.dp.InstrD !== 32'b0) begin
            instruction_count = instruction_count + 1;
        end
    end

            $display("--------------------------");
            $display("Performance:");
            $display("Cycle count:            %0d", cycle_count);
            $display("Instruction count:      %0d", instruction_count);
            $display("CPI:                    %0f", 1.0 * cycle_count / instruction_count);
            $display("Branch count:           %0d", branch_count);
            $display("Branch misprediction:   %0d", branch_miss_count);
            $display("Branch misprediction rate: %0f%%", 100.0 * branch_miss_count / branch_count);
            $display("Jump count:             %0d", jump_count);
            $display("Jump misprediction:     %0d", jump_miss_count);
            $display("Jump misprediction rate: %0f%%", 100.0 * jump_miss_count / jump_count);
            $stop;
end

endmodule