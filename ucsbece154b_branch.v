module ucsbece154b_branch #(
    parameter NUM_BTB_ENTRIES = 32,
    parameter NUM_GHR_BITS    = 5
) (
    input               clk, 
    input               reset_i,
    input        [31:0] pc_i,
    input  [$clog2(NUM_BTB_ENTRIES)-1:0] BTBwriteaddress_i,
    input        [65:0] BTBwritedata_i,   
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
    is_branch = (op_i == instr_branch_op);
    is_jump   = (op_i == instr_jal_op) || (op_i == instr_jalr_op);
    if (reset_i) begin
        integer i;
        for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
            BTB_target[i] <= 32'b0;
            BTB_tag[i]    <= 32'b0;
            BTB_J[i]      <= 1'b0;
            BTB_B[i]      <= 1'b0;
        end
    end else if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_tag[BTBwriteaddress_i]    <= pc_i[31:$clog2(NUM_BTB_ENTRIES)+2];

        // Set J/B flags based on op_i
        BTB_J[BTBwriteaddress_i] <= is_jump;
        BTB_B[BTBwriteaddress_i] <= is_branch;
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
        integer i;
        for (i = 0; i < (1 << NUM_GHR_BITS); i = i + 1)
            PHT[i] <= 2'b01; // weakly not taken
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
