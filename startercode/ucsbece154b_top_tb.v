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
            $stop;
end

endmodule