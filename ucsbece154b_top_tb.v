// ucsbece154b_top_tb.v
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


`define SIM

`define ASSERT(CONDITION, MESSAGE) if ((CONDITION)==1'b1); else begin $error($sformatf MESSAGE); end

module ucsbece154b_top_tb ();

// test bench contents
reg clk = 1;
always #1 clk <= ~clk;
reg reset;

ucsbece154b_top top (
    .clk(clk), .reset(reset)
);

wire [31:0] reg_zero = top.riscv.dp.rf.zero;
wire [31:0] reg_ra = top.riscv.dp.rf.ra;
wire [31:0] reg_sp = top.riscv.dp.rf.sp;
wire [31:0] reg_gp = top.riscv.dp.rf.gp;
wire [31:0] reg_tp = top.riscv.dp.rf.tp;
wire [31:0] reg_t0 = top.riscv.dp.rf.t0;
wire [31:0] reg_t1 = top.riscv.dp.rf.t1;
wire [31:0] reg_t2 = top.riscv.dp.rf.t2;
wire [31:0] reg_s0 = top.riscv.dp.rf.s0;
wire [31:0] reg_s1 = top.riscv.dp.rf.s1;
wire [31:0] reg_a0 = top.riscv.dp.rf.a0;
wire [31:0] reg_a1 = top.riscv.dp.rf.a1;
wire [31:0] reg_a2 = top.riscv.dp.rf.a2;
wire [31:0] reg_a3 = top.riscv.dp.rf.a3;
wire [31:0] reg_a4 = top.riscv.dp.rf.a4;
wire [31:0] reg_a5 = top.riscv.dp.rf.a5;
wire [31:0] reg_a6 = top.riscv.dp.rf.a6;
wire [31:0] reg_a7 = top.riscv.dp.rf.a7;
wire [31:0] reg_s2 = top.riscv.dp.rf.s2;
wire [31:0] reg_s3 = top.riscv.dp.rf.s3;
wire [31:0] reg_s4 = top.riscv.dp.rf.s4;
wire [31:0] reg_s5 = top.riscv.dp.rf.s5;
wire [31:0] reg_s6 = top.riscv.dp.rf.s6;
wire [31:0] reg_s7 = top.riscv.dp.rf.s7;
wire [31:0] reg_s8 = top.riscv.dp.rf.s8;
wire [31:0] reg_s9 = top.riscv.dp.rf.s9;
wire [31:0] reg_s10 = top.riscv.dp.rf.s10;
wire [31:0] reg_s11 = top.riscv.dp.rf.s11;
wire [31:0] reg_t3 = top.riscv.dp.rf.t3;
wire [31:0] reg_t4 = top.riscv.dp.rf.t4;
wire [31:0] reg_t5 = top.riscv.dp.rf.t5;
wire [31:0] reg_t6 = top.riscv.dp.rf.t6;

// wire [31:0] MEM_10000000 = top.dmem.DATA[6'd0];

//

integer i;
initial begin
$display( "Begin simulation." );
//\\ =========================== \\//

reset = 1;
@(negedge clk);
@(negedge clk);
reset = 0;

// Test for program 
for (i = 0; i < 200; i=i+1)
    @(negedge clk);

// WRITE YOUR TEST HERE

// `ASSERT(rg_zero==32'b0, ("reg_zero incorrect"));
// `ASSERT(MEM_10000070==32'hBEEF000, ("mem.DATA[29] //incorrect"));
    // Verify register values after program execution
    // Check that x (t0) remains 1
    `ASSERT(reg_t0==32'd1, ("Register t0 (x) should remain 1, got %0d", reg_t0));
    
    // Check countx (s0) - should be 10 since x is always 1
    `ASSERT(reg_s0==32'd10, ("Register s0 (countx) should be 10, got %0d", reg_s0));
    
    // Check county (s1) - should be 5 since y is 1 on odd outer iterations (5 odd numbers 0-9)
    `ASSERT(reg_s1==32'd5, ("Register s1 (county) should be 5, got %0d", reg_s1));
    
    // Check countz (s2) - should be 5 since z = x&y and x is always 1
    `ASSERT(reg_s2==32'd5, ("Register s2 (countz) should be 5, got %0d", reg_s2));
    
    // Check innercount (s3) - should be 40 (10 outer loops * 4 inner loops)
    `ASSERT(reg_s3==32'd40, ("Register s3 (innercount) should be 40, got %0d", reg_s3));
    
    // Check outer loop counter (t3) - should be 10 (loop exit condition)
    `ASSERT(reg_t3==32'd10, ("Register t3 (outer) should be 10, got %0d", reg_t3));
    
    // Check that zero register remains 0
    `ASSERT(reg_zero==32'b0, ("Register zero should remain 0, got %0d", reg_zero));



//\\ =========================== \\//
$display( "End simulation.");
$stop;
end

endmodule

`undef ASSERT
