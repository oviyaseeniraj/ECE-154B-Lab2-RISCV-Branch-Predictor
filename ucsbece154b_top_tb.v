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
// ... [keep all your existing register aliases] ...

// Performance counters
integer cycle_count;
integer branch_count, branch_miss_count;
integer jump_count, jump_miss_count;

reg [31:0] last_instr = 32'h00000013; // "addi x0, x0, 0"
reg [31:0] last_pc = 0;
integer pc_stable_cycles = 0;

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

        // Check for program termination (PC stops changing)
        if (top.riscv.dp.PCF == last_pc) begin
            pc_stable_cycles = pc_stable_cycles + 1;
            if (pc_stable_cycles > 5) begin // PC stable for 5 cycles
                $display("Program terminated. Ending simulation...");
                $display("Final PC: 0x%h", last_pc);
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
        end else begin
            pc_stable_cycles = 0;
            last_pc = top.riscv.dp.PCF;
        end

        // EXECUTE stage inspection (keep your existing code)
        if (!reset) begin
            case (top.riscv.dp.op_o)
                7'b1100011: begin // branch
                    branch_count = branch_count + 1;
                    if (top.riscv.dp.BranchTakenF != top.riscv.dp.ZeroE_o)
                        branch_miss_count = branch_miss_count + 1;
                end
                7'b1101111, 7'b1100111: begin // jal / jalr
                    jump_count = jump_count + 1;
                    if (!top.riscv.dp.BranchTakenF)
                        jump_miss_count = jump_miss_count + 1;
                end
            endcase
        end
    end
end

endmodule

`undef ASSERT