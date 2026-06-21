// ============================================================
//  Testbench : tb_regfile
//  Tests:
//    1. Reset clears all registers
//    2. Basic write then read
//    3. x0 always reads 0, even after attempting to write it
//    4. Writing to x0 does not corrupt other registers
//    5. Two simultaneous reads (rs1, rs2) work independently
//    6. reg_write=0 means no write happens
//    7. Write and read same register in same/adjacent cycles
// ============================================================
`timescale 1ns/1ps

module tb_regfile;
    reg         clk=0, rst_n=0;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    reg         reg_write;
    wire [31:0] rs1_data, rs2_data;

    regfile dut (
        .clk(clk), .rst_n(rst_n),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .rd_addr(rd_addr), .rd_data(rd_data), .reg_write(reg_write)
    );

    always #5 clk=~clk;

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s", label); pass=pass+1; end
            else      begin $display("  FAIL: %0s", label); fail=fail+1; end
        end
    endtask

    // Helper: write a value to a register
    task write_reg; input [4:0] addr; input [31:0] data;
        begin
            @(posedge clk);
            rd_addr = addr; rd_data = data; reg_write = 1;
            @(posedge clk);
            reg_write = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/regfile.vcd");
        $dumpvars(0, tb_regfile);
        $display("\n=== Register File Testbench ===\n");

        rs1_addr=0; rs2_addr=0; rd_addr=0; rd_data=0; reg_write=0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ── Test 1: All registers start at 0 after reset ────
        $display("[Test 1] Reset clears registers");
        rs1_addr = 5'd5; rs2_addr = 5'd10; #1;
        check(rs1_data===32'd0, "x5 reads 0 after reset");
        check(rs2_data===32'd0, "x10 reads 0 after reset");

        // ── Test 2: Basic write then read ─────────────────────
        $display("[Test 2] Write then read");
        write_reg(5'd5, 32'hDEADBEEF);
        rs1_addr = 5'd5; #1;
        check(rs1_data===32'hDEADBEEF, "x5 reads back written value");

        // ── Test 3: x0 always reads 0 ─────────────────────────
        $display("[Test 3] x0 hardwired to zero");
        write_reg(5'd0, 32'hFFFFFFFF);  // attempt to write x0
        rs1_addr = 5'd0; #1;
        check(rs1_data===32'd0, "x0 still reads 0 after write attempt");

        // ── Test 4: Writing x0 doesn't corrupt neighbours ─────
        $display("[Test 4] x0 write doesn't affect x1");
        write_reg(5'd1, 32'h12345678);  // set x1 to known value
        write_reg(5'd0, 32'hABCDEF00);  // attempt to overwrite x0
        rs1_addr = 5'd1; #1;
        check(rs1_data===32'h12345678, "x1 unaffected by x0 write attempt");

        // ── Test 5: Simultaneous independent reads ────────────
        $display("[Test 5] Two simultaneous reads");
        write_reg(5'd2, 32'hAAAAAAAA);
        write_reg(5'd3, 32'hBBBBBBBB);
        rs1_addr = 5'd2; rs2_addr = 5'd3; #1;
        check(rs1_data===32'hAAAAAAAA, "rs1 reads x2 correctly");
        check(rs2_data===32'hBBBBBBBB, "rs2 reads x3 correctly (simultaneous)");

        // ── Test 6: reg_write=0 means no write ────────────────
        $display("[Test 6] No write when reg_write=0");
        @(posedge clk);
        rd_addr=5'd7; rd_data=32'hCAFEBABE; reg_write=0; // write disabled
        @(posedge clk);
        rs1_addr = 5'd7; #1;
        check(rs1_data===32'd0, "x7 stays 0 when reg_write was 0");

        // ── Test 7: Multiple registers, full sweep ────────────
        $display("[Test 7] Write and verify all 31 writable registers");
        begin : sweep
            integer i;
            reg all_ok;
            all_ok = 1;
            for (i = 1; i < 32; i = i + 1) begin
                write_reg(i[4:0], i * 32'h11111111);
            end
            for (i = 1; i < 32; i = i + 1) begin
                rs1_addr = i[4:0]; #1;
                if (rs1_data !== i * 32'h11111111) all_ok = 0;
            end
            check(all_ok===1'b1, "all 31 registers hold correct independent values");
        end

        $display("\n=== %0d passed, %0d failed ===\n", pass, fail);
        if (fail==0) $display("Register file verified! Ready for immediate generator.\n");
        $finish;
    end
    initial begin #100000; $display("TIMEOUT"); $finish; end
endmodule