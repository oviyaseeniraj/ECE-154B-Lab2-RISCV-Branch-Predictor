module ucsbece154b_top_tb();

// Clock generation (10ns period -> 100MHz)
reg clk = 1;
always #5 clk = ~clk;
reg reset;

// Experiment parameters
parameter BTB_ENTRIES = 16;
parameter GHR_BITS = 4;

// Instantiate DUT
ucsbece154b_top top(
    .clk(clk),
    .reset(reset)
);

// Performance counters
reg [31:0] cycle_count;
reg [31:0] instr_count;
reg [31:0] branch_count;
reg [31:0] branch_mispredict_count;
reg [31:0] jump_count;
reg [31:0] jump_mispredict_count;
reg [31:0] btb_hit_count;
reg [31:0] btb_miss_count;

// Pipeline registers to track instructions
reg [31:0] pc_f, pc_d, pc_e, pc_m, pc_w;
reg [6:0] op_f, op_d, op_e, op_m, op_w;
reg [31:0] pc_plus4_f, pc_plus4_d, pc_plus4_e, pc_plus4_m, pc_plus4_w;

// Track branch/jump instructions in pipeline
reg is_branch_d, is_branch_e, is_branch_m;
reg is_jump_d, is_jump_e, is_jump_m;
reg branch_taken_f, branch_taken_d, branch_taken_e;
reg btb_hit_f, btb_hit_d, btb_hit_e;

// Branch predictor monitoring signals
wire is_branch = (op_e == 7'b1100011);  // BEQ, BNE, etc.
wire is_jump = ((op_e == 7'b1101111) ||  // JAL
               (op_e == 7'b1100111));    // JALR
wire branch_resolved = is_branch && top.riscv.c.PCSrcE_o;
wire branch_mispredict = is_branch && (top.riscv.c.PCSrcE_o != branch_taken_e);
wire jump_mispredict = is_jump && !branch_taken_e;
wire btb_hit = (branch_taken_f && (top.riscv.dp.BTBtargetF != pc_plus4_f)) ||
               (is_jump && branch_taken_f);

// Update pipeline registers
always @(posedge clk) begin
    if (reset) begin
        pc_f <= 0; pc_d <= 0; pc_e <= 0; pc_m <= 0; pc_w <= 0;
        op_f <= 0; op_d <= 0; op_e <= 0; op_m <= 0; op_w <= 0;
        pc_plus4_f <= 0; pc_plus4_d <= 0; pc_plus4_e <= 0; pc_plus4_m <= 0; pc_plus4_w <= 0;
        is_branch_d <= 0; is_branch_e <= 0; is_branch_m <= 0;
        is_jump_d <= 0; is_jump_e <= 0; is_jump_m <= 0;
        branch_taken_f <= 0; branch_taken_d <= 0; branch_taken_e <= 0;
        btb_hit_f <= 0; btb_hit_d <= 0; btb_hit_e <= 0;
    end else begin
        // Pipeline PC tracking
        pc_f <= top.riscv.dp.PCF_o;
        pc_d <= top.riscv.dp.PCD;
        pc_e <= top.riscv.dp.PCE;
        pc_m <= top.riscv.dp.ALUResultM_o;
        pc_w <= top.riscv.dp.PCPlus4W - 4;
        
        // Pipeline instruction opcode tracking
        op_f <= top.riscv.dp.InstrF_i[6:0];
        op_d <= top.riscv.dp.InstrD[6:0];
        op_e <= top.riscv.dp.InstrE[6:0];
        op_m <= top.riscv.dp.InstrM[6:0];
        op_w <= top.riscv.dp.InstrW[6:0];
        
        // Pipeline PC+4 tracking
        pc_plus4_f <= top.riscv.dp.PCPlus4F;
        pc_plus4_d <= top.riscv.dp.PCPlus4D;
        pc_plus4_e <= top.riscv.dp.PCPlus4E;
        pc_plus4_m <= top.riscv.dp.PCPlus4M;
        pc_plus4_w <= top.riscv.dp.PCPlus4W;
        
        // Branch/jump tracking through pipeline
        is_branch_d <= (top.riscv.dp.InstrD[6:0] == 7'b1100011);
        is_branch_e <= is_branch_d;
        is_branch_m <= is_branch_e;
        
        is_jump_d <= ((top.riscv.dp.InstrD[6:0] == 7'b1101111) || 
                      (top.riscv.dp.InstrD[6:0] == 7'b1100111));
        is_jump_e <= is_jump_d;
        is_jump_m <= is_jump_e;
        
        // Branch prediction tracking through pipeline
        branch_taken_f <= top.riscv.dp.BranchTakenF;
        branch_taken_d <= branch_taken_f;
        branch_taken_e <= branch_taken_d;
        
        btb_hit_f <= btb_hit;
        btb_hit_d <= btb_hit_f;
        btb_hit_e <= btb_hit_d;
    end
end

initial begin
    $display("=== Starting Branch Predictor Stress Test ===");
    $display("Configuration: BTB_ENTRIES=%0d, GHR_BITS=%0d", BTB_ENTRIES, GHR_BITS);
    $dumpfile("branch_predictor.vcd");
    $dumpvars(0, ucsbece154b_top_tb);
    
    // Initialize instruction memory with test program
    $readmemh("test_program.hex", top.riscv.imem.mem);
    
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
    #20;
    reset = 0;
    $display("Reset released at %0t ns", $time);
    
    // Main simulation loop
    while (cycle_count < 1000) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        
        // Instruction counting (count writes to register file)
        if (top.riscv.dp.RegWriteW_i && !reset && cycle_count > 2)
            instr_count = instr_count + 1;
        
        // Branch tracking (check in Execute stage)
        if (is_branch) begin
            branch_count = branch_count + 1;
            
            if (btb_hit_e) btb_hit_count = btb_hit_count + 1;
            else btb_miss_count = btb_miss_count + 1;
            
            if (branch_mispredict) begin
                branch_mispredict_count = branch_mispredict_count + 1;
                $display("Cycle %0d: Branch Misprediction at PC=%h (Predicted=%b, Actual=%b)",
                        cycle_count, pc_e, branch_taken_e, top.riscv.c.PCSrcE_o);
            end
        end

        // Jump tracking (check in Execute stage)
        if (is_jump) begin
            jump_count = jump_count + 1;
            if (jump_mispredict) begin
                jump_mispredict_count = jump_mispredict_count + 1;
                $display("Cycle %0d: Jump Misprediction at PC=%h", cycle_count, pc_e);
            end
        end
        
        // Exit condition
        if (pc_f == 32'h00000094 || pc_f == 32'h00000000) begin
            $display("Program completed at cycle %0d", cycle_count);
            #20;
            break;
        end
        
        if (cycle_count >= 999) begin
            $display("Simulation timeout at cycle %0d", cycle_count);
            break;
        end
    end
    
    // Final report
    $display("\n=== Branch Predictor Performance Report ===");
    $display("Total cycles: %0d", cycle_count);
    $display("Instructions retired: %0d", instr_count);
    $display("CPI: %f", real'(cycle_count)/real'(instr_count));
    
    $display("\nBranch Statistics:");
    $display("Branches executed: %0d", branch_count);
    $display("Branch mispredictions: %0d", branch_mispredict_count);
    if (branch_count > 0)
        $display("Branch misprediction rate: %f%%", 
                100.0*real'(branch_mispredict_count)/real'(branch_count));
    
    $display("\nJump Statistics:");
    $display("Jumps executed: %0d", jump_count);
    $display("Jump mispredictions: %0d", jump_mispredict_count);
    if (jump_count > 0)
        $display("Jump misprediction rate: %f%%", 
                100.0*real'(jump_mispredict_count)/real'(jump_count));
    
    $display("\nBTB Statistics:");
    $display("BTB hits: %0d", btb_hit_count);
    $display("BTB misses: %0d", btb_miss_count);
    if ((btb_hit_count + btb_miss_count) > 0)
        $display("BTB hit rate: %f%%", 
                100.0*real'(btb_hit_count)/real'(btb_hit_count + btb_miss_count));
    
    $display("\nFinal Register Values:");
    $display("s0 = %0d", top.riscv.dp.rf.s0);
    $display("s1 = %0d", top.riscv.dp.rf.s1);
    $display("s2 = %0d", top.riscv.dp.rf.s2);
    $display("s7 = %0d", top.riscv.dp.rf.s7);
    
    $finish;
end

// Detailed predictor monitoring
always @(posedge clk) begin
    if (!reset && (is_branch || is_jump) && pc_e != 0) begin
        $display("Predictor Decision: PC=%h, Type=%s, Predicted=%b, Actual=%b, Target=%h",
                pc_e,
                is_branch ? "Branch" : "Jump",
                branch_taken_e,
                is_branch ? top.riscv.c.PCSrcE_o : 1'b1,
                top.riscv.dp.BTBtargetF);
    end
end

endmodule