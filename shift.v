`ifndef SHIFT_V
`define SHIFT_V
module left_shift(
  input [31:0] a,
  input [31:0] b,
  output [31:0] out
);
reg [31:0] reg_result;
wire [31:0] op_a, op_b;
assign out = reg_result;
assign op_a = a;
assign op_b = b;
always @(*)
begin
case(op_b)
6'd0: reg_result = op_a;
6'd1: reg_result = {op_a,1'b0};
6'd2: reg_result = {op_a,2'b0};
6'd3: reg_result = {op_a,3'b0};
6'd4: reg_result = {op_a,4'b0};
6'd5: reg_result = {op_a,5'b0};
6'd6: reg_result = {op_a,6'b0};
6'd7: reg_result = {op_a,7'b0};
6'd8: reg_result = {op_a,8'b0};
6'd9: reg_result = {op_a,9'b0};
6'd10: reg_result = {op_a,10'b0};
6'd11: reg_result = {op_a,11'b0};
6'd12: reg_result = {op_a,12'b0};
6'd13: reg_result = {op_a,13'b0};
6'd14: reg_result = {op_a,14'b0};
6'd15: reg_result = {op_a,15'b0};
6'd16: reg_result = {op_a,16'b0};
6'd17: reg_result = {op_a,17'b0};
6'd18: reg_result = {op_a,18'b0};
6'd19: reg_result = {op_a,19'b0};
6'd20: reg_result = {op_a,20'b0};
6'd21: reg_result = {op_a,21'b0};
6'd22: reg_result = {op_a,22'b0};
6'd23: reg_result = {op_a,23'b0};
6'd24: reg_result = {op_a,24'b0};
6'd25: reg_result = {op_a,25'b0};
6'd26: reg_result = {op_a,26'b0};
6'd27: reg_result = {op_a,27'b0};
6'd28: reg_result = {op_a,28'b0};
6'd29: reg_result = {op_a,29'b0};
6'd30: reg_result = {op_a,30'b0};
6'd31: reg_result = {op_a,31'b0};
default: reg_result = 32'd0;
endcase
end
endmodule
module log_right_shift(
  input [31:0] a,
  input [31:0] b,
  output [31:0] out
);
reg [31:0] reg_result;
wire [31:0] op_a, op_b;
assign out = reg_result;
assign op_a = a;
assign op_b = b;
always @(*)
begin
case(op_b)
6'd0: reg_result = op_a;
6'd1: reg_result = {1'b0,op_a[31:1]};
6'd2: reg_result = {2'b0,op_a[31:2]};
6'd3: reg_result = {3'b0,op_a[31:3]};
6'd4: reg_result = {4'b0,op_a[31:4]};
6'd5: reg_result = {5'b0,op_a[31:5]};
6'd6: reg_result = {6'b0,op_a[31:6]};
6'd7: reg_result = {7'b0,op_a[31:7]};
6'd8: reg_result = {8'b0,op_a[31:8]};
6'd9: reg_result = {9'b0,op_a[31:9]};
6'd10: reg_result = {10'b0,op_a[31:10]};
6'd11: reg_result = {11'b0,op_a[31:11]};
6'd12: reg_result = {12'b0,op_a[31:12]};
6'd13: reg_result = {13'b0,op_a[31:13]};
6'd14: reg_result = {14'b0,op_a[31:14]};
6'd15: reg_result = {15'b0,op_a[31:15]};
6'd16: reg_result = {16'b0,op_a[31:16]};
6'd17: reg_result = {17'b0,op_a[31:17]};
6'd18: reg_result = {18'b0,op_a[31:18]};
6'd19: reg_result = {19'b0,op_a[31:19]};
6'd20: reg_result = {20'b0,op_a[31:20]};
6'd21: reg_result = {21'b0,op_a[31:21]};
6'd22: reg_result = {22'b0,op_a[31:22]};
6'd23: reg_result = {23'b0,op_a[31:23]};
6'd24: reg_result = {24'b0,op_a[31:24]};
6'd25: reg_result = {25'b0,op_a[31:25]};
6'd26: reg_result = {26'b0,op_a[31:26]};
6'd27: reg_result = {27'b0,op_a[31:27]};
6'd28: reg_result = {28'b0,op_a[31:28]};
6'd29: reg_result = {29'b0,op_a[31:29]};
6'd30: reg_result = {30'b0,op_a[31:30]};
6'd31: reg_result = {31'b0,op_a[31]};
default: reg_result = 32'd0;
endcase
end
endmodule
module ari_right_shift(
  input [31:0] a,
  input [31:0] b,
  output [31:0] out
);
reg [31:0] reg_result;
wire [31:0] op_a, op_b;
assign out = reg_result;
assign op_a = a;
assign op_b = b;
always @(*)
begin
case(op_b)
6'd0: reg_result = op_a;
6'd1: reg_result = {op_a[31:1]};
6'd2: reg_result = {op_a[31:2]};
6'd3: reg_result = {op_a[31:3]};
6'd4: reg_result = {op_a[31:4]};
6'd5: reg_result = {op_a[31:5]};
6'd6: reg_result = {op_a[31:6]};
6'd7: reg_result = {op_a[31:7]};
6'd8: reg_result = {op_a[31:8]};
6'd9: reg_result = {op_a[31:9]};
6'd10: reg_result = {op_a[31:10]};
6'd11: reg_result = {op_a[31:11]};
6'd12: reg_result = {op_a[31:12]};
6'd13: reg_result = {op_a[31:13]};
6'd14: reg_result = {op_a[31:14]};
6'd15: reg_result = {op_a[31:15]};
6'd16: reg_result = {op_a[31:16]};
6'd17: reg_result = {op_a[31:17]};
6'd18: reg_result = {op_a[31:18]};
6'd19: reg_result = {op_a[31:19]};
6'd20: reg_result = {op_a[31:20]};
6'd21: reg_result = {op_a[31:21]};
6'd22: reg_result = {op_a[31:22]};
6'd23: reg_result = {op_a[31:23]};
6'd24: reg_result = {op_a[31:24]};
6'd25: reg_result = {op_a[31:25]};
6'd26: reg_result = {op_a[31:26]};
6'd27: reg_result = {op_a[31:27]};
6'd28: reg_result = {op_a[31:28]};
6'd29: reg_result = {op_a[31:29]};
6'd30: reg_result = {op_a[31:30]};
default: reg_result = {32{op_a[31]}};
endcase
end
endmodule
`endif
