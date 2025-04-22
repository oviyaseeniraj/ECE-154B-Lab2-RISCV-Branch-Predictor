module ucsbece154b_top_tb();

// Clock generation (10ns period -> 100MHz)
reg clk = 1;
always #5 clk = ~clk;
reg reset;

// Experiment parameters
parameter BTB_ENTRIES = 32;
parameter GHR_BITS = 5;

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

// Pipeline registers to track instructions in each stage
reg [31:0] pc_f, pc_d, pc_e, pc_m, pc_w;
reg [6:0] op_f, op_d, op_e, op_m, op_w;
reg [31:0] pc_plus4_f, pc_plus4_d, pc_plus4_e, pc_plus4_m, pc_plus4_w;

// Track branch/jump instructions in pipeline
reg is_branch_d, is_branch_e, is_branch_m, is_branch_w;
reg is_jump_d, is_jump_e, is_jump_m, is_jump_w;
reg branch_taken_f, branch_taken_d, branch_taken_e;
reg btb_hit_f, btb_hit_d, btb_hit_e;

// Branch predictor monitoring signals
wire is_branch = (op_e == 7'b1100011);  // BEQ, BNE, etc.
wire is_jump = ((op_e == 7'b1101111) ||  // JAL
               (op_e == 7'b1100111);     // JALR
wire branch_resolved = is_branch && top.riscv.PCSrcE;
wire branch_mispredict = is_branch && (top.riscv.PCSrcE != branch_taken_e);
wire jump_mispredict = is_jump && !branch_taken_e;
wire btb_hit = (branch_taken_f && (top.riscv.BTBtargetF != pc_plus4_f)) ||
               (is_jump && branch_taken_f);

// Update pipeline registers
always @(posedge clk) begin
    if (reset) begin
        pc_f <= 0; pc_d <= 0; pc_e <= 0; pc_m <= 0; pc_w <= 0;
        op_f <= 0; op_d <= 0; op_e <= 0; op_m <= 0; op_w <= 0;
        pc_plus4_f <= 0; pc_plus4_d <= 0; pc_plus4_e <= 0; pc_plus4_m <= 0; pc_plus4_w <= 0;
        is_branch_d <= 0; is_branch_e <= 0; is_branch_m <= 0; is_branch_w <= 0;
        is_jump_d <= 0; is_jump_e <= 0; is_jump_m <= 0; is_jump_w <= 0;
        branch_taken_f <= 0; branch_taken_d <= 0; branch_taken_e <= 0;
        btb_hit_f <= 0; btb_hit_d <= 0; btb_hit_e <= 0;
    end else begin
        // Pipeline PC tracking
        pc_f <= top.riscv.PCF;
        pc_d <= top.riscv.PCD;
        pc_e <= top.riscv.PCE;
        pc_m <= top.riscv.ALUResultM;
        pc_w <= top.riscv.PCPlus4W - 4;
        
        // Pipeline instruction opcode tracking
        op_f <= top.riscv.InstrF[6:0];
        op_d <= top.riscv.InstrD[6:0];
        op_e <= top.riscv.InstrE[6:0];
        op_m <= top.riscv.InstrM[6:0];
        op_w <= top.riscv.InstrW[6:0];
        
        // Pipeline PC+4 tracking
        pc_plus4_f <= top.riscv.PCPlus4F;
        pc_plus4_d <= top.riscv.PCPlus4D;
        pc_plus4_e <= top.riscv.PCPlus4E;
        pc_plus4_m <= top.riscv.PCPlus4M;
        pc_plus4_w <= top.riscv.PCPlus4W;
        
        // Branch/jump tracking through pipeline
        is_branch_d <= (top.riscv.InstrD[6:0] == 7'b1100011);
        is_branch_e <= is_branch_d;
        is_branch_m <= is_branch_e;
        is_branch_w <= is_branch_m;
        
        is_jump_d <= ((top.riscv.InstrD[6:0] == 7'b1101111) || (top.riscv.InstrD[6:0] == 7'b1100111));
        is_jump_e <= is_jump_d;
        is_jump_m <= is_jump_e;
        is_jump_w <= is_jump_m;
        
        // Branch prediction tracking through pipeline
        branch_taken_f <= top.riscv.BranchTakenF;
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
    
    // Initialize instruction memory with edge case program
    top.riscv.imem.mem[0]  = 32'h00000413;  // addi s0,x0,0
    top.riscv.imem.mem[1]  = 32'h00000493;  // addi s1,x0,0
    top.riscv.imem.mem[2]  = 32'h00000913;  // addi s2,x0,0
    top.riscv.imem.mem[3]  = 32'h00000a13;  // addi s4,x0,0
    top.riscv.imem.mem[4]  = 32'h02000a93;  // addi s5,x0,32
    top.riscv.imem.mem[5]  = 32'h12346b37;  // lui s6,0x12346
    top.riscv.imem.mem[6]  = 32'h678b0b13;  // addi s6,s6,0x678
    top.riscv.imem.mem[7]  = 32'h00000b93;  // addi s7,x0,0
    top.riscv.imem.mem[8]  = 32'h00400c13;  // addi s8,x0,4
    top.riscv.imem.mem[9]  = 32'h01f2f293;  // andi t0,t0,0x1f
    top.riscv.imem.mem[10] = 32'h00229293;  // slli t0,t0,0x2
    top.riscv.imem.mem[11] = 32'h00028063;  // beq t0,x0,target_A
    top.riscv.imem.mem[12] = 32'h0122c333;  // xor t1,t0,s2
    top.riscv.imem.mem[13] = 32'h01f37313;  // andi t1,t1,0x1f
    top.riscv.imem.mem[14] = 32'h00031063;  // bne t1,x0,target_B
    top.riscv.imem.mem[15] = 32'h0032f393;  // andi t2,t0,0x3
    top.riscv.imem.mem[16] = 32'h00239393;  // slli t2,t2,0x2
    top.riscv.imem.mem[17] = 32'h00030067;  // jalr x0,0(t2)
    top.riscv.imem.mem[18] = 32'h00140413;  // addi s0,s0,1
    top.riscv.imem.mem[19] = 32'h0180006f;  // jal x0,inner_loop_setup
    top.riscv.imem.mem[20] = 32'h00148493;  // addi s1,s1,1
    top.riscv.imem.mem[21] = 32'h00000b93;  // addi s7,x0,0
    top.riscv.imem.mem[22] = 32'h001b8b93;  // addi s7,s7,1
    top.riscv.imem.mem[23] = 32'h001b8b93;  // addi s7,s7,1
    top.riscv.imem.mem[24] = 32'h000b8a63;  // beq s7,x0,skip_inner
    top.riscv.imem.mem[25] = 32'h012bc3b3;  // xor t2,s7,s2
    top.riscv.imem.mem[26] = 32'h0033f393;  // andi t2,t2,0x3
    top.riscv.imem.mem[27] = 32'h00039063;  // bne t2,x0,skip_inner
    top.riscv.imem.mem[28] = 32'h001b8b93;  // addi s7,s7,1
    top.riscv.imem.mem[29] = 32'hffcb8ae3;  // beq s7,s8,inner_loop
    top.riscv.imem.mem[30] = 32'h00190913;  // addi s2,s2,1
    top.riscv.imem.mem[31] = 32'hff3914e3;  // bne s2,s5,outer_loop
    top.riscv.imem.mem[32] = 32'h00000297;  // auipc t0,0x0
    top.riscv.imem.mem[33] = 32'h00428293;  // addi t0,t0,4
    top.riscv.imem.mem[34] = 32'h0082a023;  // sw s0,0(t0)
    top.riscv.imem.mem[35] = 32'h00c2a223;  // sw s1,4(t0)
    top.riscv.imem.mem[36] = 32'h05d00893;  // addi a7,x0,93
    top.riscv.imem.mem[37] = 32'h00000073;  // ecall
    top.riscv.imem.mem[38] = 32'h0000006f;  // jal x0,target_0
    top.riscv.imem.mem[39] = 32'hffc40413;  // addi s0,s0,-4
    top.riscv.imem.mem[40] = 32'h0180006f;  // jal x0,inner_loop_setup
    top.riscv.imem.mem[41] = 32'hffc48493;  // addi s1,s1,-4
    top.riscv.imem.mem[42] = 32'h0180006f;  // jal x0,inner_loop_setup
    top.riscv.imem.mem[43] = 32'h00240413;  // addi s0,s0,2
    top.riscv.imem.mem[44] = 32'h0180006f;  // jal x0,inner_loop_setup

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
        if (top.riscv.RegWriteW && !reset && cycle_count > 2)
            instr_count = instr_count + 1;
        
        // Branch tracking (check in Execute stage)
        if (is_branch) begin
            branch_count = branch_count + 1;
            
            if (btb_hit_e) btb_hit_count = btb_hit_count + 1;
            else btb_miss_count = btb_miss_count + 1;
            
            if (branch_mispredict) begin
                branch_mispredict_count = branch_mispredict_count + 1;
                $display("Cycle %0d: Branch Misprediction at PC=%h (Predicted=%b, Actual=%b)",
                        cycle_count, pc_e, branch_taken_e, top.riscv.PCSrcE);
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
    
    $finish;
end

// Detailed predictor monitoring
always @(posedge clk) begin
    if (!reset && (is_branch || is_jump) && pc_e != 0) begin
        $display("Predictor Decision: PC=%h, Type=%s, Predicted=%b, Actual=%b, Target=%h",
                pc_e,
                is_branch ? "Branch" : "Jump",
                branch_taken_e,
                is_branch ? top.riscv.PCSrcE : 1'b1,
                top.riscv.BTBtargetF);
    end
end

endmodule