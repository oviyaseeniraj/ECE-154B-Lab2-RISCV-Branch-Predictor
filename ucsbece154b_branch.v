module ucsbece154b_branch #(
    parameter NUM_BTB_ENTRIES = 8,
    parameter NUM_GHR_BITS    = 3
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

reg [31:0] BTB_target   [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag      [0:NUM_BTB_ENTRIES-1];
reg        BTB_valid    [0:NUM_BTB_ENTRIES-1];

reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1<<NUM_GHR_BITS)-1];

wire [$clog2(NUM_BTB_ENTRIES)-1:0] BTB_index = pc_i[$clog2(NUM_BTB_ENTRIES)+1:2];
wire [31:0] pc_tag = pc_i[31:$clog2(NUM_BTB_ENTRIES)+2];
wire BTB_hit = (BTB_tag[BTB_index] == pc_tag) && BTB_valid[BTB_index];

assign PHTreadaddress_o = GHR ^ pc_i[NUM_GHR_BITS+1:2];

wire is_branch = (op_i == instr_branch_op);
wire is_jump   = (op_i == instr_jal_op) || (op_i == instr_jalr_op);

always @(*) begin
    if (BTB_hit) begin
        BTBtarget_o = BTB_target[BTB_index];
        BranchTaken_o = is_jump ? 1'b1 : PHT[PHTreadaddress_o][1];
    end else begin
        BTBtarget_o = pc_i + 4;
        BranchTaken_o = 1'b0;
    end
end

always @(posedge clk) begin
    if (reset_i) begin
        // Initialize BTB
        BTB_target[0] <= 32'b0; BTB_tag[0] <= 32'b0; BTB_valid[0] <= 1'b0;
        BTB_target[1] <= 32'b0; BTB_tag[1] <= 32'b0; BTB_valid[1] <= 1'b0;
        BTB_target[2] <= 32'b0; BTB_tag[2] <= 32'b0; BTB_valid[2] <= 1'b0;
        BTB_target[3] <= 32'b0; BTB_tag[3] <= 32'b0; BTB_valid[3] <= 1'b0;
        BTB_target[4] <= 32'b0; BTB_tag[4] <= 32'b0; BTB_valid[4] <= 1'b0;
        BTB_target[5] <= 32'b0; BTB_tag[5] <= 32'b0; BTB_valid[5] <= 1'b0;
        BTB_target[6] <= 32'b0; BTB_tag[6] <= 32'b0; BTB_valid[6] <= 1'b0;
        BTB_target[7] <= 32'b0; BTB_tag[7] <= 32'b0; BTB_valid[7] <= 1'b0;
        BTB_target[8] <= 32'b0; BTB_tag[8] <= 32'b0; BTB_valid[8] <= 1'b0;
        BTB_target[9] <= 32'b0; BTB_tag[9] <= 32'b0; BTB_valid[9] <= 1'b0;
        BTB_target[10] <= 32'b0; BTB_tag[10] <= 32'b0; BTB_valid[10] <= 1'b0;
        BTB_target[11] <= 32'b0; BTB_tag[11] <= 32'b0; BTB_valid[11] <= 1'b0;
        BTB_target[12] <= 32'b0; BTB_tag[12] <= 32'b0; BTB_valid[12] <= 1'b0;
        BTB_target[13] <= 32'b0; BTB_tag[13] <= 32'b0; BTB_valid[13] <= 1'b0;
        BTB_target[14] <= 32'b0; BTB_tag[14] <= 32'b0; BTB_valid[14] <= 1'b0;
        BTB_target[15] <= 32'b0; BTB_tag[15] <= 32'b0; BTB_valid[15] <= 1'b0;
        BTB_target[16] <= 32'b0; BTB_tag[16] <= 32'b0; BTB_valid[16] <= 1'b0;
        BTB_target[17] <= 32'b0; BTB_tag[17] <= 32'b0; BTB_valid[17] <= 1'b0;
        BTB_target[18] <= 32'b0; BTB_tag[18] <= 32'b0; BTB_valid[18] <= 1'b0;
        BTB_target[19] <= 32'b0; BTB_tag[19] <= 32'b0; BTB_valid[19] <= 1'b0;
        BTB_target[20] <= 32'b0; BTB_tag[20] <= 32'b0; BTB_valid[20] <= 1'b0;
        BTB_target[21] <= 32'b0; BTB_tag[21] <= 32'b0; BTB_valid[21] <= 1'b0;
        BTB_target[22] <= 32'b0; BTB_tag[22] <= 32'b0; BTB_valid[22] <= 1'b0;
        BTB_target[23] <= 32'b0; BTB_tag[23] <= 32'b0; BTB_valid[23] <= 1'b0;
        BTB_target[24] <= 32'b0; BTB_tag[24] <= 32'b0; BTB_valid[24] <= 1'b0;
        BTB_target[25] <= 32'b0; BTB_tag[25] <= 32'b0; BTB_valid[25] <= 1'b0;
        BTB_target[26] <= 32'b0; BTB_tag[26] <= 32'b0; BTB_valid[26] <= 1'b0;
        BTB_target[27] <= 32'b0; BTB_tag[27] <= 32'b0; BTB_valid[27] <= 1'b0;
        BTB_target[28] <= 32'b0; BTB_tag[28] <= 32'b0; BTB_valid[28] <= 1'b0;
        BTB_target[29] <= 32'b0; BTB_tag[29] <= 32'b0; BTB_valid[29] <= 1'b0;
        BTB_target[30] <= 32'b0; BTB_tag[30] <= 32'b0; BTB_valid[30] <= 1'b0;
        BTB_target[31] <= 32'b0; BTB_tag[31] <= 32'b0; BTB_valid[31] <= 1'b0;
    end else if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i] <= pc_i[31:$clog2(NUM_BTB_ENTRIES)+2];
        BTB_valid[BTBwriteaddress_i] <= 1'b1;
    end
end

always @(posedge clk) begin
    if (reset_i || GHRreset_i) begin
        GHR <= {NUM_GHR_BITS{1'b0}};
    end else if (PHTwe_i) begin
        GHR <= {GHR[NUM_GHR_BITS-2:0], PHTincrement_i};
    end
end

always @(posedge clk) begin
    if (reset_i) begin
        // Initialize PHT
        PHT[0] <= 2'b01; PHT[1] <= 2'b01; PHT[2] <= 2'b01; PHT[3] <= 2'b01;
        PHT[4] <= 2'b01; PHT[5] <= 2'b01; PHT[6] <= 2'b01; PHT[7] <= 2'b01;
        PHT[8] <= 2'b01; PHT[9] <= 2'b01; PHT[10] <= 2'b01; PHT[11] <= 2'b01;
        PHT[12] <= 2'b01; PHT[13] <= 2'b01; PHT[14] <= 2'b01; PHT[15] <= 2'b01;
        PHT[16] <= 2'b01; PHT[17] <= 2'b01; PHT[18] <= 2'b01; PHT[19] <= 2'b01;
        PHT[20] <= 2'b01; PHT[21] <= 2'b01; PHT[22] <= 2'b01; PHT[23] <= 2'b01;
        PHT[24] <= 2'b01; PHT[25] <= 2'b01; PHT[26] <= 2'b01; PHT[27] <= 2'b01;
        PHT[28] <= 2'b01; PHT[29] <= 2'b01; PHT[30] <= 2'b01; PHT[31] <= 2'b01;
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