module ucsbece154b_top_tb();

// Clock generation (10ns period -> 100MHz)
reg clk = 1;
always #5 clk = ~clk;
reg reset;

// Instantiate DUT
ucsbece154b_top top(
    .clk(clk),
    .reset(reset)
);

// Register file connections
wire [31:0] s0 = top.riscv.dp.rf.s0;  // countx
wire [31:0] s1 = top.riscv.dp.rf.s1;  // county
wire [31:0] s2 = top.riscv.dp.rf.s2;  // countz
wire [31:0] s3 = top.riscv.dp.rf.s3;  // innercount
wire [31:0] t3 = top.riscv.dp.rf.t3;  // outer loop counter

// Performance counters
reg [31:0] cycle_count;
reg [31:0] instr_count;
reg [31:0] branch_count;
reg [31:0] branch_mispredict_count;
reg [31:0] jump_count;
reg [31:0] jump_mispredict_count;
reg [31:0] btb_hit_count;
reg [31:0] btb_miss_count;

// Branch predictor monitoring
wire is_branch = (top.riscv.dp.op_o == 7'b1100011);
wire is_jump = ((top.riscv.dp.op_o == 7'b1101111) ||  // JAL
                (top.riscv.dp.op_o == 7'b1100111));   // JALR
wire branch_resolved = is_branch && top.riscv.c.PCSrcE;
wire branch_mispredict = is_branch && 
                        (top.riscv.c.PCSrcE != top.riscv.dp.BranchTakenF);
wire jump_mispredict = is_jump && !top.riscv.dp.BranchTakenF;
wire btb_hit = top.riscv.dp.BranchTakenF && 
              (top.riscv.dp.BTBtargetF != (top.riscv.dp.PCF_o + 4));

// Track pipeline stages
reg [31:0] pc_f, pc_d, pc_e, pc_m, pc_w;
always @(posedge clk) begin
    pc_f <= top.riscv.dp.PCF_o;
    pc_d <= top.riscv.dp.PCD;
    pc_e <= top.riscv.dp.PCE;
    pc_m <= {top.riscv.dp.ALUResultM_o[31:1], 1'b0}; // Word-aligned
    pc_w <= top.riscv.dp.PCPlus4W - 4;
end

initial begin
    $display("=== Starting Simulation ===");
    $dumpfile("waveform.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
    
    // Initialize counters
    cycle_count = 0;
    instr_count = 0;
    branch_count = 0;
    branch_mispredict_count = 0;
    jump_count = 0;
    jump_mispredict_count = 0;
    btb_hit_count = 0;
    btb_miss_count = 0;
    
    // Reset sequence
    reset = 1;
    #20;  // 2 clock cycles
    reset = 0;
    $display("Reset released at %0t ns", $time);
    
    // Create performance log file
    $display("Creating performance log file...");
    $writememh("performance_log.txt", {32'b0}); // Create empty file
    
    // Main simulation loop
    while (cycle_count < 1000) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Count instructions (retired in WB stage)
        if (top.riscv.c.RegWriteW && !reset && cycle_count > 2)
            instr_count = instr_count + 1;
        
        // Count branches and mispredictions
        if (is_branch && !reset && pc_e != 0) begin
            branch_count = branch_count + 1;
            if (branch_mispredict)
                branch_mispredict_count = branch_mispredict_count + 1;
        end
        
        // Count jumps and mispredictions
        if (is_jump && !reset && pc_e != 0) begin
            jump_count = jump_count + 1;
            if (jump_mispredict)
                jump_mispredict_count = jump_mispredict_count + 1;
        end
        
        // Count BTB hits/misses
        if ((is_branch || is_jump) && !reset && pc_f != 0) begin
            if (btb_hit)
                btb_hit_count = btb_hit_count + 1;
            else
                btb_miss_count = btb_miss_count + 1;
        end
        
        // Log performance data every 10 cycles
        if (cycle_count % 10 == 0) begin
            $display("Cycle %0d: PC=%h, Instr=%h", cycle_count, pc_f, top.riscv.dp.InstrF_i);
            $writememh("performance_log.txt", 
                       {cycle_count, 
                        instr_count,
                        branch_count,
                        branch_mispredict_count,
                        jump_count,
                        jump_mispredict_count,
                        btb_hit_count,
                        btb_miss_count});
        end
        
        // Exit when we reach the END label (PC stops changing)
        if (pc_f == 32'h0000003C) begin  // END label address
            $display("Reached END label at cycle %0d", cycle_count);
            #20; // Let final writes complete
            break;
        end
        
        // Safety timeout
        if (cycle_count >= 999) begin
            $display("Warning: Simulation timeout at cycle %0d", cycle_count);
            break;
        end
    end
    
    // Final performance report
    $display("\n=== Simulation Complete ===");
    $display("Total cycles: %0d", cycle_count);
    $display("Instructions retired: %0d", instr_count);
    $display("CPI: %f", real'(cycle_count)/real'(instr_count));
    $display("\nBranch Predictor Statistics:");
    $display("Branches executed: %0d", branch_count);
    $display("Branch mispredictions: %0d", branch_mispredict_count);
    $display("Branch misprediction rate: %f%%", 
             100.0*real'(branch_mispredict_count)/real'(branch_count));
    $display("\nJump Predictor Statistics:");
    $display("Jumps executed: %0d", jump_count);
    $display("Jump mispredictions: %0d", jump_mispredict_count);
    $display("Jump misprediction rate: %f%%", 
             100.0*real'(jump_mispredict_count)/real'(jump_count));
    $display("\nBTB Statistics:");
    $display("BTB hits: %0d", btb_hit_count);
    $display("BTB misses: %0d", btb_miss_count);
    $display("BTB hit rate: %f%%", 
             100.0*real'(btb_hit_count)/real'(btb_hit_count + btb_miss_count));
    $display("\nFinal Register Values:");
    $display("countx (s0): %0d", s0);
    $display("county (s1): %0d", s1);
    $display("countz (s2): %0d", s2);
    $display("innercount (s3): %0d", s3);
    $display("outer (t3): %0d", t3);
    
    // Write final performance data
    $writememh("performance_log.txt", 
               {cycle_count, 
                instr_count,
                branch_count,
                branch_mispredict_count,
                jump_count,
                jump_mispredict_count,
                btb_hit_count,
                btb_miss_count});
    
    $finish;
end

// Monitor pipeline and branch predictor behavior
always @(posedge clk) begin
    if (!reset && cycle_count > 2) begin
        // Log branch predictor decisions
        if (is_branch || is_jump) begin
            $display("BP Decision: PC=%h, Predicted=%b, Actual=%b, Target=%h", 
                    pc_e,
                    top.riscv.dp.BranchTakenF,
                    top.riscv.c.PCSrcE,
                    top.riscv.dp.PCTargetE);
        end
        
        // Log pipeline stages for debugging
        $display("Pipeline: F=%h, D=%h, E=%h, M=%h, W=%h",
                pc_f, pc_d, pc_e, pc_m, pc_w);
    end
end

endmodule