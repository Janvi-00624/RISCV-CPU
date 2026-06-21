// ============================================================
//  Module  : alu
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    32-bit ALU supporting the operations needed by our
//    RV32I instruction subset. The operation is selected by
//    alu_ctrl, NOT the raw instruction opcode/funct fields —
//    that translation happens in the control unit.
//
//  Why alu_ctrl instead of opcode/funct directly?
//    Multiple instructions can use the same ALU operation
//    (e.g. ADD is used by both 'add' and 'addi', and also
//    internally by 'lw'/'sw' to compute the memory address).
//    Decoupling the ALU's control signal from the raw
//    instruction fields keeps the ALU reusable and simple.
//
//  Operations:
//    alu_ctrl  Operation   Used by
//    000       ADD         add, addi, lw, sw, jal
//    001       SUB         sub, beq (subtract to compare)
//    010       AND         and, andi
//    011       OR          or, ori
//    100       XOR         xor, xori
//    101       SLT         slt, slti (set less than, signed)
//    110       SLL         sll (shift left logical)
//    111       SRL         srl (shift right logical)
// ============================================================

module alu (
    input  wire [31:0] a,         // operand A (rs1)
    input  wire [31:0] b,         // operand B (rs2 or immediate)
    input  wire [2:0]  alu_ctrl,  // operation select
    output reg  [31:0] result,    // ALU output
    output wire        zero       // result == 0 (used for BEQ)
);

    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam AND_OP = 3'b010;
    localparam OR_OP  = 3'b011;
    localparam XOR_OP = 3'b100;
    localparam SLT = 3'b101;
    localparam SLL = 3'b110;
    localparam SRL = 3'b111;

    always @(*) begin
        case (alu_ctrl)
            ADD:    result = a + b;
            SUB:    result = a - b;
            AND_OP: result = a & b;
            OR_OP:  result = a | b;
            XOR_OP: result = a ^ b;
            SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            SLL:    result = a << b[4:0];   // only low 5 bits of shift amount matter
            SRL:    result = a >> b[4:0];
            default: result = 32'd0;
        endcase
    end

    // zero flag — high when result is exactly 0
    // used by BEQ: if (rs1 - rs2 == 0) branch is taken
    assign zero = (result == 32'd0);

endmodule