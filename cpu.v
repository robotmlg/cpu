`ifndef CPU_V
`define CPU_V

`include "header.v"
`include "memory.v"
`include "fetch.v"
`include "decode.v"

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
wire [`MAX_INSTR_WIDTH-1:0] instr_out;
wire [3:0] instr_len;
// dec-exec comms
wire dec_res_valid;

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
    .i_dec_ready(dec_ready),
    .o_res_valid(fetch_res_valid),
    .o_instr(instr_out),
    .o_instr_len(instr_len),

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

    // decode-execute comms
    .i_next_ready(1'b0),
    .o_res_valid(dec_res_valid),
    .o_ready(dec_ready)
);

endmodule
`endif
