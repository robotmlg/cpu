`ifndef CPU_V
`define CPU_V

`include "header.v"
`include "memory.v"
`include "fetch.v"
`include "decode.v"
`include "mem_stage.v"
`include "execute.v"
`include "writeback.v"

//`define ADDRESS_WIDTH 32;

module cpu(
    input clk,
    input reset
);

wire mem_ready;
wire fetch_ready;
wire dec_ready;

// inter-module comms
// mem-fetch comms
wire mem_fetch_valid;
wire [`DATA_WIDTH-1:0] mem_fetch_data;
wire fetch_mem_valid;
wire [`ADDRESS_WIDTH-1:0] fetch_mem_addr;
// fetch-dec comms
wire fetch_res_valid;
wire dec_fetch_ready;
wire [`MAX_INSTR_WIDTH-1:0] instr_out;
wire [3:0] instr_len;
wire [`ADDRESS_WIDTH-1:0] instr_pc;
// dec-mem comms
wire dec_res_valid;
wire [`ADDRESS_WIDTH-1:0] dec_mem_pc;
wire [7:0] dec_mem_opcode;
wire [8:0] dec_mem_opDEST_flags;
wire [`ADDRESS_WIDTH-1:0] dec_mem_opDEST_data;
wire [3:0] dec_mem_opDEST_reg;
wire [4:0] dec_mem_opDEST_scale;
wire [3:0] dec_mem_opDEST_base_reg;
wire [8:0] dec_mem_opSRC_flags;
wire [`ADDRESS_WIDTH-1:0] dec_mem_opSRC_data;
wire [3:0] dec_mem_opSRC_reg;
wire [4:0] dec_mem_opSRC_scale;
wire [3:0] dec_mem_opSRC_base_reg;
wire mem_dec_ready;
// mem_stg-exec comms
wire mem_exec_valid;
wire exec_mem_ready;
wire [`ADDRESS_WIDTH-1:0] mem_exec_pc;
wire [7:0] mem_exec_opcode;
wire [`DATA_WIDTH-1:0] mem_exec_opA;
wire [`DATA_WIDTH-1:0] mem_exec_opB;
wire [3:0] mem_exec_dest_reg;
wire [`ADDRESS_WIDTH-1:0] mem_exec_dest_addr;
// exec-wb comms
wire exec_wb_valid;
wire wb_exec_ready;
wire [7:0] exec_wb_opcode;
wire [`DATA_WIDTH-1:0] exec_wb_value;
wire [3:0] exec_wb_dest_reg;
wire [`ADDRESS_WIDTH-1:0] exec_wb_dest_addr;


// memory module
memory instr_mem(
  .clk(clk),
  .reset(reset),

  .i_valid(fetch_mem_valid),
  .i_address(fetch_mem_addr),
  .i_res_ready(1'b1),
  .i_cmd(`MEM_CMD_READ),
  .i_data(`DATA_WIDTH'bx),//no write data

  .o_data(mem_fetch_data),
  .o_res_valid(mem_fetch_valid),
  .o_ready(mem_ready)
);

// fetch module
fetch my_fetch(
    .clk(clk),
    .reset(reset),

    .i_pc_valid(1'b0),
    .i_pc(`ADDRESS_WIDTH'h0),

    // mem-fetch comms
    .i_mem_valid(mem_fetch_valid),
    .i_mem_data(mem_fetch_data),
    .o_addr_valid(fetch_mem_valid),
    .o_addr(fetch_mem_addr),

    // fetch-dec comms
    .i_dec_ready(dec_fetch_ready),
    .o_res_valid(fetch_res_valid),
    .o_instr(instr_out),
    .o_instr_len(instr_len),
    .o_pc(instr_pc),

    .o_ready(fetch_ready)
);

// decode module
decode my_dec(
    .clk(clk),
    .reset(reset),

    //fetch-decode comms
    .i_instr_valid(fetch_res_valid),
    .i_instr(instr_out),
    .i_instr_len(instr_len),
    .i_pc(instr_pc),
    .o_fetching(dec_fetch_ready),

    // decode-execute comms
    .i_next_ready(mem_dec_ready),
    .o_pc(dec_mem_pc),
    .o_opcode(dec_mem_opcode),

    .o_opDEST_flags(dec_mem_opDEST_flags),
    .o_opDEST_data(dec_mem_opDEST_data),
    .o_opDEST_reg(dec_mem_opDEST_reg),
    .o_opDEST_scale(dec_mem_opDEST_scale),
    .o_opDEST_base_reg(dec_mem_opDEST_base_reg),
    .o_opSRC_flags(dec_mem_opSRC_flags),
    .o_opSRC_data(dec_mem_opSRC_data),
    .o_opSRC_reg(dec_mem_opSRC_reg),
    .o_opSRC_scale(dec_mem_opSRC_scale),
    .o_opSRC_base_reg(dec_mem_opSRC_base_reg),

    .o_res_valid(dec_res_valid),
    .o_ready(dec_ready)
);

memory_stage my_mem_stg(
    .clk(clk),
    .reset(reset),
    
    .i_input_valid(dec_res_valid),
    .i_pc(dec_mem_pc),
    .i_opcode(dec_mem_opcode),
    .i_opDEST_flags(dec_mem_opDEST_flags),
    .i_opDEST_data(dec_mem_opDEST_data),
    .i_opDEST_reg(dec_mem_opDEST_reg),
    .i_opDEST_scale(dec_mem_opDEST_scale),
    .i_opDEST_base_reg(dec_mem_opDEST_base_reg),
    .i_opSRC_flags(dec_mem_opSRC_flags),
    .i_opSRC_data(dec_mem_opSRC_data),
    .i_opSRC_reg(dec_mem_opSRC_reg),
    .i_opSRC_scale(dec_mem_opSRC_scale),
    .i_opSRC_base_reg(dec_mem_opSRC_base_reg),
    .o_fetching(mem_dec_ready),

    .i_next_ready(exec_mem_ready),
    .o_res_valid(mem_exec_valid),
    .o_pc(mem_exec_pc),
    .o_opcode(mem_exec_opcode),
    .o_opA(mem_exec_opA),
    .o_opB(mem_exec_opB),
    .o_dest_reg(mem_exec_dest_reg),
    .o_dest_addr(mem_exec_dest_addr),
    .o_ready()
);

execute my_exec(
    .clk(clk),
    .reset(reset),

    // mem-exec comms
    .i_input_valid(mem_exec_valid),
    .i_pc(mem_exec_pc),
    .i_opcode(mem_exec_opcode),
    .i_opA(mem_exec_opA),
    .i_opB(mem_exec_opB),
    .i_dest_reg(mem_exec_dest_reg),
    .i_dest_addr(mem_exec_dest_addr),
    .o_fetching(exec_mem_ready),

    .i_next_ready(wb_exec_ready),
    .o_res_valid(exec_wb_valid),
    .o_opcode(exec_wb_opcode),
    .o_res(exec_wb_value),
    .o_dest_reg(exec_wb_dest_reg),
    .o_dest_addr(exec_wb_dest_addr),

    .o_ready()
);

writeback my_wb(
    .clk(clk),
    .reset(reset),

    // exec-wb
    .i_input_valid(exec_wb_valid),
    .i_opcode(exec_wb_opcode),
    .i_val(exec_wb_value),
    .i_dest_reg(exec_wb_dest_reg),
    .i_dest_addr(exec_wb_dest_addr),
    .o_fetching(wb_exec_ready),

    .o_ready()
);


endmodule
`endif
