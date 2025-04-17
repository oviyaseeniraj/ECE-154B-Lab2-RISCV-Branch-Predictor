// ucsbece154_branch.v
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


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

// BTB implementation
reg [31:0] BTB [0:NUM_BTB_ENTRIES-1];
reg [31:0] BTB_tags [0:NUM_BTB_ENTRIES-1];
reg [NUM_BTB_ENTRIES-1:0] BTB_J;  // Unconditional jump flag
reg [NUM_BTB_ENTRIES-1:0] BTB_B;  // Conditional branch flag

// Gshare predictor implementation
reg [NUM_GHR_BITS-1:0] GHR;
reg [1:0] PHT [0:(1<<NUM_GHR_BITS)-1];  // 2-bit saturating counters

// BTB read logic
wire [$clog2(NUM_BTB_ENTRIES)-1:0] BTB_index = pc_i[$clog2(NUM_BTB_ENTRIES)+1:2];
wire [31:0] BTB_tag = pc_i[31:$clog2(NUM_BTB_ENTRIES)+2];
wire BTB_hit = (BTB_tags[BTB_index] == BTB_tag) && (BTB_J[BTB_index] || BTB_B[BTB_index]);

// PHT index calculation
assign PHTreadaddress_o = GHR ^ pc_i[NUM_GHR_BITS+1:2];

// Branch prediction logic
wire is_branch = (op_i == instr_branch_op);
wire is_jump = (op_i == instr_jal_op) || (op_i == instr_jalr_op);

always @(*) begin
    if (BTB_hit) begin
        BTBtarget_o = BTB[BTB_index];
        // Use PHT prediction for branches, always taken for jumps
        BranchTaken_o = BTB_J[BTB_index] ? 1'b1 : PHT[PHTreadaddress_o][1];
    end else begin
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end

// BTB write logic
always @(posedge clk) begin
    if (reset_i) begin
        BTB_J <= {NUM_BTB_ENTRIES{1'b0}};
        BTB_B <= {NUM_BTB_ENTRIES{1'b0}};
    end else if (BTB_we) begin
        BTB[BTBwriteaddress_i] <= BTBwritedata_i[31:0];
        BTB_tags[BTBwriteaddress_i] <= BTBwritedata_i[63:32];
        BTB_J[BTBwriteaddress_i] <= BTBwritedata_i[64];
        BTB_B[BTBwriteaddress_i] <= BTBwritedata_i[65];
    end
end

// GHR update logic
always @(posedge clk) begin
    if (reset_i || GHRreset_i) begin
        GHR <= {NUM_GHR_BITS{1'b0}};
    end else if (is_branch || is_jump) begin
        // Speculative update
        GHR <= {GHR[NUM_GHR_BITS-2:0], BranchTaken_o};
    end
end

// PHT update logic
always @(posedge clk) begin
    if (reset_i) begin
        for (integer i = 0; i < (1<<NUM_GHR_BITS); i = i + 1)
            PHT[i] <= 2'b00;
    end else if (PHTwe_i) begin
        if (PHTincrement_i) begin
            // Increment saturating counter
            if (PHT[PHTwriteaddress_i] != 2'b11)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        end else begin
            // Decrement saturating counter
            if (PHT[PHTwriteaddress_i] != 2'b00)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;
        end
    end
end

endmodule
