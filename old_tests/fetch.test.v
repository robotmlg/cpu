`include "header.v"
`include "fetch.v"
`include "memory.v"
`include "sim.v"

//`define ADDRESS_WIDTH 32;

module test();

wire reset;
wire clk;

reg [`ADDRESS_WIDTH-1:0] mem_address;
wire [`DATA_WIDTH-1:0]   mem_data_out;

reg mem_valid;
wire mem_ready;
wire fetch_ready;
wire fetch_res_valid;
wire mem_res_valid;
reg [`MAX_INSTR_WIDTH-1:0] instr_out;
reg [3:0] instr_len;

// inter-module comms
// mem-fetch comms
wire mem_fetch_valid;
wire [`DATA_WIDTH-1:0] mem_fetch_data;
wire fetch_mem_valid;
wire [`ADDRESS_WIDTH-1:0] fetch_mem_addr;
// fetch-dec comms
wire dec_in_ready;


/*
always @(posedge clk) begin
  if (!reset && mem_ready) begin
    mem_valid <= 1;
  end

  if (!reset && mem_res_valid) begin
    mem_valid <= 0;
    mem_address += (`DATA_WIDTH / 8);
  end
end
*/

reg fake_mem_wire;

assign dec_in_ready = fake_mem_wire;

// simulate decode module
always @(posedge clk) begin
//    if(fetch_res_valid)
        fake_mem_wire = 1;
 //   else
  //      fake_mem_wire = 0;
end

// Simulator (clock + reset)
sim my_sim(
  .clk(clk),
  .reset(reset)
);

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

  .i_dec_ready(dec_in_ready),
  .o_res_valid(fetch_res_valid),
  .o_ready(fetch_ready),
  .o_instr(instr_out),
  .o_instr_len(instr_len)
);


endmodule
