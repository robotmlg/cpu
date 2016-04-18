`ifndef FETCH_V
`define FETCH_V

`include "header.v"

// fetches an x86 instruction from memory
module fetch(
    input clk,
    input reset,

    // talking to memory module
    input i_mem_valid,
    input [`DATA_WIDTH-1:0] i_mem_data,
    output o_addr_valid,
    output [`ADDRESS_WIDTH-1:0] o_addr,

    // 
    input i_valid, // whether input data is valid
    input [`ADDRESS_WIDTH-1:0] i_pc, // next pc, if needed

    // sending to decode module
    output [`MAX_INSTR_WIDTH-1:0] o_instr, // max length 15 bytes
    output [3:0] o_instr_len, 
    output o_res_valid,
    output o_ready
    );

// state matchine
reg [3:0] reg_status;
reg [3:0] nxt_status;
// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_INIT_PC    4'h2
`define ST_GET_CELL   4'h3
`define ST_GET_BYTE   4'h4
`define ST_NEW_INST   4'h5
`define ST_FIND_INST  4'h6
`define ST_PARSE_OP   4'h7

reg ready;
reg res_valid;

// global info
reg [`ADDRESS_WIDTH-1:0] base_pc;
reg [2:0] byte_index = 3'h0;
reg [7:0] read_byte;
reg [`DATA_WIDTH-1:0] read_cell;

// info about current instruction
reg [`MAX_INSTR_WIDTH-1:0] instr;
reg [3:0] instr_len; // 1-15 B
reg [`ADDRESS_WIDTH-1:0] instr_address = `ADDRESS_WIDTH'h0; // the PC address
reg [`ADDRESS_WIDTH-1:0] next_address = `ADDRESS_WIDTH'h0;

// talking to memory
reg [`ADDRESS_WIDTH-1:0] cell_address;
reg addr_valid = 'b0;
assign o_addr_valid = addr_valid;
assign o_addr = o_addr_valid ? cell_address : `ADDRESS_WIDTH'hx;

// output
assign o_res_valid = (res_valid && (reg_status == `ST_IDLE));
assign o_ready = (reg_status == `ST_IDLE) && !reset;
assign o_instr = o_res_valid ? instr : `MAX_INSTR_WIDTH'hx;
assign o_instr_len = o_res_valid ? instr_len : 4'hx;

// synchronous reset
always @(posedge clk && reset) begin
reg_status <= `ST_RESET;
end

// fetch an instruction
always @(posedge clk) begin
//$display("STATE = %d",reg_status);
case (reg_status)
    `ST_RESET: begin
        reg_status = `ST_INIT_PC;
    end
    // get the PC from the first line intially
    `ST_INIT_PC: begin
        if (addr_valid == 1'b0) begin
            cell_address = `ADDRESS_WIDTH'b0;
            addr_valid = 1'b1;
        end

        if (i_mem_valid) begin
            base_pc = i_mem_data;
            addr_valid = 1'b0;
            reg_status = `ST_NEW_INST;
            byte_index = 3'h4;
            $display("The PC is %x",base_pc);
        end
    end
    // get the next memory cell
    `ST_GET_CELL: begin
        if (addr_valid == 1'b0) begin
            addr_valid = 1'b1;
        end
        if (i_mem_valid) begin
            read_cell = i_mem_data;
            addr_valid = 1'b0;
            byte_index = 3'h0;
            reg_status = `ST_GET_BYTE;
        end
    end
    // get the next byte
    `ST_GET_BYTE: begin
        // record the last byte
        $display("Last byte: %x",read_byte);
        case (instr_len)
        4'h0: instr[7:0] = read_byte;
        4'h1: instr[15:8] = read_byte;
        4'h2: instr[23:16] = read_byte;
        4'h3: instr[31:24] = read_byte;
        4'h4: instr[39:32] = read_byte;
        4'h5: instr[47:40] = read_byte;
        4'h6: instr[55:48] = read_byte;
        4'h7: instr[63:56] = read_byte;
        4'h8: instr[71:64] = read_byte;
        4'h9: instr[79:72] = read_byte;
        4'hA: instr[87:80] = read_byte;
        4'hB: instr[95:88] = read_byte;
        4'hC: instr[103:96] = read_byte;
        4'hD: instr[111:104] = read_byte;
        4'hE: instr[119:112] = read_byte;
        4'hF: $display("Instruction too long!");
        endcase
        reg_status = nxt_status;
        case (byte_index)
        3'h3: begin
            read_byte = read_cell[31:24];
        end
        3'h2: begin
            read_byte = read_cell[23:16];
        end
        3'h1: begin
            read_byte = read_cell[15:8];
        end
        3'h0: begin
            read_byte = read_cell[7:0];
        end
        3'h4: begin
            reg_status = `ST_GET_CELL;
            cell_address = cell_address + (`DATA_WIDTH/8);
        end
        endcase
        byte_index++;
    end
    // init for a new instruction
    `ST_NEW_INST: begin
        instr_len = 0;
        reg_status = `ST_GET_BYTE;
        nxt_status = `ST_FIND_INST;
    end
    // find a new instruction
    `ST_FIND_INST: begin
        case (read_byte)
        // byte is a prefix
        8'hF0, 8'hF2, 8'hF3, 8'h2E, 8'h36, 8'h3E, 8'h26, 8'h64, 8'h65, 8'h66, 8'h67: begin
            nxt_status = `ST_FIND_INST;
            reg_status = `ST_GET_BYTE;
            instr_len++;
        end
        // byte is an instruction
        default: begin
            nxt_status = `ST_PARSE_OP;
            reg_status = `ST_GET_BYTE;
        end
        endcase
    end
    // determine the instruction length based on the opcode
    `ST_PARSE_OP: begin
        $display("found an opcode!");
    end
endcase

end



endmodule

`endif
