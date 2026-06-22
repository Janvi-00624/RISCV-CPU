// ============================================================
//  Module  : instr_mem
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    Read-only instruction memory (ROM).
//    Holds the program the CPU will execute.
//    Outputs the 32-bit instruction at address PC.
//
//  Key points:
//    - Combinational read (no clock needed — purely async)
//    - Word-addressed: PC is byte address, we access word at PC/4
//    - In simulation, loaded from a $readmemh hex file
//    - On FPGA, synthesises to block RAM or distributed RAM
//
//  Size: 64 words = 256 bytes (enough for small test programs)
// ============================================================

module instr_mem #(
    parameter MEM_SIZE = 64   // number of 32-bit words
)(
    input  wire [31:0] pc,          // program counter (byte address)
    output wire [31:0] instruction  // instruction at pc
);

    reg [31:0] mem [0:MEM_SIZE-1];

    // Load program from hex file at simulation start
    // Format: one 32-bit hex value per line, e.g. 00500093
    initial begin
        $readmemh("programs/program.hex", mem);
    end

    // Combinational read — word addressed (PC >> 2)
    // PC is a byte address; divide by 4 to get word index
    assign instruction = mem[pc[31:2]];

endmodule