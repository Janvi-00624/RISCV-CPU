// ============================================================
//  Module  : control_unit
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    Decodes a RISC-V instruction and generates all control
//    signals needed to drive the datapath for that instruction.
//
//  Inputs (instruction fields):
//    opcode  [6:0]  — instruction family
//    funct3  [2:0]  — operation within family
//    funct7  [6:0]  — further qualification (ADD vs SUB etc.)
//
//  Outputs (control signals):
//    alu_ctrl  [2:0] — which ALU operation to perform
//    imm_type  [2:0] — which immediate format to decode
//    reg_write       — write result to rd in register file
//    mem_write       — write to data memory (sw)
//    mem_read        — read from data memory (lw)
//    mem_to_reg      — mux: write mem data (1) or ALU result (0) to rd
//    alu_src         — mux: ALU B input = imm (1) or rs2 (0)
//    branch          — instruction is a branch (beq)
//    jump            — instruction is jal
//
//  Supported opcodes (RV32I subset):
//    0110011 R-type  : add, sub, and, or, xor, slt, sll, srl
//    0010011 I-type  : addi, andi, ori, xori, slti
//    0000011 Load    : lw
//    0100011 Store   : sw
//    1100011 Branch  : beq
//    1101111 Jump    : jal
// ============================================================

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg  [2:0] alu_ctrl,
    output reg  [2:0] imm_type,
    output reg        reg_write,
    output reg        mem_write,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        jump
);

    // ── Opcode constants ─────────────────────────────────────
    localparam OP_R      = 7'b0110011;  // R-type arithmetic
    localparam OP_I      = 7'b0010011;  // I-type arithmetic
    localparam OP_LOAD   = 7'b0000011;  // lw
    localparam OP_STORE  = 7'b0100011;  // sw
    localparam OP_BRANCH = 7'b1100011;  // beq
    localparam OP_JAL    = 7'b1101111;  // jal

    // ── funct3 constants for R and I type ────────────────────
    localparam F3_ADD_SUB = 3'b000;
    localparam F3_SLL     = 3'b001;
    localparam F3_SLT     = 3'b010;
    localparam F3_XOR     = 3'b100;
    localparam F3_SRL     = 3'b101;
    localparam F3_OR      = 3'b110;
    localparam F3_AND     = 3'b111;

    // ── ALU control encodings (must match alu.v) ─────────────
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_SLT = 3'b101;
    localparam ALU_SLL = 3'b110;
    localparam ALU_SRL = 3'b111;

    // ── Immediate type encodings (must match imm_gen.v) ──────
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_J = 3'b011;

    always @(*) begin
        // ── Safe defaults (all signals off) ──────────────────
        // This prevents latches and ensures any unimplemented
        // opcode results in a safe no-operation
        alu_ctrl  = ALU_ADD;
        imm_type  = IMM_I;
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src   = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;

        case (opcode)

            // ── R-type: add, sub, and, or, xor, slt, sll, srl
            // ALU operates on two registers (rs1, rs2)
            // Result written back to rd
            OP_R: begin
                reg_write = 1'b1;    // write result to rd
                alu_src   = 1'b0;    // ALU B = rs2 (not immediate)
                case (funct3)
                    F3_ADD_SUB: alu_ctrl = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    // funct7[5]=1 means SUB, funct7[5]=0 means ADD
                    // This is how RISC-V distinguishes add from sub
                    // using the same opcode and funct3
                    F3_SLL:     alu_ctrl = ALU_SLL;
                    F3_SLT:     alu_ctrl = ALU_SLT;
                    F3_XOR:     alu_ctrl = ALU_XOR;
                    F3_SRL:     alu_ctrl = ALU_SRL;
                    F3_OR:      alu_ctrl = ALU_OR;
                    F3_AND:     alu_ctrl = ALU_AND;
                    default:    alu_ctrl = ALU_ADD;
                endcase
            end

            // ── I-type: addi, andi, ori, xori, slti
            // ALU operates on rs1 and a sign-extended immediate
            // Result written back to rd
            OP_I: begin
                reg_write = 1'b1;    // write result to rd
                alu_src   = 1'b1;    // ALU B = immediate
                imm_type  = IMM_I;
                case (funct3)
                    F3_ADD_SUB: alu_ctrl = ALU_ADD; // addi (no subi in RISC-V)
                    F3_SLL:     alu_ctrl = ALU_SLL;
                    F3_SLT:     alu_ctrl = ALU_SLT;
                    F3_XOR:     alu_ctrl = ALU_XOR;
                    F3_SRL:     alu_ctrl = ALU_SRL;
                    F3_OR:      alu_ctrl = ALU_OR;
                    F3_AND:     alu_ctrl = ALU_AND;
                    default:    alu_ctrl = ALU_ADD;
                endcase
            end

            // ── Load: lw
            // addr = rs1 + imm (ALU computes memory address)
            // Load result from data memory into rd
            OP_LOAD: begin
                reg_write  = 1'b1;   // write loaded data to rd
                alu_src    = 1'b1;   // ALU B = immediate (offset)
                mem_read   = 1'b1;   // read from data memory
                mem_to_reg = 1'b1;   // write memory data (not ALU result) to rd
                imm_type   = IMM_I;
                alu_ctrl   = ALU_ADD; // addr = rs1 + offset
            end

            // ── Store: sw
            // addr = rs1 + imm (ALU computes memory address)
            // Write rs2 value into data memory at computed addr
            OP_STORE: begin
                reg_write = 1'b0;    // no register write
                alu_src   = 1'b1;    // ALU B = immediate (offset)
                mem_write = 1'b1;    // write to data memory
                imm_type  = IMM_S;   // S-type immediate format
                alu_ctrl  = ALU_ADD; // addr = rs1 + offset
            end

            // ── Branch: beq
            // ALU subtracts rs1 - rs2
            // If zero flag is set (equal), PC += imm (branch taken)
            // If not, PC += 4 (branch not taken)
            OP_BRANCH: begin
                reg_write = 1'b0;    // no register write
                alu_src   = 1'b0;    // ALU B = rs2
                branch    = 1'b1;    // this is a branch instruction
                imm_type  = IMM_B;   // B-type immediate (branch offset)
                alu_ctrl  = ALU_SUB; // subtract to check equality
            end

            // ── Jump: jal
            // PC = PC + imm (unconditional jump)
            // rd = PC + 4  (save return address)
            OP_JAL: begin
                reg_write = 1'b1;    // write return address to rd
                jump      = 1'b1;    // this is a jump instruction
                imm_type  = IMM_J;   // J-type immediate (jump offset)
                alu_ctrl  = ALU_ADD; // not used for PC, but safe default
            end

            default: begin
                // Unknown opcode — all outputs stay at safe defaults
            end
        endcase
    end

endmodule