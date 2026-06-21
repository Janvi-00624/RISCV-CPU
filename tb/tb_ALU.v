// ============================================================
//  Testbench : tb_alu
//  Tests every ALU operation including signed edge cases
// ============================================================
`timescale 1ns/1ps

module tb_alu;
    reg  [31:0] a, b;
    reg  [2:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s", label); pass=pass+1; end
            else      begin $display("  FAIL: %0s", label); fail=fail+1; end
        end
    endtask

    initial begin
        $display("\n=== ALU Testbench ===\n");

        // ADD
        a=32'd10; b=32'd5; alu_ctrl=3'b000; #1;
        check(result===32'd15, "ADD: 10+5=15");
        check(zero===1'b0, "ADD: zero flag low when nonzero");

        // ADD resulting in zero
        a=32'd0; b=32'd0; alu_ctrl=3'b000; #1;
        check(result===32'd0, "ADD: 0+0=0");
        check(zero===1'b1, "ADD: zero flag high when result is 0");

        // SUB
        a=32'd10; b=32'd5; alu_ctrl=3'b001; #1;
        check(result===32'd5, "SUB: 10-5=5");

        // SUB equal operands -> zero (used by BEQ)
        a=32'd7; b=32'd7; alu_ctrl=3'b001; #1;
        check(zero===1'b1, "SUB: equal operands give zero=1 (BEQ taken)");

        // AND
        a=32'hFF00FF00; b=32'h0F0F0F0F; alu_ctrl=3'b010; #1;
        check(result===32'h0F000F00, "AND: bitwise and correct");

        // OR
        a=32'hF0F0F0F0; b=32'h0F0F0F0F; alu_ctrl=3'b011; #1;
        check(result===32'hFFFFFFFF, "OR: bitwise or correct");

        // XOR
        a=32'hFFFFFFFF; b=32'hFFFFFFFF; alu_ctrl=3'b100; #1;
        check(result===32'h00000000, "XOR: identical operands give 0");

        // SLT - positive numbers
        a=32'd3; b=32'd5; alu_ctrl=3'b101; #1;
        check(result===32'd1, "SLT: 3<5 -> 1");

        a=32'd5; b=32'd3; alu_ctrl=3'b101; #1;
        check(result===32'd0, "SLT: 5<3 -> 0");

        // SLT - signed negative numbers (critical edge case)
        a=-32'd5; b=32'd3; alu_ctrl=3'b101; #1;
        check(result===32'd1, "SLT: -5<3 -> 1 (signed comparison)");

        a=32'd3; b=-32'd5; alu_ctrl=3'b101; #1;
        check(result===32'd0, "SLT: 3<-5 -> 0 (signed comparison)");

        // SLL
        a=32'h00000001; b=32'd4; alu_ctrl=3'b110; #1;
        check(result===32'h00000010, "SLL: 1<<4=16");

        // SRL
        a=32'h00000010; b=32'd4; alu_ctrl=3'b111; #1;
        check(result===32'h00000001, "SRL: 16>>4=1");

        $display("\n=== %0d passed, %0d failed ===\n", pass, fail);
        if (fail==0) $display("ALU verified! Ready for register file.\n");
        $finish;
    end
endmodule