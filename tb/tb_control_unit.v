// ============================================================
//  Testbench : tb_control_unit
//  Tests every supported instruction for correct control signals
// ============================================================
`timescale 1ns/1ps

module tb_control_unit;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire [2:0] alu_ctrl, imm_type;
    wire       reg_write, mem_write, mem_read;
    wire       mem_to_reg, alu_src, branch, jump;

    control_unit dut (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .alu_ctrl(alu_ctrl), .imm_type(imm_type),
        .reg_write(reg_write), .mem_write(mem_write),
        .mem_read(mem_read), .mem_to_reg(mem_to_reg),
        .alu_src(alu_src), .branch(branch), .jump(jump)
    );

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s", label); pass=pass+1; end
            else      begin $display("  FAIL: %0s", label); fail=fail+1; end
        end
    endtask

    initial begin
        $display("\n=== Control Unit Testbench ===\n");

        // ── add x1, x2, x3 ───────────────────────────────────
        $display("[Test 1] add (R-type)");
        opcode=7'b0110011; funct3=3'b000; funct7=7'b0000000; #1;
        check(alu_ctrl===3'b000, "ADD: alu_ctrl=ADD");
        check(reg_write===1'b1,  "ADD: reg_write=1");
        check(alu_src===1'b0,    "ADD: alu_src=0 (rs2)");
        check(mem_write===1'b0,  "ADD: mem_write=0");
        check(branch===1'b0,     "ADD: branch=0");
        check(jump===1'b0,       "ADD: jump=0");

        // ── sub x1, x2, x3 ───────────────────────────────────
        $display("[Test 2] sub (R-type)");
        opcode=7'b0110011; funct3=3'b000; funct7=7'b0100000; #1;
        check(alu_ctrl===3'b001, "SUB: alu_ctrl=SUB (funct7[5]=1)");
        check(reg_write===1'b1,  "SUB: reg_write=1");

        // ── and, or, xor ─────────────────────────────────────
        $display("[Test 3] and/or/xor (R-type)");
        opcode=7'b0110011; funct7=7'b0000000;
        funct3=3'b111; #1; check(alu_ctrl===3'b010, "AND: alu_ctrl=AND");
        funct3=3'b110; #1; check(alu_ctrl===3'b011, "OR:  alu_ctrl=OR");
        funct3=3'b100; #1; check(alu_ctrl===3'b100, "XOR: alu_ctrl=XOR");

        // ── slt ──────────────────────────────────────────────
        $display("[Test 4] slt (R-type)");
        opcode=7'b0110011; funct3=3'b010; funct7=7'b0000000; #1;
        check(alu_ctrl===3'b101, "SLT: alu_ctrl=SLT");

        // ── addi x1, x2, 100 ─────────────────────────────────
        $display("[Test 5] addi (I-type)");
        opcode=7'b0010011; funct3=3'b000; funct7=7'b0; #1;
        check(alu_ctrl===3'b000, "ADDI: alu_ctrl=ADD");
        check(reg_write===1'b1,  "ADDI: reg_write=1");
        check(alu_src===1'b1,    "ADDI: alu_src=1 (immediate)");
        check(imm_type===3'b000, "ADDI: imm_type=I");
        check(branch===1'b0,     "ADDI: branch=0");

        // ── lw x1, 0(x2) ─────────────────────────────────────
        $display("[Test 6] lw (Load)");
        opcode=7'b0000011; funct3=3'b010; funct7=7'b0; #1;
        check(alu_ctrl===3'b000,  "LW: alu_ctrl=ADD (addr calc)");
        check(reg_write===1'b1,   "LW: reg_write=1");
        check(alu_src===1'b1,     "LW: alu_src=1 (immediate offset)");
        check(mem_read===1'b1,    "LW: mem_read=1");
        check(mem_to_reg===1'b1,  "LW: mem_to_reg=1 (memory to rd)");
        check(mem_write===1'b0,   "LW: mem_write=0");

        // ── sw x1, 0(x2) ─────────────────────────────────────
        $display("[Test 7] sw (Store)");
        opcode=7'b0100011; funct3=3'b010; funct7=7'b0; #1;
        check(alu_ctrl===3'b000,  "SW: alu_ctrl=ADD (addr calc)");
        check(reg_write===1'b0,   "SW: reg_write=0 (no rd write)");
        check(alu_src===1'b1,     "SW: alu_src=1 (immediate offset)");
        check(mem_write===1'b1,   "SW: mem_write=1");
        check(mem_read===1'b0,    "SW: mem_read=0");
        check(imm_type===3'b001,  "SW: imm_type=S");

        // ── beq x1, x2, offset ───────────────────────────────
        $display("[Test 8] beq (Branch)");
        opcode=7'b1100011; funct3=3'b000; funct7=7'b0; #1;
        check(alu_ctrl===3'b001,  "BEQ: alu_ctrl=SUB (compare)");
        check(reg_write===1'b0,   "BEQ: reg_write=0");
        check(alu_src===1'b0,     "BEQ: alu_src=0 (rs2)");
        check(branch===1'b1,      "BEQ: branch=1");
        check(mem_write===1'b0,   "BEQ: mem_write=0");
        check(imm_type===3'b010,  "BEQ: imm_type=B");

        // ── jal x1, offset ───────────────────────────────────
        $display("[Test 9] jal (Jump)");
        opcode=7'b1101111; funct3=3'b000; funct7=7'b0; #1;
        check(reg_write===1'b1,   "JAL: reg_write=1 (save return addr)");
        check(jump===1'b1,        "JAL: jump=1");
        check(branch===1'b0,      "JAL: branch=0");
        check(imm_type===3'b011,  "JAL: imm_type=J");

        // ── Unknown opcode — safe defaults ───────────────────
        $display("[Test 10] Unknown opcode");
        opcode=7'b1111111; funct3=3'b0; funct7=7'b0; #1;
        check(reg_write===1'b0,   "Unknown: reg_write=0 (safe)");
        check(mem_write===1'b0,   "Unknown: mem_write=0 (safe)");
        check(branch===1'b0,      "Unknown: branch=0 (safe)");
        check(jump===1'b0,        "Unknown: jump=0 (safe)");

        $display("\n=== %0d passed, %0d failed ===\n", pass, fail);
        if (fail==0) $display("Control unit verified! Ready for memory modules.\n");
        $finish;
    end
endmodule