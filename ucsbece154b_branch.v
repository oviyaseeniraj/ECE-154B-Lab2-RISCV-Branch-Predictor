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
reg [31:0] BTB [0:NUM_BTB_ENTRIES-1];   // Target addresses
reg [31:0] BTB_tags [0:NUM_BTB_ENTRIES-1]; // Tags for BTB entries (upper PC bits)
reg [NUM_BTB_ENTRIES-1:0] BTB_J;  // Unconditional jump flag per entry
reg [NUM_BTB_ENTRIES-1:0] BTB_B;  // Conditional branch flag per entry

// Gshare predictor implementation
reg [NUM_GHR_BITS-1:0] GHR; //global history register
reg [1:0] PHT [0:(1<<NUM_GHR_BITS)-1];  // pattern history table for 2-bit saturating counters

// BTB read logic - happens in the fetch stage
wire [$clog2(NUM_BTB_ENTRIES)-1:0] BTB_index = pc_i[$clog2(NUM_BTB_ENTRIES)+1:2]; // index from PC
wire [31:0] BTB_tag = pc_i[31:$clog2(NUM_BTB_ENTRIES)+2]; // tag from upper PC bits
wire BTB_hit = (BTB_tags[BTB_index] == BTB_tag) && (BTB_J[BTB_index] || BTB_B[BTB_index]); // BTB hit if tag matches and entry is valid (either jump or branch)

// PHT index calculation
assign PHTreadaddress_o = GHR ^ pc_i[NUM_GHR_BITS+1:2]; // XOR GHR with PC bits (excluding 2 LSBs since instructions are word-aligned)

// Branch prediction logic
wire is_branch = (op_i == instr_branch_op); // Detect branch instructions
wire is_jump = (op_i == instr_jal_op) || (op_i == instr_jalr_op); // Detect jump instructions

always @(*) begin
    if (BTB_hit) begin
        // On BTB hit, use stored target and make prediction
        BTBtarget_o = BTB[BTB_index];
        // For jumps (unconditional), always predict taken
        // For branches, use MSB of PHT counter (1=taken, 0=not taken)
        BranchTaken_o = BTB_J[BTB_index] ? 1'b1 : PHT[PHTreadaddress_o][1];
    end else begin
        // On BTB miss, predict not taken
        BTBtarget_o = 32'b0;
        BranchTaken_o = 1'b0;
    end
end

// BTB write logic - execute stage
always @(posedge clk) begin
    // Reset all BTB entries
    if (reset_i) begin
        // Reset all BTB entries
        BTB_J <= {NUM_BTB_ENTRIES{1'b0}};
        BTB_B <= {NUM_BTB_ENTRIES{1'b0}};
    end else if (BTB_we) begin
        // Write new entry to BTB (from execute stage)
        // BTBwritedata_i format: [65:64] = {B,J} flags, [63:32] = tag, [31:0] = target
        BTB[BTBwriteaddress_i] <= BTBwritedata_i[31:0];         // Target address
        BTB_tags[BTBwriteaddress_i] <= BTBwritedata_i[63:32];   // Tag
        BTB_J[BTBwriteaddress_i] <= BTBwritedata_i[64];     // Unconditional jump flag 
        BTB_B[BTBwriteaddress_i] <= BTBwritedata_i[65];     // Conditional branch flag
    end
end

// GHR update logic
always @(posedge clk) begin
    if (reset_i || GHRreset_i) begin
        // Reset GHR on processor reset or branch misprediction
        GHR <= {NUM_GHR_BITS{1'b0}};
    end else if (is_branch || is_jump) begin
        // Speculatively update GHR with prediction outcome
        // Shift in 1 for taken, 0 for not taken
        GHR <= {GHR[NUM_GHR_BITS-2:0], BranchTaken_o};
    end
end

// PHT update logic - execute stage
always @(posedge clk) begin
    integer i;
    if (reset_i) begin
        // Initialize all PHT counters to weakly not-taken (01)
        for (i = 0; i < (1<<NUM_GHR_BITS); i = i + 1)
            PHT[i] <= 2'b00;
    end else if (PHTwe_i) begin
        // Update PHT counter based on actual branch outcome
        if (PHTincrement_i) begin
            // Increment counter (toward taken) but saturate at 3 (11)
            if (PHT[PHTwriteaddress_i] != 2'b11)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] + 1;
        end else begin
            // Decrement counter (toward not-taken) but saturate at 0 (00)
            if (PHT[PHTwriteaddress_i] != 2'b00)
                PHT[PHTwriteaddress_i] <= PHT[PHTwriteaddress_i] - 1;
        end
    end
end

endmodule
