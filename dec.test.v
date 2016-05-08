`include "old_decode.v.bak"
`include "sim.v"

`define ADDRESS_WIDTH 32
`define DATA_WIDTH 32

module test();

wire reset;
wire clk;

reg [`ADDRESS_WIDTH-1:0] mem_address = 0;
wire [`DATA_WIDTH-1:0]   mem_data_out;

reg mem_valid;
wire mem_ready;
wire mem_res_valid;

always @(posedge clk) begin
  if (!reset && mem_ready) begin
    mem_valid <= 1;
  end

  if (!reset && mem_res_valid) begin
    mem_valid <= 0;
    mem_address += (`DATA_WIDTH / 8);
  end
end

// decoder module
instr_dec #(`ADDRESS_WIDTH, `DATA_WIDTH) my_dec(
  .clk(clk),
  .reset(reset),

  .i_res_ready(1'b1), //we are always ready to receive data
  .i_valid(1'b1),

  .o_res_valid(mem_res_valid),
  .o_ready(mem_ready)
);

// Simulator (clock + reset)
sim my_sim(
  .clk(clk),
  .reset(reset)
);

endmodule
