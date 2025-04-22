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
reg tag_match = 0;
reg btb_entry_valid = 0;

reg [31:0] tag_d, tag_e;

always @(posedge clk) begin
    tag_d <= btb_tag_in;
    tag_e <= tag_d;
end

initial begin
    BTB_valid[btb_index] = 1'b0;
    BTB_tag[btb_index] = 32'b0;
end

always @(posedge clk) begin
    $display("[BTB INDEX] index=%0d", btb_index);
    $display("[BTB TAG FROM PC] tag=%h", btb_tag_in);
    $display("[BTB TAG FROM TABLE] tag=%h", BTB_tag[btb_index]);
    tag_match <= BTB_valid[btb_index];
    if (BTB_valid[btb_index]) begin
        tag_match <= (btb_tag_in == BTB_tag[btb_index]);
    end else begin
        tag_match <= 1'b0;
    end
    $display("[BTB TAG MATCH] match=%b", tag_match);
    btb_entry_valid <= BTB_valid[btb_index];

    if (BTB_we && !tag_match) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= tag_e;
        BTB_j_flag[BTBwriteaddress_i] <= (op_i == instr_jal_op || op_i == instr_jalr_op);
        BTB_b_flag[BTBwriteaddress_i] <= (op_i == instr_branch_op);
        BTB_valid[BTBwriteaddress_i]  <= 1'b1;

        $display("[BTB WRITE] index=%0d PC=%h target=%h op=%b j=%b b=%b", 
                 BTBwriteaddress_i, pc_i, BTBwritedata_i, op_i, 
                 (op_i == instr_jal_op || op_i == instr_jalr_op), 
                 (op_i == instr_branch_op));
        
        $display("[BTB ENTRY] index=%0d tag=%h target=%h j=%b b=%b valid=%b",
                 BTBwriteaddress_i, BTB_tag[BTBwriteaddress_i], BTB_target[BTBwriteaddress_i], 
                 BTB_j_flag[BTBwriteaddress_i], BTB_b_flag[BTBwriteaddress_i], BTB_valid[BTBwriteaddress_i]);
    end
end


wire [NUM_GHR_BITS-1:0] pc_xor_ghr = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
assign PHTreadaddress_o = pc_xor_ghr;

wire [1:0] pht_entry = PHT[pc_xor_ghr];
wire predict_taken = pht_entry[1];

wire [31:0] btb_target_bypass = (BTB_we && BTBwriteaddress_i == btb_index) ? 
                                BTBwritedata_i : BTB_target[btb_index];

always @(*) begin
    //tag_match <= (btb_tag_in == BTB_tag[btb_index]);
    if (tag_match && btb_entry_valid) begin
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
