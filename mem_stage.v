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
`define ST_CALC_ADD   4'h4
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

reg [`DATA_WIDTH-1:0] opSRC_val;
reg [`DATA_WIDTH-1:0] opDEST_val;

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

// reg-file comms
reg [3:0] req_reg;
wire [3:0] w_req_reg;
assign w_req_reg = req_reg;
reg [`DATA_WIDTH-1:0] req_data;
wire [`DATA_WIDTH-1:0] w_req_data;
assign w_req_data = req_data;
reg [`REG_CMD_WIDTH-1:0] req_cmd;
wire [`REG_CMD_WIDTH-1:0] w_req_cmd;
assign w_req_cmd = req_cmd;
reg req_valid;
wire w_req_valid;
assign w_req_valid = req_valid;
reg req_read_ready;
wire w_req_read_ready;
assign w_req_read_ready = req_read_ready;

wire [`DATA_WIDTH-1:0] reg_resp_data;
wire reg_resp_valid;
wire reg_ready;


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
        res_valid = 0;
        fetching = 1;
    end
    `ST_IDLE: begin
        if (res_valid == 0 && fetching == 0) begin
            res_valid = 1;
        end
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

        opSRC_val = 0;
        opDEST_val = 0;

        $display("getting registers for %x",opcode);

        reg_status = `ST_GET_REG;
    end
    `ST_GET_REG: begin
        if (opSRC_flags`FLG_VAL == 1) begin
        end
    end
    `ST_CALC_ADD: begin
        if (opSRC_flags`FLG_VAL == 1 && opSRC_flags`FLG_MEM == 1) begin
        end
    end
    
  endcase

end

reg_file my_reg(
    .clk(clk),
    .reset(reset),

    .i_reg(w_req_reg),
    .i_data(w_req_data),
    .i_cmd(w_req_cmd),
    .i_valid(w_req_valid),
    .i_res_ready(w_req_read_ready),

    .o_data(reg_resp_data),
    .o_res_valid(reg_resp_valid),
    .o_ready(reg_ready)
);


endmodule

`endif
