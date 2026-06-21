// ============================================================
//  Module  : imm_gen
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    Extracts and sign-extends the immediate value from a
//    32-bit instruction, based on its format type.
//
//  Why this is needed:
//    RISC-V scatters immediate bits across different bit
//    positions depending on instruction type (I, S, B, J).
//    This was a deliberate ISA design choice to keep rs1,
//    rs2, and opcode in the SAME bit positions across all
//    formats, simplifying the decoder. The tradeoff is that
//    immediates must be reassembled by the hardware (or here,
//    by this combinational module).
//
//  Formats handled (RV32I subset used in this CPU):
//
//  I-type (addi, lw):
//    instr[31:20] = imm[11:0]   -- contiguous, easy case
//
//  S-type (sw):
//    instr[31:25] = imm[11:5]
//    instr[11:7]  = imm[4:0]    -- split across two fields
//
//  B-type (beq):
//    instr[31]    = imm[12]
//    instr[7]     = imm[11]
//    instr[30:25] = imm[10:5]
//    instr[11:8]  = imm[4:1]
//    imm[0] is ALWAYS 0 -- branch targets are always
//    2-byte aligned, so bit 0 isn't stored, just assumed 0.
//
//  J-type (jal):
//    instr[31]    = imm[20]
//    instr[19:12] = imm[19:12]
//    instr[20]    = imm[11]
//    instr[30:21] = imm[10:1]
//    imm[0] is ALWAYS 0, same reasoning as B-type.
//
//  Sign extension:
//    All immediates are sign-extended to 32 bits using the
//    instruction's MSB (instr[31]) as the sign bit -- this
//    bit is ALWAYS the sign bit in every RISC-V format,
//    another deliberate encoding simplification.
// ============================================================

module imm_gen (
    input  wire [31:0] instr,      // full 32-bit instruction
    input  wire [2:0]  imm_type,   // which format to decode
    output reg  [31:0] imm_out     // sign-extended immediate
);

    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_J = 3'b011;
    localparam IMM_U = 3'b100;   // for lui/auipc (bonus, not required for base subset)

    always @(*) begin
        case (imm_type)

            // ── I-type: imm[11:0] is already contiguous ──────
            // instr[31:20] -> imm[11:0]
            // Sign-extend using instr[31] (the sign bit)
            IMM_I: imm_out = {{20{instr[31]}}, instr[31:20]};

            // ── S-type: imm split into two pieces ─────────────
            // upper bits  instr[31:25] -> imm[11:5]
            // lower bits  instr[11:7]  -> imm[4:0]
            IMM_S: imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // ── B-type: imm split into FOUR pieces, bit0=0 ────
            // instr[31]    -> imm[12]  (sign bit)
            // instr[7]     -> imm[11]
            // instr[30:25] -> imm[10:5]
            // instr[11:8]  -> imm[4:1]
            // imm[0] is always 0 (branches are 2-byte aligned)
            IMM_B: imm_out = {{19{instr[31]}}, instr[31], instr[7],
                               instr[30:25], instr[11:8], 1'b0};

            // ── J-type: imm split into FOUR pieces, bit0=0 ────
            // instr[31]    -> imm[20]  (sign bit)
            // instr[19:12] -> imm[19:12]
            // instr[20]    -> imm[11]
            // instr[30:21] -> imm[10:1]
            // imm[0] is always 0
            IMM_J: imm_out = {{11{instr[31]}}, instr[31], instr[19:12],
                               instr[20], instr[30:21], 1'b0};

            // ── U-type: upper 20 bits, lower 12 bits are 0 ────
            // Used by lui/auipc -- not required for our base
            // subset but included for completeness
            IMM_U: imm_out = {instr[31:12], 12'b0};

            default: imm_out = 32'd0;
        endcase
    end

endmodule