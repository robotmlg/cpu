`ifndef WRITEBACK_V
`define WRITEBACK_V

`include "header.v"

// writes data back to the regfile, memory, and PC
module writeback(
    input clk,
    input reset,

    // exec-wb comms
    input i_input_valid,
    input [7:0] i_opcode,
    input [`DATA_WIDTH-1:0] i_val,
    input [3:0] i_dest_reg,
    input [`ADDRESS_WIDTH-1:0] i_dest_addr,

    output o_fetching,

    // wb-fetch  comms
    output o_pc_valid,
    output [`ADDRESS_WIDTH-1:0] o_pc,

    output o_ready
);

// WB state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_NEW_INST   4'h2
`define ST_MEM_WRITE  4'h3
`define ST_REG_WRITE  4'h4
`define ST_PC_WRITE   4'h5
`define ST_END_INST   4'hF

// WB type macros
`define WB_PC  2'h0
`define WB_MEM 2'h1
`define WB_REG 2'h2

// status registers
reg ready;
reg fetching;
reg state_idle;
reg [1:0] wb_type;

// FSM registers
reg [3:0] reg_status = `ST_RESET;
reg [3:0] nxt_status = `ST_IDLE;


// info about current instruction
reg [7:0] opcode;
reg [7:0] value;
reg [3:0] dest_reg;
reg [3:0] dest_addr;

reg [`ADDRESS_WIDTH-1:0] out_pc;
reg pc_valid;



assign o_pc_valid = pc_valid;
assign o_ready = ready;
assign o_fetching = fetching;


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




// execute the instructions
always @(posedge clk) begin
    //$display("STATE = %d",reg_status);
    case (reg_status)
    `ST_RESET: begin
        reg_status = `ST_IDLE;
        pc_valid = 0;
        fetching = 1;
        out_pc = 0;
        pc_valid = 0;
    end
    `ST_IDLE: begin
        state_idle = 1;
        if (pc_valid == 0 && opcode == 0) begin
            pc_valid = 1;
            out_pc = dest_addr;

        end
    end
    `ST_NEW_INST: begin
        $display("WRITEBACK");
        state_idle = 0;
        opcode = i_opcode;
        value = i_val;
        dest_reg = i_dest_reg;
        dest_addr = i_dest_addr;

        if(dest_addr != 0)
            reg_status = `ST_MEM_WRITE;
        else
            reg_status = `ST_REG_WRITE;

    end
    `ST_MEM_WRITE: begin
        wb_type = `WB_MEM;
    end
    `ST_REG_WRITE: begin
        wb_type = `WB_REG;
    end
    `ST_PC_WRITE: begin
        wb_type = `WB_PC;
    end
    
  endcase

end




endmodule

`endif
