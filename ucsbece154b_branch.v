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
// the taken or not taken prediction is based on the PHT (Prediction History Table) which is indexed using the GHR (Global History Register)
// the PHT is a 2-bit saturating counter that predicts the outcome of the branch instruction based on the GHR value
// the saturating counter values are 00 (strongly not taken), 01 (weakly not taken), 10 (weakly taken), and 11 (strongly taken)
// the PHT is indexed using the XOR of the GHR and the lower bits of the PC address (given in lab instr)
// the GHR is a shift register that shifts in the outcome of the last branch instruction
// we have a 5 bit GHR so we can store the outcome of the last 5 branch instructions, LSB is the most recent and MSB is the oldest
// train the predictor with the outcome of the last branch instruction
// the PHT is updated with the outcome of the branch instruction (taken increments eg 01->10, not taken decrements eg 11->10)
// the GHR is updated with the outcome of the last branch instruction (e.g. 10010 + taken = 00101)

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

localparam BTB_IDX_BITS = $clog2(NUM_BTB_ENTRIES);

// BTB entry fields
reg [31:0] BTB_target   [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag      [0:NUM_BTB_ENTRIES-1];
reg        BTB_j_flag   [0:NUM_BTB_ENTRIES-1];
reg        BTB_b_flag   [0:NUM_BTB_ENTRIES-1];

// PHT and GHR
reg [1:0] PHT [0:(1 << NUM_GHR_BITS)-1];
reg [NUM_GHR_BITS-1:0] GHR;

wire [BTB_IDX_BITS-1:0] btb_index = pc_i[BTB_IDX_BITS+1:2];
wire [31:0] btb_tag_in = pc_i;

// BTB read logic
wire tag_match = (BTB_tag[btb_index] == btb_tag_in);
wire valid = (BTB_j_flag[btb_index] | BTB_b_flag[btb_index]);

// Predict logic
wire [NUM_GHR_BITS-1:0] pc_xor_ghr = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
assign PHTreadaddress_o = pc_xor_ghr;
wire [1:0] pht_entry = PHT[pc_xor_ghr];
wire predict_taken = pht_entry[1]; // MSB

// Adding combinatorial bypass logic
wire [31:0] btb_target_bypass = (BTB_we && (BTBwriteaddress_i == btb_index)) ? 
                               BTBwritedata_i : BTB_target[btb_index];

// Modified output assignment:
always @(*) begin
    if (tag_match && valid) begin
        BTBtarget_o = btb_target_bypass;  // Use bypassed target if available
        BranchTaken_o = (BTB_b_flag[btb_index] && predict_taken) || 
                       BTB_j_flag[btb_index];
    end else begin
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end

// GHR update
always @(posedge clk) begin
    if (reset_i || GHRreset_i)
        GHR <= 0;
    else if (op_i == instr_branch_op)
        GHR <= {GHR[NUM_GHR_BITS-2:0], predict_taken}; // shift in prediction
end

// BTB write
always @(posedge clk) begin
    if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= pc_i;
        BTB_j_flag[BTBwriteaddress_i] <= (op_i == instr_jal_op || op_i == instr_jalr_op);
        BTB_b_flag[BTBwriteaddress_i] <= (op_i == instr_branch_op);
    end
end

// PHT update
always @(posedge clk) begin
    if (PHTwe_i) begin
        if (PHTincrement_i && PHT[PHTwriteaddress_i] < 2'b11)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        else if (!PHTincrement_i && PHT[PHTwriteaddress_i] > 2'b00)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;
    end
end

endmodule
