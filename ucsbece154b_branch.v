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

localparam BTB_IDX_BITS = $clog2(NUM_BTB_ENTRIES);


reg [31:0] BTB_target [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tag    [0:NUM_BTB_ENTRIES-1];
reg        BTB_j_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_b_flag [0:NUM_BTB_ENTRIES-1];
reg        BTB_valid  [0:NUM_BTB_ENTRIES-1];

reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1 << NUM_GHR_BITS)-1];

wire [BTB_IDX_BITS-1:0] btb_index = pc_i[BTB_IDX_BITS+1:2];
wire [31:0] btb_tag_in = pc_i;
reg tag_match = 1'b0;
reg btb_entry_valid = 1'b0;

reg [31:0] tag_d, tag_e;
reg tag_match_d = 1'b0;
reg tag_match_e = 1'b0;
reg [6:0] op_e = 7'b0;

initial begin
    BTB_target[0] = 32'b0; BTB_tag[0]    = 32'b0; BTB_j_flag[0] = 1'b0; BTB_b_flag[0] = 1'b0; BTB_valid[0]  = 1'b0;
    BTB_target[1] = 32'b0; BTB_tag[1]    = 32'b0; BTB_j_flag[1] = 1'b0; BTB_b_flag[1] = 1'b0; BTB_valid[1]  = 1'b0;
    BTB_target[2] = 32'b0; BTB_tag[2]    = 32'b0; BTB_j_flag[2] = 1'b0; BTB_b_flag[2] = 1'b0; BTB_valid[2]  = 1'b0;
    BTB_target[3] = 32'b0; BTB_tag[3]    = 32'b0; BTB_j_flag[3] = 1'b0; BTB_b_flag[3] = 1'b0; BTB_valid[3]  = 1'b0;
    BTB_target[4] = 32'b0; BTB_tag[4]    = 32'b0; BTB_j_flag[4] = 1'b0; BTB_b_flag[4] = 1'b0; BTB_valid[4]  = 1'b0;
    BTB_target[5] = 32'b0; BTB_tag[5]    = 32'b0; BTB_j_flag[5] = 1'b0; BTB_b_flag[5] = 1'b0; BTB_valid[5]  = 1'b0;
    BTB_target[6] = 32'b0; BTB_tag[6] = 32'b0; BTB_j_flag[6] = 1'b0; BTB_b_flag[6] = 1'b0; BTB_valid[6] = 1'b0;
    BTB_target[7] = 32'b0; BTB_tag[7] = 32'b0; BTB_j_flag[7] = 1'b0; BTB_b_flag[7] = 1'b0; BTB_valid[7] = 1'b0;
    BTB_target[8] = 32'b0; BTB_tag[8] = 32'b0; BTB_j_flag[8] = 1'b0; BTB_b_flag[8] = 1'b0; BTB_valid[8] = 1'b0;
    BTB_target[9] = 32'b0; BTB_tag[9] = 32'b0; BTB_j_flag[9] = 1'b0; BTB_b_flag[9] = 1'b0; BTB_valid[9] = 1'b0;
    BTB_target[10] = 32'b0; BTB_tag[10] = 32'b0; BTB_j_flag[10] = 1'b0; BTB_b_flag[10] = 1'b0; BTB_valid[10] = 1'b0;
    BTB_target[11] = 32'b0; BTB_tag[11] = 32'b0; BTB_j_flag[11] = 1'b0; BTB_b_flag[11] = 1'b0; BTB_valid[11] = 1'b0;
    BTB_target[12] = 32'b0; BTB_tag[12] = 32'b0; BTB_j_flag[12] = 1'b0; BTB_b_flag[12] = 1'b0; BTB_valid[12] = 1'b0;
    BTB_target[13] = 32'b0; BTB_tag[13] = 32'b0; BTB_j_flag[13] = 1'b0; BTB_b_flag[13] = 1'b0; BTB_valid[13] = 1'b0;
    BTB_target[14] = 32'b0; BTB_tag[14] = 32'b0; BTB_j_flag[14] = 1'b0; BTB_b_flag[14] = 1'b0; BTB_valid[14] = 1'b0;
    BTB_target[15] = 32'b0; BTB_tag[15] = 32'b0; BTB_j_flag[15] = 1'b0; BTB_b_flag[15] = 1'b0; BTB_valid[15] = 1'b0;
    BTB_target[16] = 32'b0; BTB_tag[16] = 32'b0; BTB_j_flag[16] = 1'b0; BTB_b_flag[16] = 1'b0; BTB_valid[16] = 1'b0;
    BTB_target[17] = 32'b0; BTB_tag[17] = 32'b0; BTB_j_flag[17] = 1'b0; BTB_b_flag[17] = 1'b0; BTB_valid[17] = 1'b0;
    BTB_target[18] = 32'b0; BTB_tag[18] = 32'b0; BTB_j_flag[18] = 1'b0; BTB_b_flag[18] = 1'b0; BTB_valid[18] = 1'b0;
    BTB_target[19] = 32'b0; BTB_tag[19] = 32'b0; BTB_j_flag[19] = 1'b0; BTB_b_flag[19] = 1'b0; BTB_valid[19] = 1'b0;
    BTB_target[20] = 32'b0; BTB_tag[20] = 32'b0; BTB_j_flag[20] = 1'b0; BTB_b_flag[20] = 1'b0; BTB_valid[20] = 1'b0;
    BTB_target[21] = 32'b0; BTB_tag[21] = 32'b0; BTB_j_flag[21] = 1'b0; BTB_b_flag[21] = 1'b0; BTB_valid[21] = 1'b0;
    BTB_target[22] = 32'b0; BTB_tag[22] = 32'b0; BTB_j_flag[22] = 1'b0; BTB_b_flag[22] = 1'b0; BTB_valid[22] = 1'b0;
    BTB_target[23] = 32'b0; BTB_tag[23] = 32'b0; BTB_j_flag[23] = 1'b0; BTB_b_flag[23] = 1'b0; BTB_valid[23] = 1'b0;
    BTB_target[24] = 32'b0; BTB_tag[24] = 32'b0; BTB_j_flag[24] = 1'b0; BTB_b_flag[24] = 1'b0; BTB_valid[24] = 1'b0;
    BTB_target[25] = 32'b0; BTB_tag[25] = 32'b0; BTB_j_flag[25] = 1'b0; BTB_b_flag[25] = 1'b0; BTB_valid[25] = 1'b0;
    BTB_target[26] = 32'b0; BTB_tag[26] = 32'b0; BTB_j_flag[26] = 1'b0; BTB_b_flag[26] = 1'b0; BTB_valid[26] = 1'b0;
    BTB_target[27] = 32'b0; BTB_tag[27] = 32'b0; BTB_j_flag[27] = 1'b0; BTB_b_flag[27] = 1'b0; BTB_valid[27] = 1'b0;
    BTB_target[28] = 32'b0; BTB_tag[28] = 32'b0; BTB_j_flag[28] = 1'b0; BTB_b_flag[28] = 1'b0; BTB_valid[28] = 1'b0;
    BTB_target[29] = 32'b0; BTB_tag[29] = 32'b0; BTB_j_flag[29] = 1'b0; BTB_b_flag[29] = 1'b0; BTB_valid[29] = 1'b0;
    BTB_target[30] = 32'b0; BTB_tag[30] = 32'b0; BTB_j_flag[30] = 1'b0; BTB_b_flag[30] = 1'b0; BTB_valid[30] = 1'b0;
    BTB_target[31] = 32'b0; BTB_tag[31] = 32'b0; BTB_j_flag[31] = 1'b0; BTB_b_flag[31] = 1'b0; BTB_valid[31] = 1'b0;

    // initialize PHT to weakly taken
    PHT[0] = 2'b01; PHT[1] = 2'b01; PHT[2] = 2'b01; PHT[3] = 2'b01;
    PHT[4] = 2'b01; PHT[5] = 2'b01; PHT[6] = 2'b01; PHT[7] = 2'b01;
    PHT[8] = 2'b01; PHT[9] = 2'b01; PHT[10] = 2'b01; PHT[11] = 2'b01;
    PHT[12] = 2'b01; PHT[13] = 2'b01; PHT[14] = 2'b01; PHT[15] = 2'b01;
    PHT[16] = 2'b01; PHT[17] = 2'b01; PHT[18] = 2'b01; PHT[19] = 2'b01;
    PHT[20] = 2'b01; PHT[21] = 2'b01; PHT[22] = 2'b01; PHT[23] = 2'b01;
    PHT[24] = 2'b01; PHT[25] = 2'b01; PHT[26] = 2'b01; PHT[27] = 2'b01;
    PHT[28] = 2'b01; PHT[29] = 2'b01; PHT[30] = 2'b01; PHT[31] = 2'b01;

end

always @(posedge clk) begin
    tag_d <= btb_tag_in;
    tag_e <= tag_d;
end

always @(posedge clk) begin
    tag_match_d <= tag_match;
    tag_match_e <= tag_match_d;
    op_e <= op_i;
end

always @(*) begin
    if (BTB_valid[btb_index]) begin
        tag_match = (btb_tag_in == BTB_tag[btb_index]);
    end else begin
        tag_match = 1'b0;
    end
end

always @(posedge clk) begin
    // $display("[BTB INDEX] index=%0d", btb_index);
    // $display("[BTB TAG FROM PC] tag=%h", btb_tag_in);
    // $display("[BTB TAG FROM TABLE] tag=%h", BTB_tag[btb_index]);
    // $display("[BTB VALID] valid=%b", BTB_valid[btb_index]);
    
    $display("[BTB TAG E MATCH] match_e=%b", tag_match_e);
    $display("[BTB TAG DECODE MATCH] match=%b", tag_match);
    $display("[BTB INDEX EXECUTE] index=%0d", BTBwriteaddress_i);
    $display("[BTB TAG EXEC PC] tag=%h", tag_e);
    $display("[BTB EXEC TAG FROM TABLE] tag=%h", BTB_tag[BTBwriteaddress_i]);
    $display("[BTB EXEC VALID] valid=%b", BTB_valid[BTBwriteaddress_i]);

    if (BTB_we && !tag_match_e) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= tag_e;
        BTB_j_flag[BTBwriteaddress_i] <= (op_e == instr_jal_op || op_e == instr_jalr_op);
        BTB_b_flag[BTBwriteaddress_i] <= (op_e == instr_branch_op);
        BTB_valid[BTBwriteaddress_i]  <= 1'b1;

        $display("[BTB WRITE] index=%0d PC=%h target=%h op=%b j=%b b=%b", 
                 BTBwriteaddress_i, tag_e, BTBwritedata_i, op_e, 
                 (op_e == instr_jal_op || op_e == instr_jalr_op), 
                 (op_e == instr_branch_op));
    end
    
    $display("[BTB ENTRY] index=%0d tag=%h target=%h j=%b b=%b valid=%b",
                BTBwriteaddress_i, BTB_tag[BTBwriteaddress_i], BTB_target[BTBwriteaddress_i], 
                BTB_j_flag[BTBwriteaddress_i], BTB_b_flag[BTBwriteaddress_i], BTB_valid[BTBwriteaddress_i]);
end


wire [NUM_GHR_BITS-1:0] pc_xor_ghr = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
assign PHTreadaddress_o = pc_xor_ghr;

wire [1:0] pht_entry = PHT[pc_xor_ghr];
wire predict_taken = pht_entry[1];

wire [31:0] btb_target_bypass = BTB_target[btb_index];

assign btb_b = BTB_b_flag[btb_index];
assign btb_j = BTB_j_flag[btb_index];
assign btb_valid = BTB_valid[btb_index];

always @(*) begin
    if (tag_match && BTB_valid[btb_index]) begin
        BTBtarget_o = btb_target_bypass;
        BranchTaken_o = (BTB_b_flag[btb_index] && predict_taken) || BTB_j_flag[btb_index];
    end else begin
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end
always @(posedge clk) begin
    if (PHTwe_i) begin
        if (PHTincrement_i && PHT[PHTwriteaddress_i] < 2'b11)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        else if (!PHTincrement_i && PHT[PHTwriteaddress_i] > 2'b00)
            PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;

        $display("[PHT UPDATE] addr=%0d inc=%b new_value=%b", 
                 PHTwriteaddress_i, PHTincrement_i, PHT[PHTwriteaddress_i]);
    end
end

always @(posedge clk) begin
    if (reset_i || GHRreset_i)
        GHR <= 0;
    else if (op_i == instr_branch_op) begin
        GHR <= {GHR[NUM_GHR_BITS-2:0], ~PHTincrement_i};
        $display("[GHR UPDATE] new GHR=%b", {GHR[NUM_GHR_BITS-2:0], ~PHTincrement_i});
    end
end

endmodule
