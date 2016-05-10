`ifndef EXECUTE_V
`define EXECUTE_V

`include "header.v"
`include "alu.v"

// executes the instruction with the alu
module execute(
    input clk,
    input reset,

    // mem-exec comms
    input i_input_valid,
    input [`ADDRESS_WIDTH-1:0] i_pc,
    input [7:0] i_opcode,
    input [`DATA_WIDTH-1:0] i_opA,
    input [`DATA_WIDTH-1:0] i_opB,
    input [3:0] i_dest_reg,
    input [`ADDRESS_WIDTH-1:0] i_dest_addr,

    output o_fetching,

    // execute-writeback comms
    input i_next_ready,
    output o_res_valid,
    output [7:0] o_opcode,
    output [`DATA_WIDTH-1:0] o_res,
    output [3:0] o_dest_reg,
    output [`ADDRESS_WIDTH-1:0] o_dest_addr,

    output o_ready
);

// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_NEW_INST   4'h2
`define ST_EXEC       4'h3
`define ST_END_INST   4'hF

// status registers
reg ready;
reg res_valid;
reg fetching;
reg state_idle;

// FSM registers
reg [3:0] reg_status = `ST_RESET;
reg [3:0] nxt_status = `ST_IDLE;


// info about current instruction
reg [`ADDRESS_WIDTH-1:0] curr_pc;
reg [7:0] opcode;
reg [`DATA_WIDTH-1:0] opA;
reg [`DATA_WIDTH-1:0] opB;
reg [3:0] dest_reg;
reg [3:0] dest_addr;


// inter-stage registers
reg [`DATA_WIDTH-1:0] res;
reg [7:0] out_opcode;
reg [3:0] out_dest_reg;
reg [`ADDRESS_WIDTH-1:0] out_dest_addr;

// alu comms
wire [`DATA_WIDTH-1:0] req_opA;
wire [`DATA_WIDTH-1:0] req_opB;
wire [2:0] req_cmd;
wire [`DATA_WIDTH-1:0] resp_res;
wire resp_valid;
wire alu_ready;


assign o_res_valid = res_valid;
assign o_ready = ready;
assign o_fetching = fetching;
assign o_opcode = out_opcode;
assign o_res = res;
assign o_dest_reg = out_dest_reg;
assign o_dest_addr = out_dest_addr;


// synchronous reset
always @(posedge clk && reset) begin
  reg_status <= `ST_RESET;
end

// synchronous retrieve instruction
always @(posedge clk && i_input_valid) begin
    if(state_idle) begin
        reg_status = `ST_NEW_INST;
        fetching = 1;
    end
    else
        fetching = 0;
end


// when the buffer is full and the next stage is ready, pass the data
always @(posedge clk && i_next_ready && res_valid && !reset) begin
    res_valid <= #20 0; // TODO: find a less hacky way to do this
end


// execute the instructions
always @(posedge clk) begin
    //$display("STATE = %d",reg_status);
    case (reg_status)
    `ST_RESET: begin
        reg_status = `ST_IDLE;
        res_valid = 0;
        fetching = 1;
        curr_pc = 0;
    end
    `ST_IDLE: begin
        state_idle = 1;
        if (res_valid == 0 && curr_pc != 0) begin
            res_valid = 1;
            out_opcode = opcode;
            out_dest_reg = dest_reg;
            out_dest_addr = dest_addr;

        end
    end
    `ST_NEW_INST: begin
        $display("Getting ops!");
        state_idle = 0;
        opcode = i_opcode;
        curr_pc = i_pc;
        opA = i_opA;
        opB = i_opB;
        dest_reg = i_dest_reg;
        dest_addr = i_dest_addr;

        reg_status = `ST_EXEC;
    end
    `ST_EXEC: begin
        case(opcode)
        `OPC_XOR: begin
            $display("XORing the SHIT out of those operands");
            res = opA ^ opB;
        end
        `OPC_ADD: begin
        end
        `OPC_SUB: begin
        end
        default: begin
            $display("OPCODE NOT IMPLEMENTED");
        end
        endcase
        reg_status = `ST_IDLE;
    end
    
  endcase

end

alu my_alu(
    .clk(clk),
    .reset(reset),

    .i_a(req_opA),
    .i_b(req_opB),
    .i_cmd(req_cmd),

    .o_result(resp_res),
    .o_valid(resp_valid),
    .o_ready(alu_ready)
);



endmodule

`endif
