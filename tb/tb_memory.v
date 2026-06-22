`timescale 1ns/1ps
module tb_memory;
    reg clk=0; always #5 clk=~clk;

    reg  [31:0] pc;
    wire [31:0] instruction;
    instr_mem imem(.pc(pc),.instruction(instruction));

    reg  [31:0] addr, write_data;
    reg         mem_write, mem_read;
    wire [31:0] read_data;
    data_mem dmem(.clk(clk),.addr(addr),.write_data(write_data),
                  .mem_write(mem_write),.mem_read(mem_read),.read_data(read_data));

    integer pass=0, fail=0;
    task check; input cond; input [127:0] label;
        begin
            if (cond) begin $display("  PASS: %0s",label); pass=pass+1; end
            else      begin $display("  FAIL: %0s",label); fail=fail+1; end
        end
    endtask

    initial begin
        $display("\n=== Memory Testbench ===\n");
        mem_write=0; mem_read=0; addr=0; write_data=0;

        $display("[Test 1] Instruction memory reads");
        pc=32'd0; #1; check(instruction===32'h00500093, "PC=0: addi x1,x0,5");
        pc=32'd4; #1; check(instruction===32'h00300113, "PC=4: addi x2,x0,3");
        pc=32'd8; #1; check(instruction===32'h002081b3, "PC=8: add x3,x1,x2");

        $display("[Test 2] Data memory write then read");
        addr=32'd0; write_data=32'hDEADBEEF; mem_write=1;
        @(posedge clk); #1;          // write happens at clock edge
        mem_write=0; mem_read=1; #1; // now read
        check(read_data===32'hDEADBEEF, "data mem: write then read back");

        $display("[Test 3] Write multiple addresses");
        addr=32'd4; write_data=32'hCAFEBABE; mem_write=1;
        @(posedge clk); #1;
        mem_write=0; mem_read=1; #1;
        check(read_data===32'hCAFEBABE, "data mem: second address correct");

        addr=32'd0; #1;
        check(read_data===32'hDEADBEEF, "data mem: first address undisturbed");

        $display("[Test 4] mem_read=0 returns 0");
        mem_read=0; #1;
        check(read_data===32'd0, "read_data=0 when mem_read=0");

        $display("\n=== %0d passed, %0d failed ===\n",pass,fail);
        if(fail==0) $display("Memory verified! Ready for cpu_top.\n");
        $finish;
    end
endmodule