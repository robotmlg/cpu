`ifndef ALU_V
`define ALU_V

`include "header.v"
`include "full_add.v"
`include "mul.v"
`include "shift.v"

`define OP_NOP   3'b000
`define OP_SHL   3'b001
`define OP_SHR   3'b010
`define OP_SHRA  3'b011
`define OP_ADD   3'b100
`define OP_SUB   3'b101
`define OP_MUL   3'b110
`define OP_DIV   3'b111

// Simple single cycle alu
module alu(
  input clk,
  input reset,
  
  input [`DATA_WIDTH-1:0] i_a,    // 1st operand
  input [`DATA_WIDTH-1:0] i_b,    // 2nd operand
  input  [2:0] i_cmd,  // command

  output [`DATA_WIDTH-1:0] o_result,
  output        o_valid, // result is valid

  output        o_ready  // ready to take input
);

reg [`DATA_WIDTH-1:0] reg_result;
reg        reg_valid = 1'b0;

wire [`DATA_WIDTH-1:0] op_a;
wire [`DATA_WIDTH-1:0] op_b;

wire [`DATA_WIDTH-1:0] sum;
wire c_out;
wire [63:0] prod;
wire [`DATA_WIDTH-1:0] shl_out;
wire [`DATA_WIDTH-1:0] shr_out;
wire [`DATA_WIDTH-1:0] shra_out;

// ALU state machine macros
`define ST_RESET  2'h0
`define ST_READY  2'h1
`define ST_BUSY   2'h2

// begin in reset state
reg [1:0] reg_status = `ST_RESET;

// Synchronous reset
always @(posedge clk && reset) begin
  reg_status <= `ST_READY;
end

// Assign outputs
assign o_ready = ((reg_status == `ST_READY) && !reset);
assign o_valid = (reg_valid && (reg_status == `ST_READY));
assign o_result = o_valid ? reg_result : 32'hx; // Ternary operator


// Fix inputs
assign op_a = i_a;
assign op_b = i_cmd == `OP_SUB ? -i_b : i_b;

// Main processing loop
always @(posedge clk && !reset) begin

  case (reg_status)
  `ST_READY: begin
    reg_status <= `ST_BUSY;

    casez (i_cmd)
    `OP_SHL: reg_result = shl_out;
    `OP_SHR: reg_result = shr_out;
    `OP_SHRA: reg_result = shra_out;
    3'b10?:  reg_result = {c_out,sum}; // OP_ADD and OP_SUB
    `OP_MUL: reg_result = prod;
    `OP_DIV: reg_result = i_a / i_b;
    default: reg_result = i_a;
    endcase

  end
  `ST_BUSY: begin
    reg_valid <= 1'b1;
    reg_status <= `ST_READY;
  end
  default: begin
    $display("should not happen");
    $finish;
  end
  endcase

end

full_add my_add_sub
(
.a(op_a),
.b(op_b),
.c_in(1'b0),
.c_out(c_out),
.sum(sum)
);

mul my_mul
(
.a(op_a),
.b(op_b),
.prod(prod)
);

left_shift my_shl
(
.a(op_a),
.b(op_b),
.out(shl_out)
);

log_right_shift my_shr
(
.a(op_a),
.b(op_b),
.out(shr_out)
);

ari_right_shift my_shra
(
.a(op_a),
.b(op_b),
.out(shra_out)
);
endmodule

`endif
