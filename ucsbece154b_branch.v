module ucsbece154b_branch #(
    parameter NUM_BTB_ENTRIES = 32,
    parameter NUM_GHR_BITS    = 5
) (
    input               clk, 
    input               reset_i,
    input        [31:0] pc_i,
    input  [$clog2(NUM_BTB_ENTRIES)-1:0] BTBwriteaddress_i,
    input        [31:0] BTBwritedata_i,   
    output reg   [31:0] BTBtarget_o,           
    input               BTB_we, 
    output reg          BranchTaken_o,
    input         [6:0] op_i, 
    input               PHTincrement_i, 
    input               GHRreset_i,
    input               PHTwe_i,
    input    [NUM_GHR_BITS-1:0]  PHTwriteaddress_i,
    output   [NUM_GHR_BITS-1:0]  PHTreadaddress_o
);

`include "ucsbece154b_defines.vh"

// CONTEXT: BTB
// BTB is a branch target buffer that stores the target address of branch instructions
// it is used to predict the target address of a branch instruction before it is executed
// 2-way set associative table with 32 entries, each entry has a target address and a tag
// we index into the BTB using the lower bits of the PC address and check if the tag matches
// if it does, we check if the entry is valid (i.e., if it is a jump or branch instruction)
// if it is, we return the target address and the prediction (taken or not taken)
// if it is not, we return a default value (0) and not taken prediction

// CONTEXT: Gshare predictor
// Gshare is a branch predictor that uses global history to predict the outcome of branch instructions
// the taken or not taken prediction is based on the PHT (Pattern History Table) which is indexed using the GHR (Global History Register)
// the PHT is a 2-bit saturating counter that predicts the outcome of the branch instruction based on the GHR value
// the saturating counter values are 00 (strongly not taken), 01 (weakly not taken), 10 (weakly taken), and 11 (strongly taken)
// the PHT is indexed using the XOR of the GHR and the lower bits of the PC address (given in lab instr)
// the GHR is a shift register that shifts in the outcome of the last branch instruction
// we have a 5 bit GHR so we can store the outcome of the last 5 branch instructions, LSB is the most recent and MSB is the oldest
// train the predictor with the outcome of the last branch instruction
// the PHT is updated with the outcome of the branch instruction (taken increments eg 01->10, not taken decrements eg 11->10)
// the GHR is updated with the outcome of the last branch instruction (e.g. 10010 + taken = 00101)

// BTB implementation
reg [31:0] BTB_target   [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag      [0:NUM_BTB_ENTRIES-1];
reg        BTB_J        [0:NUM_BTB_ENTRIES-1];
reg        BTB_B        [0:NUM_BTB_ENTRIES-1];

// Gshare predictor
reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1<<NUM_GHR_BITS)-1];

// Index and tag extraction
wire [$clog2(NUM_BTB_ENTRIES)-1:0] BTB_index = pc_i[$clog2(NUM_BTB_ENTRIES)+1:2];
wire [31:0] pc_tag = pc_i[31:$clog2(NUM_BTB_ENTRIES)+2];
wire BTB_valid = BTB_J[BTB_index] | BTB_B[BTB_index];
wire BTB_hit = (BTB_tag[BTB_index] == pc_tag) && BTB_valid;

assign PHTreadaddress_o = GHR ^ pc_i[NUM_GHR_BITS+1:2];

wire is_branch = (op_i == instr_branch_op);
wire is_jump   = (op_i == instr_jal_op) || (op_i == instr_jalr_op);

// Fetch stage: read BTB
always @(*) begin
    if (BTB_hit) begin
        BTBtarget_o = BTB_target[BTB_index];
        BranchTaken_o = BTB_J[BTB_index] ? 1'b1 : PHT[PHTreadaddress_o][1];
    end else begin
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end

// Execute stage: update BTB
always @(posedge clk) begin
    if (reset_i) begin
        // Entry 0
        BTB_target[0] <= 32'b0;
        BTB_tag[0]    <= 32'b0;
        BTB_J[0]      <= 1'b0;
        BTB_B[0]      <= 1'b0;
        
        // Entry 1
        BTB_target[1] <= 32'b0;
        BTB_tag[1]    <= 32'b0;
        BTB_J[1]      <= 1'b0;
        BTB_B[1]      <= 1'b0;
        
        // Entry 2
        BTB_target[2] <= 32'b0;
        BTB_tag[2]    <= 32'b0;
        BTB_J[2]      <= 1'b0;
        BTB_B[2]      <= 1'b0;
        
        // Entry 3
        BTB_target[3] <= 32'b0;
        BTB_tag[3]    <= 32'b0;
        BTB_J[3]      <= 1'b0;
        BTB_B[3]      <= 1'b0;
        
        // Entry 4
        BTB_target[4] <= 32'b0;
        BTB_tag[4]    <= 32'b0;
        BTB_J[4]      <= 1'b0;
        BTB_B[4]      <= 1'b0;
        
        // Entry 5
        BTB_target[5] <= 32'b0;
        BTB_tag[5]    <= 32'b0;
        BTB_J[5]      <= 1'b0;
        BTB_B[5]      <= 1'b0;
        
        // Entry 6
        BTB_target[6] <= 32'b0;
        BTB_tag[6]    <= 32'b0;
        BTB_J[6]      <= 1'b0;
        BTB_B[6]      <= 1'b0;
        
        // Entry 7
        BTB_target[7] <= 32'b0;
        BTB_tag[7]    <= 32'b0;
        BTB_J[7]      <= 1'b0;
        BTB_B[7]      <= 1'b0;
        
        // Entry 8
        BTB_target[8] <= 32'b0;
        BTB_tag[8]    <= 32'b0;
        BTB_J[8]      <= 1'b0;
        BTB_B[8]      <= 1'b0;
        
        // Entry 9
        BTB_target[9] <= 32'b0;
        BTB_tag[9]    <= 32'b0;
        BTB_J[9]      <= 1'b0;
        BTB_B[9]      <= 1'b0;
        
        // Entry 10
        BTB_target[10] <= 32'b0;
        BTB_tag[10]    <= 32'b0;
        BTB_J[10]      <= 1'b0;
        BTB_B[10]      <= 1'b0;
        
        // Entry 11
        BTB_target[11] <= 32'b0;
        BTB_tag[11]    <= 32'b0;
        BTB_J[11]      <= 1'b0;
        BTB_B[11]      <= 1'b0;
        
        // Entry 12
        BTB_target[12] <= 32'b0;
        BTB_tag[12]    <= 32'b0;
        BTB_J[12]      <= 1'b0;
        BTB_B[12]      <= 1'b0;
        
        // Entry 13
        BTB_target[13] <= 32'b0;
        BTB_tag[13]    <= 32'b0;
        BTB_J[13]      <= 1'b0;
        BTB_B[13]      <= 1'b0;
        
        // Entry 14
        BTB_target[14] <= 32'b0;
        BTB_tag[14]    <= 32'b0;
        BTB_J[14]      <= 1'b0;
        BTB_B[14]      <= 1'b0;
        
        // Entry 15
        BTB_target[15] <= 32'b0;
        BTB_tag[15]    <= 32'b0;
        BTB_J[15]      <= 1'b0;
        BTB_B[15]      <= 1'b0;
        
        // Entry 16
        BTB_target[16] <= 32'b0;
        BTB_tag[16]    <= 32'b0;
        BTB_J[16]      <= 1'b0;
        BTB_B[16]      <= 1'b0;
        
        // Entry 17
        BTB_target[17] <= 32'b0;
        BTB_tag[17]    <= 32'b0;
        BTB_J[17]      <= 1'b0;
        BTB_B[17]      <= 1'b0;
        
        // Entry 18
        BTB_target[18] <= 32'b0;
        BTB_tag[18]    <= 32'b0;
        BTB_J[18]      <= 1'b0;
        BTB_B[18]      <= 1'b0;
        
        // Entry 19
        BTB_target[19] <= 32'b0;
        BTB_tag[19]    <= 32'b0;
        BTB_J[19]      <= 1'b0;
        BTB_B[19]      <= 1'b0;
        
        // Entry 20
        BTB_target[20] <= 32'b0;
        BTB_tag[20]    <= 32'b0;
        BTB_J[20]      <= 1'b0;
        BTB_B[20]      <= 1'b0;
        
        // Entry 21
        BTB_target[21] <= 32'b0;
        BTB_tag[21]    <= 32'b0;
        BTB_J[21]      <= 1'b0;
        BTB_B[21]      <= 1'b0;
        
        // Entry 22
        BTB_target[22] <= 32'b0;
        BTB_tag[22]    <= 32'b0;
        BTB_J[22]      <= 1'b0;
        BTB_B[22]      <= 1'b0;
        
        // Entry 23
        BTB_target[23] <= 32'b0;
        BTB_tag[23]    <= 32'b0;
        BTB_J[23]      <= 1'b0;
        BTB_B[23]      <= 1'b0;
        
        // Entry 24
        BTB_target[24] <= 32'b0;
        BTB_tag[24]    <= 32'b0;
        BTB_J[24]      <= 1'b0;
        BTB_B[24]      <= 1'b0;
        
        // Entry 25
        BTB_target[25] <= 32'b0;
        BTB_tag[25]    <= 32'b0;
        BTB_J[25]      <= 1'b0;
        BTB_B[25]      <= 1'b0;
        
        // Entry 26
        BTB_target[26] <= 32'b0;
        BTB_tag[26]    <= 32'b0;
        BTB_J[26]      <= 1'b0;
        BTB_B[26]      <= 1'b0;
        
        // Entry 27
        BTB_target[27] <= 32'b0;
        BTB_tag[27]    <= 32'b0;
        BTB_J[27]      <= 1'b0;
        BTB_B[27]      <= 1'b0;
        
        // Entry 28
        BTB_target[28] <= 32'b0;
        BTB_tag[28]    <= 32'b0;
        BTB_J[28]      <= 1'b0;
        BTB_B[28]      <= 1'b0;
        
        // Entry 29
        BTB_target[29] <= 32'b0;
        BTB_tag[29]    <= 32'b0;
        BTB_J[29]      <= 1'b0;
        BTB_B[29]      <= 1'b0;
        
        // Entry 30
        BTB_target[30] <= 32'b0;
        BTB_tag[30]    <= 32'b0;
        BTB_J[30]      <= 1'b0;
        BTB_B[30]      <= 1'b0;
        
        // Entry 31
        BTB_target[31] <= 32'b0;
        BTB_tag[31]    <= 32'b0;
        BTB_J[31]      <= 1'b0;
        BTB_B[31]      <= 1'b0;
    end else if (BTB_we) begin
        BTB_target[BTB_index] <= BTBwritedata_i;  // Use same index as read path
        BTB_tag[BTB_index] <= pc_tag;             // Use same tag calculation
        BTB_J[BTB_index] <= (op_i == instr_jal_op) || (op_i == instr_jalr_op);
        BTB_B[BTB_index] <= (op_i == instr_branch_op);
    end
end

// GHR update
always @(posedge clk) begin
    if (reset_i || GHRreset_i) begin
        GHR <= {NUM_GHR_BITS{1'b0}};
    end else if (is_branch || is_jump) begin
        GHR <= {GHR[NUM_GHR_BITS-2:0], BranchTaken_o};
    end
end

// PHT update
always @(posedge clk) begin
    if (reset_i) begin
        PHT[0] <= 2'b01;
         PHT[1] <= 2'b01;
         PHT[2] <= 2'b01;
         PHT[3] <= 2'b01;
         PHT[4] <= 2'b01;
         PHT[5] <= 2'b01;
         PHT[6] <= 2'b01;
         PHT[7] <= 2'b01;
         PHT[8] <= 2'b01;
         PHT[9] <= 2'b01;
         PHT[10] <= 2'b01;
         PHT[11] <= 2'b01;
         PHT[12] <= 2'b01;
         PHT[13] <= 2'b01;
         PHT[14] <= 2'b01;
         PHT[15] <= 2'b01;
         PHT[16] <= 2'b01;
         PHT[17] <= 2'b01;
         PHT[18] <= 2'b01;
         PHT[19] <= 2'b01;
         PHT[20] <= 2'b01;
         PHT[21] <= 2'b01;
         PHT[22] <= 2'b01;
         PHT[23] <= 2'b01;
         PHT[24] <= 2'b01;
         PHT[25] <= 2'b01;
         PHT[26] <= 2'b01;
         PHT[27] <= 2'b01;
         PHT[28] <= 2'b01;
         PHT[29] <= 2'b01;
         PHT[30] <= 2'b01;
         PHT[31] <= 2'b01;
    end else if (PHTwe_i) begin
        if (PHTincrement_i) begin
            if (PHT[PHTwriteaddress_i] != 2'b11)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        end else begin
            if (PHT[PHTwriteaddress_i] != 2'b00)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;
        end
    end
end

endmodule
