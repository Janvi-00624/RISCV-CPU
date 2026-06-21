// ============================================================
//  Testbench : tb_imm_gen
//  Tests all 4 immediate formats with hand-calculated
//  expected values, including negative (sign-extended) cases.
// ============================================================
`timescale 1ns/1ps

module tb_imm_gen;
    reg  [31:0] instr;
    reg  [2:0]  imm_type;
    wire [31:0] imm_out;

    imm_gen dut (.instr(instr), .imm_type(imm_type), .imm_out(imm_out));

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s", label); pass=pass+1; end
            else      begin $display("  FAIL: %0s", label); fail=fail+1; end
        end
    endtask

    initial begin
        $display("\n=== Immediate Generator Testbench ===\n");

        // ── I-type tests ───────────────────────────────────
        // addi x1, x0, 100
        // imm = 100 = 0x064, positive, fits easily in 12 bits
        // Instruction encoding: imm[11:0]=100, rs1=0, funct3=0, rd=1, opcode=0010011
        $display("[Test 1] I-type: addi with positive immediate 100");
        instr = {12'd100, 5'd0, 3'b000, 5'd1, 7'b0010011};
        imm_type = 3'b000; #1;
        check(imm_out===32'd100, "I-type imm=100 decoded correctly");

        // addi x1, x0, -1  (imm = -1 = all 1s)
        $display("[Test 2] I-type: addi with negative immediate -1");
        instr = {12'hFFF, 5'd0, 3'b000, 5'd1, 7'b0010011};
        imm_type = 3'b000; #1;
        check(imm_out===32'hFFFFFFFF, "I-type imm=-1 sign-extended correctly");

        // lw x2, -4(x1)  (imm = -4)
        $display("[Test 3] I-type: lw with negative offset -4");
        instr = {12'hFFC, 5'd1, 3'b010, 5'd2, 7'b0000011};
        imm_type = 3'b000; #1;
        check(imm_out===32'hFFFFFFFC, "I-type imm=-4 sign-extended correctly");

        // ── S-type tests ───────────────────────────────────
        // sw x2, 100(x1)  (imm = 100 = 0b000001100100)
        // imm[11:5] = 0000011, imm[4:0] = 00100
        $display("[Test 4] S-type: sw with positive offset 100");
        instr = {7'b0000011, 5'd2, 5'd1, 3'b010, 5'b00100, 7'b0100011};
        imm_type = 3'b001; #1;
        check(imm_out===32'd100, "S-type imm=100 reassembled correctly");

        // sw x2, -4(x1)  (imm = -4 = all 1s in lower 12 bits)
        $display("[Test 5] S-type: sw with negative offset -4");
        instr = {7'b1111111, 5'd2, 5'd1, 3'b010, 5'b11100, 7'b0100011};
        imm_type = 3'b001; #1;
        check(imm_out===32'hFFFFFFFC, "S-type imm=-4 sign-extended correctly");

        // ── B-type tests ───────────────────────────────────
        // beq x1, x2, +8  (imm=8=0b0000000001000, bit0 always 0)
        // imm[12]=0 imm[11]=0 imm[10:5]=000000 imm[4:1]=0100
        $display("[Test 6] B-type: beq with positive offset +8");
        instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011};
        imm_type = 3'b010; #1;
        check(imm_out===32'd8, "B-type imm=+8 reassembled correctly");

        // beq x1, x2, -8 (backward branch)
        // imm=-8: in 13-bit signed = 1 1111111 1000 (imm[12]=1, rest pattern for -8)
        // -8 = 0b1111111111000 (13 bits two's complement)
        $display("[Test 7] B-type: beq with negative offset -8 (backward branch)");
        instr = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b000, 4'b1100, 1'b1, 7'b1100011};
        imm_type = 3'b010; #1;
        check(imm_out===32'hFFFFFFF8, "B-type imm=-8 sign-extended correctly");

        // ── J-type tests ───────────────────────────────────
        // jal x1, +16  (imm=16=0b00000000000010000, bit0 always 0)
        // imm[20]=0 imm[19:12]=00000000 imm[11]=0 imm[10:1]=0001000
        $display("[Test 8] J-type: jal with positive offset +16");
        instr = {1'b0, 10'b0000001000, 1'b0, 8'b00000000, 5'd1, 7'b1101111};
        imm_type = 3'b011; #1;
        check(imm_out===32'd16, "J-type imm=+16 reassembled correctly");

        // jal x1, -16 (backward jump)
        $display("[Test 9] J-type: jal with negative offset -16");
        instr = {1'b1, 10'b1111111000, 1'b1, 8'b11111111, 5'd1, 7'b1101111};
        imm_type = 3'b011; #1;
        check(imm_out===32'hFFFFFFF0, "J-type imm=-16 sign-extended correctly");

        $display("\n=== %0d passed, %0d failed ===\n", pass, fail);
        if (fail==0) $display("Immediate generator verified! Ready for control unit.\n");
        $finish;
    end
endmodule