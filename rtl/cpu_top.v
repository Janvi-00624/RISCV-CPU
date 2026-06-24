module cpu_top(input clk, rst_n);
  reg  [31:0] pc;
  wire [31:0] instruction;
  instr_mem imem(.pc(pc),.instruction(instruction));

  wire [6:0] opcode=instruction[6:0];
  wire [4:0] rd=instruction[11:7], rs1=instruction[19:15], rs2=instruction[24:20];
  wire [2:0] funct3=instruction[14:12];
  wire [6:0] funct7=instruction[31:25];

  wire [2:0] alu_ctrl, imm_type;
  wire reg_write, mem_write, mem_read, mem_to_reg, alu_src, branch, jump;
  control_unit ctrl(.opcode(opcode),.funct3(funct3),.funct7(funct7),
    .alu_ctrl(alu_ctrl),.imm_type(imm_type),.reg_write(reg_write),
    .mem_write(mem_write),.mem_read(mem_read),.mem_to_reg(mem_to_reg),
    .alu_src(alu_src),.branch(branch),.jump(jump));

  wire [31:0] imm;
  imm_gen immgen(.instr(instruction),.imm_type(imm_type),.imm_out(imm));

  wire [31:0] rs1_data, rs2_data, rd_data;
  regfile rf(.clk(clk),.rst_n(rst_n),.rs1_addr(rs1),.rs2_addr(rs2),
    .rs1_data(rs1_data),.rs2_data(rs2_data),.rd_addr(rd),.rd_data(rd_data),.reg_write(reg_write));

  wire [31:0] alu_b = alu_src ? imm : rs2_data;
  wire [31:0] alu_result; wire zero;
  alu alu_inst(.a(rs1_data),.b(alu_b),.alu_ctrl(alu_ctrl),.result(alu_result),.zero(zero));

  wire [31:0] mem_read_data;
  data_mem dmem(.clk(clk),.addr(alu_result),.write_data(rs2_data),
    .mem_write(mem_write),.mem_read(mem_read),.read_data(mem_read_data));

  assign rd_data = mem_to_reg ? mem_read_data : alu_result;

  wire [31:0] pc_branch = pc + imm;
  wire branch_taken = branch & zero;
  wire [31:0] pc_next = jump ? pc_branch : branch_taken ? pc_branch : pc + 32'd4;

  always @(posedge clk) begin
    if (!rst_n) pc <= 32'd0;
    else        pc <= pc_next;
  end
endmodule