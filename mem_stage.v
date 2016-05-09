`ifndef MEM_STG_V
`define MEM_STG_V

`include "header.v"
`include "reg.v"

// decodes the x86 instruction passed
module memory_stage(
    input clk,
    input reset,

    // decode-mem comms
    input i_input_valid,
    output [`ADDRESS_WIDTH-1:0]    i_pc,
    output [7:0]                   i_opcode,

    output [8:0]                   i_opDEST_flags,
    output [`ADDRESS_WIDTH-1:0]    i_opDEST_data, // offset, immediate, absolute
    output [3:0]                   i_opDEST_reg,
    output [4:0]                   i_opDEST_scale,
    output [3:0]                   i_opDEST_base_reg,

    output [8:0]                   i_opSRC_flags,
    output [`ADDRESS_WIDTH-1:0]    i_opSRC_data,
    output [3:0]                   i_opSRC_reg,
    output [4:0]                   i_opSRC_scale,
    output [3:0]                   i_opSRC_base_reg,

    // mem-execute comms
    input i_next_ready,
    output o_res_valid,
    output o_ready
);

// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_NEW_INST   4'h2
`define ST_GET_REG    4'h3
`define ST_END_INST   4'hF

// status registers
reg ready;
reg res_valid;
reg fetching;
reg passed_out;

// FSM registers
reg [3:0] reg_status = `ST_RESET;
reg [3:0] nxt_status = `ST_IDLE;

// current byte
reg [7:0] curr_byte;
reg [3:0] byte_index;

// info about current instruction
reg [7:0] opcode;
reg [`ADDRESS_WIDTH-1:0] curr_pc;

reg [8:0] opDEST_flags;
reg [`ADDRESS_WIDTH-1:0] opDEST_data; // offset, immediate, absolute
reg [3:0] opDEST_reg;
reg [4:0] opDEST_scale;
reg [3:0] opDEST_base_reg;

reg [8:0] opSRC_flags;
reg [`ADDRESS_WIDTH-1:0] opSRC_data;
reg [3:0] opSRC_reg;
reg [4:0] opSRC_scale;
reg [3:0] opSRC_base_reg;

// inter-stage registers
reg [7:0] out_opcode;

reg [8:0]                   out_opDEST_flags;
reg [`ADDRESS_WIDTH-1:0]    out_opDEST_data; // offset, immediate, absolute
reg [3:0]                   out_opDEST_reg;
reg [4:0]                   out_opDEST_scale;
reg [3:0]                   out_opDEST_base_reg;

reg [8:0]                   out_opSRC_flags;
reg [`ADDRESS_WIDTH-1:0]    out_opSRC_data;
reg [3:0]                   out_opSRC_reg;
reg [4:0]                   out_opSRC_scale;
reg [3:0]                   out_opSRC_base_reg;


assign o_res_valid = res_valid;
assign o_ready = ready;

// synchronous reset
always @(posedge clk && reset) begin
  reg_status <= `ST_RESET;
end

// synchronous retrieve instruction
always @(posedge clk && i_input_valid) begin
    if(reg_status == `ST_IDLE) begin
        reg_status = `ST_NEW_INST;
        fetching = 1;
    end
    else
        fetching = 0;
end



// decode the instructions
always @(posedge clk) begin
    //$display("STATE = %d",reg_status);
    case (reg_status)
    `ST_RESET: begin
        reg_status = `ST_IDLE;
    end
    `ST_IDLE: begin
    end
    `ST_NEW_INST: begin
        opcode = i_opcode;
        curr_pc = i_pc;
        opDEST_flags = i_opDEST_flags;
        opDEST_data = i_opDEST_data;
        opDEST_reg = i_opDEST_reg;
        opDEST_scale = i_opDEST_scale;
        opDEST_base_reg = i_opDEST_base_reg;
        opSRC_flags = i_opSRC_flags;
        opSRC_data = i_opSRC_data;
        opSRC_reg = i_opSRC_reg;
        opSRC_scale = i_opSRC_scale;
        opSRC_base_reg = i_opSRC_base_reg;

        reg_status = `ST_GET_REG;
    end
  endcase

end

/*
reg_file my_reg(
);
*/


endmodule

`endif
