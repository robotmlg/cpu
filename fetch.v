`ifndef FETCH_V
`define FETCH_V

`include "header.v"

// fetches an x86 instruction from memory
module fetch(
  input clk,
  input reset,

  // talking to memory module
  input i_mem_valid,
  input [`DATA_WIDTH-1:0] i_mem_data,
  output o_addr_valid,
  output [`ADDRESS_WIDTH-1:0] o_addr,

  // 
  input i_valid, // whether input data is valid
  input [`ADDRESS_WIDTH-1:0] i_pc, // next pc, if needed

  // sending to decode module
  output [`MAX_INSTR_WIDTH-1:0] o_instr, // max length 15 bytes
  output [3:0] o_instr_len, 
  output o_res_valid,
  output o_ready
);

// state matchine
reg [3:0] reg_status;
// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_INIT_PC    4'h2

reg ready;
reg res_valid;

// global info
reg [`ADDRESS_WIDTH-1:0] base_pc;

// info about current instruction
reg [`MAX_INSTR_WIDTH-1:0] instr;
reg [3:0] instr_len; // 1-15 B
reg [`ADDRESS_WIDTH-1:0] instr_address = `ADDRESS_WIDTH'h0; // the PC address
reg [`ADDRESS_WIDTH-1:0] next_address = `ADDRESS_WIDTH'h0;

// talking to memory
reg [`ADDRESS_WIDTH-1:0] cell_address;
reg addr_valid;
assign o_addr_valid = addr_valid;
assign o_addr = o_addr_valid ? cell_address : `ADDRESS_WIDTH'hx;

// output
assign o_res_valid = (res_valid && (reg_status == `ST_IDLE));
assign o_ready = (reg_status == `ST_IDLE) && !reset;
assign o_instr = o_res_valid ? instr : `MAX_INSTR_WIDTH'hx;
assign o_instr_len = o_res_valid ? instr_len : 4'hx;

// synchronous reset
always @(posedge clk && reset) begin
  reg_status <= `ST_RESET;
end

// fetch an instruction
always @(posedge clk) begin
  //$display("STATE = %d",reg_status);
  case (reg_status)
  `ST_RESET: begin
    reg_status = `ST_INIT_PC;
  end
  // get the PC from the first line intially
  `ST_INIT_PC: begin
    if (addr_valid == 1'b0) begin
      cell_address = `ADDRESS_WIDTH'b0;
      addr_valid = 1'b1;
    end

    if (i_mem_valid) begin
      base_pc = i_mem_data;
      addr_valid = 1'b0;
      $display("The PC is %x",base_pc);
    end
  end

  endcase

end



endmodule

`endif
