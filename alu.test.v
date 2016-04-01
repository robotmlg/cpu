`include "alu.v"

module alu_test#(parameter TESTS=100)(
  input clk,
  input reset,
  input [2:0] op_in,

  output o_done
);
// Connecting wires
wire [31:0] alu_a;
wire [31:0] alu_b;
wire  [2:0] alu_cmd;

wire [31:0] alu_result;
wire        alu_res_valid;
wire        alu_ready;

// You can use arrays (even multidimensional
reg [32+32-1:0] tests [0:TESTS-1];
reg done = 1'b0;

// This is not synthetizable
integer i;


// Initial block
initial begin
  tests[0] <= {32'd0,32'd0};
  tests[1] <= {32'd0,32'd0};
  tests[2] <= {32'd0,32'd1};
  tests[3] <= {32'd1,32'd1};
  tests[4] <= {32'd2,32'd2};
  tests[5] <= {32'hffffffff,32'hffffffff};
  tests[6] <= {32'hffffffff,32'h0};
  tests[7] <= {32'h0,32'hffffffff};
  for(i = 8; i < TESTS; i = i + 1) begin
    tests[i] <= {{$random},{$random}};
  end
end

reg [31:0] t = 5'h0;

reg [31:0] a,b,res;
reg [2:0] op = `OP_NOP;

assign alu_a   = a;
assign alu_b   = b;
assign alu_cmd = op;
assign o_done  = done;


always @(posedge alu_res_valid) begin
  if (alu_result != res)
    $display("Result wrong!");
end

always @(posedge alu_ready) begin
    a <= tests[t][63:32];
    b <= tests[t][31:0];
    op <= op_in;

    case(op)
    `OP_NOP: res <= tests[t][63:32];
    `OP_SHL: res <= tests[t][63:32] << tests[t][31:0];
    `OP_SHR: res <= tests[t][63:32] >> tests[t][31:0];
    `OP_SHRA: res <= tests[t][63:32] >>> tests[t][31:0];
    `OP_ADD: res <= tests[t][63:32] + tests[t][31:0];
    `OP_SUB: res <= tests[t][63:32] - tests[t][31:0];
    `OP_MUL: res <= tests[t][63:32] * tests[t][31:0];
    `OP_DIV: res <= tests[t][63:32] / tests[t][31:0];
    default: $display("INVALID ALU COMMAND");
    endcase
    
    if (t + 1 < TESTS)
       t = t + 1;
    else begin
      t = 0;
      done = 1'b1;
    end
end


// alu module
alu my_alu
(
.clk(clk),
.reset(reset),

.i_a(alu_a),
.i_b(alu_b),
.i_cmd(alu_cmd),

.o_result(alu_result),
.o_valid(alu_res_valid),
.o_ready(alu_ready)
);

endmodule
