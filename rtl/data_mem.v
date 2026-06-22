// ============================================================
//  Module  : data_mem
//  Project : Single-Cycle RISC-V CPU (RV32I subset)
//  Author  : [Your Name]
//
//  Purpose :
//    Read/write data memory (RAM).
//    Used by lw (load word) and sw (store word) instructions.
//
//  Key points:
//    - Synchronous WRITE (on posedge clk) — data is written
//      at the clock edge when mem_write is asserted
//    - Combinational READ (async) — data is available
//      immediately when mem_read is asserted, no clock needed
//    - This is the standard single-cycle CPU memory model
//
//  Size: 64 words = 256 bytes
// ============================================================

module data_mem #(
    parameter MEM_SIZE = 64
)(
    input  wire        clk,
    input  wire [31:0] addr,       // byte address (from ALU result)
    input  wire [31:0] write_data, // data to store (rs2 value)
    input  wire        mem_write,  // 1 = store word
    input  wire        mem_read,   // 1 = load word
    output wire [31:0] read_data   // data loaded (goes to rd)
);

    reg [31:0] mem [0:MEM_SIZE-1];

    // Initialise to zero (important for simulation correctness)
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            mem[i] = 32'd0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[31:2]] <= write_data;
    end

    // Combinational read
    assign read_data = mem_read ? mem[addr[31:2]] : 32'd0;

endmodule