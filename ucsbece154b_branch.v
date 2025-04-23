// DEBUG-ENHANCED ucsbece154b_branch.v
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

// BTB parameters
localparam BTB_IDX_BITS = $clog2(NUM_BTB_ENTRIES);

// BTB storage
reg [31:0] BTB_target [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag    [0:NUM_BTB_ENTRIES-1];
reg        BTB_j_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_b_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_valid  [0:NUM_BTB_ENTRIES-1];

// GHR and PHT
reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1 << NUM_GHR_BITS)-1];

// BTB indexing and tag matching
wire [BTB_IDX_BITS-1:0] btb_index = pc_i[BTB_IDX_BITS+1:2];
wire [31:0] btb_tag_in = pc_i;
reg tag_match;
reg btb_entry_valid;

// Reset and initialization
integer i;
always @(posedge clk) begin
    if (reset_i) begin
        for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
            BTB_target[i] <= 32'b0;
            BTB_tag[i]    <= 32'b0;
            BTB_j_flag[i] <= 1'b0;
            BTB_b_flag[i] <= 1'b0;
            BTB_valid[i]  <= 1'b0;
        end
        
        // Initialize PHT to weakly taken
        for (i = 0; i < (1 << NUM_GHR_BITS); i = i + 1) begin
            PHT[i] <= 2'b10;
        end
        
        GHR <= {NUM_GHR_BITS{1'b0}};
    end
end

// BTB tag matching
always @(*) begin
    tag_match = BTB_valid[btb_index] && (btb_tag_in == BTB_tag[btb_index]);
end

// BTB write
always @(posedge clk) begin
    if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= pc_i;
        BTB_j_flag[BTBwriteaddress_i] <= (op_i == instr_jal_op || op_i == instr_jalr_op);
        BTB_b_flag[BTBwriteaddress_i] <= (op_i == instr_branch_op);
        BTB_valid[BTBwriteaddress_i]  <= 1'b1;
    end
end

// Gshare predictor
wire [NUM_GHR_BITS-1:0] pc_xor_ghr = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
assign PHTreadaddress_o = pc_xor_ghr;
wire predict_taken = PHT[pc_xor_ghr][1];

// PHT update
always @(posedge clk) begin
    if (PHTwe_i) begin
        if (PHTincrement_i && PHT[PHTwriteaddress_i] < 2'b11)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        else if (!PHTincrement_i && PHT[PHTwriteaddress_i] > 2'b00)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;
    end
end

// GHR update
always @(posedge clk) begin
    if (reset_i || GHRreset_i)
        GHR <= {NUM_GHR_BITS{1'b0}};
    else if (PHTwe_i)
        GHR <= {BranchTaken_o, GHR[NUM_GHR_BITS-1:1]};
end

// Generate prediction
always @(*) begin
    BTBtarget_o = 32'b0;
    BranchTaken_o = 1'b0;

    if (BTB_valid[btb_index] && tag_match) begin
        if (BTB_j_flag[btb_index]) begin
            // Jumps are always taken
            BTBtarget_o = BTB_target[btb_index];
            BranchTaken_o = 1'b1;
        end else if (BTB_b_flag[btb_index]) begin
            // Branch depends on PHT prediction
            BTBtarget_o = BTB_target[btb_index];
            BranchTaken_o = predict_taken;
        end
    end
end

endmodule
