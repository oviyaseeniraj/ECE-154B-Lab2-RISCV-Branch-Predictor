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

// BTB entry storage
reg [31:0] BTB_target [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag    [0:NUM_BTB_ENTRIES-1];
reg        BTB_j_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_b_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_valid  [0:NUM_BTB_ENTRIES-1];  // NEW: explicit validity tracking

// GHR and PHT
reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1 << NUM_GHR_BITS)-1];

// BTB read
wire [BTB_IDX_BITS-1:0] btb_index = pc_i[BTB_IDX_BITS+1:2];
wire [31:0] btb_tag_in = pc_i;
wire tag_match = (BTB_tag[btb_index] == btb_tag_in);
wire btb_entry_valid = BTB_valid[btb_index];

// Gshare address
wire [NUM_GHR_BITS-1:0] pc_xor_ghr = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
assign PHTreadaddress_o = pc_xor_ghr;

wire [1:0] pht_entry = PHT[pc_xor_ghr];
wire predict_taken = pht_entry[1];

// Bypass BTB write
wire [31:0] btb_target_bypass = (BTB_we && BTBwriteaddress_i == btb_index) ? 
                                BTBwritedata_i : BTB_target[btb_index];

// Prediction output
always @(*) begin
    if (tag_match && btb_entry_valid) begin
        BTBtarget_o = btb_target_bypass;
        BranchTaken_o = (BTB_b_flag[btb_index] && predict_taken) || BTB_j_flag[btb_index];
    end else begin
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end

// BTB write
always @(posedge clk) begin
    if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= pc_i;
        BTB_j_flag[BTBwriteaddress_i] <= (op_i == instr_jal_op || op_i == instr_jalr_op);
        BTB_b_flag[BTBwriteaddress_i] <= (op_i == instr_branch_op);
        BTB_valid[BTBwriteaddress_i]  <= 1'b1;  // Mark entry as valid
    end
end

// PHT update
always @(posedge clk) begin
    // if (reset_i) begin
    //     // Initialize all PHT entries to weakly taken (10)
    //     PHT[0] <= 2'b10; PHT[1] <= 2'b10; PHT[2] <= 2'b10; PHT[3] <= 2'b10;
    //     PHT[4] <= 2'b10; PHT[5] <= 2'b10; PHT[6] <= 2'b10; PHT[7] <= 2'b10;
    //     PHT[8] <= 2'b10; PHT[9] <= 2'b10; PHT[10] <= 2'b10; PHT[11] <= 2'b10;
    //     PHT[12] <= 2'b10; PHT[13] <= 2'b10; PHT[14] <= 2'b10; PHT[15] <= 2'b10;
    //     PHT[16] <= 2'b10; PHT[17] <= 2'b10; PHT[18] <= 2'b10; PHT[19] <= 2'b10;
    //     PHT[20] <= 2'b10; PHT[21] <= 2'b10; PHT[22] <= 2'b10; PHT[23] <= 2'b10;
    //     PHT[24] <= 2'b10; PHT[25] <= 2'b10; PHT[26] <= 2'b10; PHT[27] <= 2'b10;
    //     PHT[28] <= 2'b10; PHT[29] <= 2'b10; PHT[30] <= 2'b10; PHT[31] <= 2'b10;
    // end
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
        GHR <= 0;
    else if (op_i == instr_branch_op)
        GHR <= {GHR[NUM_GHR_BITS-2:0], ~PHTincrement_i}; // ~PHTincrement_i = actual_taken
end

endmodule
