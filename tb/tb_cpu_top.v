// ============================================================
//  Testbench : tb_cpu_top
//  Runs the test program and checks register values after
//  each instruction executes. This proves the CPU works end
//  to end — fetch, decode, execute, memory, write-back.
//
//  Expected register state after program completes:
//    x1 = 5      (addi x1, x0, 5)
//    x2 = 3      (addi x2, x0, 3)
//    x3 = 8      (add  x3, x1, x2)
//    x4 = 8      (lw   x4, 0(x0))
//    x5 = 1      (addi x5, x0, 1 — after branch skips x5=0)
// ============================================================
`timescale 1ns/1ps

module tb_cpu_top;
    reg clk=0, rst_n=0;
    always #5 clk=~clk;

    cpu_top dut(.clk(clk), .rst_n(rst_n));

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s",label); pass=pass+1; end
            else      begin $display("  FAIL: %0s",label); fail=fail+1; end
        end
    endtask

    // Helper to read a register directly from DUT regfile
    // (uses hierarchical path — only works in simulation)
    function [31:0] read_reg;
        input [4:0] idx;
        read_reg = dut.rf.registers[idx];
    endfunction

    integer i;

    initial begin
        $dumpfile("sim/cpu_top.vcd");
        $dumpvars(0, tb_cpu_top);
        $display("\n=== RISC-V CPU Top Testbench ===\n");
        $display("Program: compute 5+3, store/load, branch test\n");

        // Reset for 3 cycles
        rst_n = 0;
        repeat(3) @(posedge clk);
        rst_n = 1;

        // Run for enough cycles to execute all 9 instructions
        // Single-cycle: 1 instruction per clock
        // Give 15 cycles total to be safe (last instruction loops)
        repeat(15) @(posedge clk);

        $display("[Check] Register file after program execution:");
        $display("  x1 = %0d (expect 5)",  read_reg(1));
        $display("  x2 = %0d (expect 3)",  read_reg(2));
        $display("  x3 = %0d (expect 8)",  read_reg(3));
        $display("  x4 = %0d (expect 8)",  read_reg(4));
        $display("  x5 = %0d (expect 1)",  read_reg(5));
        $display("");

        check(read_reg(1)===32'd5, "x1=5  (addi x1,x0,5)");
        check(read_reg(2)===32'd3, "x2=3  (addi x2,x0,3)");
        check(read_reg(3)===32'd8, "x3=8  (add x3,x1,x2)");
        check(read_reg(4)===32'd8, "x4=8  (lw x4,0(x0) — memory roundtrip)");
        check(read_reg(5)===32'd1, "x5=1  (branch taken, skip x5=0, execute x5=1)");
        check(read_reg(0)===32'd0, "x0=0  (hardwired zero, never changes)");

        // Also check data memory directly
        $display("\n[Check] Data memory:");
        $display("  mem[0] = %0d (expect 8)", dut.dmem.mem[0]);
        check(dut.dmem.mem[0]===32'd8, "mem[0]=8 (sw x3,0(x0) stored correctly)");

        // Print PC trace — show where CPU got to
        $display("\n[Check] Final PC = 0x%08h (expect 0x20 — loop)", dut.pc);
        check(dut.pc===32'h20, "PC halted at jal loop (0x20)");

        $display("\n=== %0d passed, %0d failed ===\n", pass, fail);
        if (fail==0)
            $display("CPU WORKS! All instructions execute correctly.\n");
        else
            $display("Some checks failed. Review waveforms in GTKWave.\n");

        $finish;
    end

    // Print PC and instruction every cycle for debugging
    initial begin
        @(posedge rst_n);
        $display("Cycle-by-cycle execution trace:");
        $display("  Cycle | PC   | Instruction");
        repeat(12) begin
            @(posedge clk); #1;
            $display("        | %04h | %08h", dut.pc, dut.instruction);
        end
    end

    initial begin #10000; $display("TIMEOUT"); $finish; end
endmodule