// ============================================================
//  Module  : regfile
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    32 x 32-bit general purpose register file.
//    RV32I has 32 registers: x0 through x31.
//
//  Ports:
//    2 READ ports  — combinational, no clock needed.
//                    Most instructions read two source
//                    registers (rs1, rs2) in the same cycle.
//    1 WRITE port  — synchronous, happens on clk edge.
//                    Only one register can be written per cycle.
//
//  Critical RISC-V rule:
//    Register x0 is hardwired to the constant 0.
//    - Reading x0 ALWAYS returns 0, no matter what was
//      "written" to it.
//    - Writing to x0 is a legal operation but has NO EFFECT.
//    This is used as a trick in real RISC-V code: e.g.
//    'add x0, x0, x0' is effectively a NOP (no-operation).
//
//  Interface:
//    clk        — system clock
//    rst_n      — active-low reset (clears all registers to 0)
//    rs1_addr   — address of first source register to read
//    rs2_addr   — address of second source register to read
//    rs1_data   — value read from rs1 (combinational)
//    rs2_data   — value read from rs2 (combinational)
//    rd_addr    — address of destination register to write
//    rd_data    — value to write into rd
//    reg_write  — write enable (1 = perform the write this cycle)
// ============================================================

module regfile (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,

    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        reg_write
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    // ── Synchronous write ────────────────────────────────────
    // Loop variable for reset
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            // Clear all registers to 0 on reset
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else begin
            // Write only if reg_write is asserted AND
            // the destination is not x0 (x0 is read-only)
            if (reg_write && (rd_addr != 5'd0)) begin
                registers[rd_addr] <= rd_data;
            end
            // If rd_addr == 0, this write is silently ignored.
            // registers[0] always stays 0 because we never
            // write to it, AND we explicitly force its read
            // value to 0 below regardless.
        end
    end

    // ── Combinational reads ──────────────────────────────────
    // x0 is hardwired to 0 — force this at the READ side too,
    // as a second safety net (belt and suspenders design).
    // Even if something went wrong and registers[0] was
    // somehow non-zero, reads of x0 would still return 0.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

endmodule