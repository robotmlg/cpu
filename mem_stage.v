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
    input [`ADDRESS_WIDTH-1:0]    i_pc,
    input [7:0]                   i_opcode,

    input [8:0]                   i_opDEST_flags,
    input [`ADDRESS_WIDTH-1:0]    i_opDEST_data, // offset, immediate, absolute
    input [3:0]                   i_opDEST_reg,
    input [4:0]                   i_opDEST_scale,
    input [3:0]                   i_opDEST_base_reg,

    input [8:0]                   i_opSRC_flags,
    input [`ADDRESS_WIDTH-1:0]    i_opSRC_data,
    input [3:0]                   i_opSRC_reg,
    input [4:0]                   i_opSRC_scale,
    input [3:0]                   i_opSRC_base_reg,

    output o_fetching,

    // mem-execute comms
    input i_next_ready,
    output o_res_valid,
    output [`ADDRESS_WIDTH-1:0] o_pc,
    output [7:0] o_opcode,
    output [`DATA_WIDTH-1:0] o_opA,
    output [`DATA_WIDTH-1:0] o_opB,
    output [3:0] o_dest_reg,
    output [`ADDRESS_WIDTH-1:0] o_dest_addr,

    output o_ready
);

// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_NEW_INST   4'h2
`define ST_GET_REG    4'h3
`define ST_CALC_ADD   4'h4
`define ST_GET_BASE   4'h5
`define ST_GET_IMM    4'h6
`define ST_END_INST   4'h7
`define ST_GET_MEM    4'h8
`define ST_END_INST   4'hF

// status registers
reg ready;
reg res_valid;
reg fetching;
reg state_idle;
reg src_done = 0;
reg src_dirty = 0;
reg src_chkd = 0;
reg dest_done = 0;
reg dest_dirty = 0;
reg dest_chkd = 0;

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

reg [3:0] dest_reg;
reg [`ADDRESS_WIDTH-1:0] dest_addr;

reg [`DATA_WIDTH-1:0] opSRC_val;
reg [`DATA_WIDTH-1:0] opSRC_reg_val;
reg [`DATA_WIDTH-1:0] opDEST_base_val;
reg [`DATA_WIDTH-1:0] opDEST_val;
reg [`DATA_WIDTH-1:0] opDEST_reg_val;
reg [`DATA_WIDTH-1:0] opSRC_base_val;

// inter-stage registers
reg [`ADDRESS_WIDTH-1:0] out_pc;
reg [7:0] out_opcode;
reg [`DATA_WIDTH-1:0] out_opA;
reg [`DATA_WIDTH-1:0] out_opB;
reg [3:0] out_dest_reg;
reg [`ADDRESS_WIDTH-1:0] out_dest_addr;

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
assign o_fetching = fetching;
assign o_pc = out_pc;
assign o_opcode = out_opcode;
assign o_opA = out_opA;
assign o_opB = out_opB;
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


// get the operands from regfile the instructions
// TODO: get operands from memory
always @(posedge clk) begin
    //$display("STATE = %d",reg_status);
    case (reg_status)
    `ST_RESET: begin
        reg_status = `ST_IDLE;
        res_valid = 0;
        fetching = 1;
        out_pc = `ADDRESS_WIDTH'h0;
        curr_pc = 0;
    end
    `ST_IDLE: begin
        state_idle = 1;
        if (res_valid == 0 && curr_pc != 0) begin
            res_valid = 1;
            out_opcode = opcode;
            out_pc = curr_pc;
            out_opA = opSRC_val;
            out_opB = opDEST_val;
            out_dest_reg = dest_reg;
            out_dest_addr = dest_addr;
        end
    end
    `ST_NEW_INST: begin
        $display("Getting ops!");
        state_idle = 0;
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
        opSRC_reg_val = 0;
        opSRC_base_val = 0;
        opDEST_val = 0;
        opDEST_reg_val = 0;
        opDEST_base_val = 0;

        dest_reg = 0;
        dest_addr = 0;

        src_done = 0;
        dest_done = 0;
        src_chkd = 0;
        dest_chkd = 0;

        //$display("getting registers for %x",opcode);

        if (opSRC_flags`FLG_IMM || opDEST_flags`FLG_IMM)
            reg_status = `ST_GET_IMM;
        else
            reg_status = `ST_GET_REG;
    end
    `ST_GET_IMM: begin
        // get the immediate value
        if (opSRC_flags`FLG_VAL && opSRC_flags`FLG_IMM) begin
            opSRC_val = opSRC_data;
        end
        if (opDEST_flags`FLG_VAL && opDEST_flags`FLG_IMM) begin
            opDEST_val = opDEST_data;
        end
        // from here, if you need a register, get it, otherwise it must be abs mem
        if (opSRC_flags`FLG_REG || opDEST_flags`FLG_REG)
            reg_status = `ST_GET_REG;
        else
            reg_status = `ST_CALC_ADD;
    end
    `ST_GET_REG: begin
        // get the value in the main registers
        if (opSRC_flags`FLG_VAL && opSRC_flags`FLG_REG && src_done == 0) begin
            //$display("getting src reg");
            if (src_chkd == 0) begin
                //$display("checking src reg");
                req_reg = opSRC_reg;
                req_cmd = `REG_CMD_CHECK;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    //$display("src reg resp good");
                    if(reg_resp_data == 0) begin // the reg is clean
                        //$display("src reg clean");
                        src_chkd = 1;
                        src_dirty = 0;
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                    else begin
                        //$display("src reg dirty");
                        src_dirty = 1; 
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                end
                
            end
            else if (src_chkd == 1 && src_dirty == 0) begin
                //$display("reading src reg");
                req_cmd = `REG_CMD_READ;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    opSRC_reg_val = reg_resp_data;
                    src_done = 1;
                    req_valid = 0;
                    req_read_ready = 0;
                    $display("Got reg %x value %x", opSRC_reg, reg_resp_data);
                end
            end
        end
        else
            src_done = 1;

        if (src_done && !dest_done && opDEST_flags`FLG_VAL && opDEST_flags`FLG_REG) begin
            //$display("getting dest reg");
            if (dest_chkd == 0) begin
                //$display("checking dest reg");
                req_reg = opDEST_reg;
                req_cmd = `REG_CMD_CHECK;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    if(reg_resp_data == 0) begin // the reg is clean
                        //$display("dest reg clean");
                        dest_chkd = 1;
                        dest_dirty = 0;
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                    else begin
                        //$display("dest reg dirty");
                        dest_dirty = 1; 
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                end
                
            end
            else if (dest_chkd == 1 && dest_dirty == 0) begin
                req_reg = opDEST_reg;
                req_cmd = `REG_CMD_READ;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    opDEST_reg_val = reg_resp_data;
                    dest_done = 1;
                    req_valid = 0;
                    req_read_ready = 0;
                    $display("Got reg %x value %x", opDEST_reg, reg_resp_data);
                end
            end
        end

        if(src_done && dest_done) begin
            src_done = 0;
            dest_done = 0;
            src_chkd = 0;
            dest_chkd = 0;
            src_dirty = 0;
            dest_dirty = 0;

            if(opSRC_flags`FLG_BAS || opDEST_flags`FLG_BAS)
                reg_status = `ST_GET_BASE;
            else if(opSRC_flags`FLG_MEM || opDEST_flags`FLG_MEM)
                reg_status = `ST_CALC_ADD;
            else
                reg_status = `ST_END_INST;
        end
    end
    `ST_GET_BASE: begin
        // get the value in the base register
        if (opSRC_flags`FLG_VAL && opSRC_flags`FLG_BAS && src_done == 0) begin
            //$display("getting src reg");
            if (src_chkd == 0) begin
                //$display("checking src reg");
                req_reg = opSRC_base_reg;
                req_cmd = `REG_CMD_CHECK;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    //$display("src reg resp good");
                    if(reg_resp_data == 0) begin // the reg is clean
                        //$display("src reg clean");
                        src_chkd = 1;
                        src_dirty = 0;
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                    else begin
                        //$display("src reg dirty");
                        src_dirty = 1; 
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                end
                
            end
            else if (src_chkd == 1 && src_dirty == 0) begin
                //$display("reading src reg");
                req_cmd = `REG_CMD_READ;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    opSRC_base_val = reg_resp_data;
                    src_done = 1;
                    req_valid = 0;
                    req_read_ready = 0;
                    //$display("Got reg %x value %x", opSRC_base_reg, reg_resp_data);
                end
            end
        end
        else
            src_done = 1;

        if (src_done && !dest_done && opDEST_flags`FLG_VAL && opDEST_flags`FLG_BAS) begin
            //$display("getting dest reg");
            if (dest_chkd == 0) begin
                //$display("checking dest reg");
                req_reg = opDEST_base_reg;
                req_cmd = `REG_CMD_CHECK;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    if(reg_resp_data == 0) begin // the reg is clean
                        //$display("dest reg clean");
                        dest_chkd = 1;
                        dest_dirty = 0;
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                    else begin
                        //$display("dest reg dirty");
                        dest_dirty = 1; 
                        req_valid = 0;
                        req_read_ready = 0;
                    end
                end
                
            end
            else if (dest_chkd == 1 && dest_dirty == 0) begin
                req_reg = opDEST_base_reg;
                req_cmd = `REG_CMD_READ;
                req_valid = 1;
                req_read_ready = 1;

                if (reg_resp_valid) begin
                    opDEST_base_val = reg_resp_data;
                    dest_done = 1;
                    req_valid = 0;
                    req_read_ready = 0;
                    //$display("Got reg %x value %x", opDEST_base_reg, reg_resp_data);
                end
            end
        end
        reg_status = `ST_CALC_ADD;
    end
    `ST_CALC_ADD: begin
        // calculate the memory address to access
        if (opSRC_flags`FLG_VAL && opSRC_flags`FLG_MEM) begin
            if (opSRC_flags`FLG_ABS || opSRC_flags`FLG_REL) begin
                // relative addresses already made absolute in decode stage
                opSRC_val = opSRC_data;
            end
            else begin
                if (opSRC_flags`FLG_SCA)
                    opSRC_val = opSRC_reg_val * opSRC_scale;
                if (opSRC_flags`FLG_OFF)
                    opSRC_val += opSRC_data;
                if (opSRC_flags`FLG_BAS)
                    opSRC_val += opSRC_base_val;
            end
        end
        if (opDEST_flags`FLG_VAL && opDEST_flags`FLG_MEM) begin
            if (opDEST_flags`FLG_ABS || opDEST_flags`FLG_REL) begin
                // relative addresses already made absolute in decode stage
                opDEST_val = opDEST_data;
            end
            else begin
                if (opDEST_flags`FLG_SCA)
                    opDEST_val = opDEST_reg_val * opDEST_scale;
                if (opDEST_flags`FLG_OFF)
                    opDEST_val += opDEST_data;
                if (opDEST_flags`FLG_BAS)
                    opDEST_val += opDEST_base_val;
            end
        end
        reg_status = `ST_GET_MEM;
    end
    `ST_GET_MEM: begin
        // access memory to get the values needed
        // TODO: this
    end
    `ST_END_INST: begin
        //$display("End of instr");
        // get the destination register info
        if (opDEST_flags`FLG_REG && ~opDEST_flags`FLG_MEM) 
            dest_reg = opDEST_reg;
        else
            dest_addr = opDEST_val;

        // mark the destination register as dirty
        if (dest_addr == 0) begin
            req_reg = dest_reg;
            req_cmd = `REG_CMD_MARKD;
            req_valid = 1;
            req_read_ready = 1;

            if (reg_resp_valid) begin
                reg_status = `ST_IDLE;
                req_valid = 0;
                req_read_ready = 0;
                //$display("Got reg %x value %x", opDEST_base_reg, reg_resp_data);
            end
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
