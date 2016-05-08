`include "cpu.v"
`include "sim.v"

//`define ADDRESS_WIDTH 32;

module test();

wire reset;
wire clk;



// Simulator (clock + reset)
sim my_sim(
  .clk(clk),
  .reset(reset)
);

cpu my_cpu(
    .clk(clk),
    .reset(reset)
);



endmodule
