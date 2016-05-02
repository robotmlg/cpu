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

    // data from writeback
    input i_pc_valid, // whether input data is valid
    input [`ADDRESS_WIDTH-1:0] i_pc, // next pc, if needed

    // talking to decode module
    input i_dec_ready,
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
`define ST_END_INST   4'h8
`define ST_PARSE_MRM  4'h9

reg res_valid;
reg passed_to_dec;

// global info
reg [`ADDRESS_WIDTH-1:0] base_pc;
reg [2:0] byte_index = 3'h0;
reg [7:0] read_byte;
reg [`DATA_WIDTH-1:0] read_cell;
reg valid_byte = 0;

// info about current instruction
reg [`MAX_INSTR_WIDTH-1:0] instr;
reg [3:0] instr_len; // 1-15 B, The actual length of the instruction
reg [3:0] read_instr_len=0; // the number of bytes read in so far
reg [`ADDRESS_WIDTH-1:0] instr_address = `ADDRESS_WIDTH'h0; // the PC address
reg [`ADDRESS_WIDTH-1:0] next_address = `ADDRESS_WIDTH'h0;
reg [2:0] disp_width;

// talking to memory
reg [`ADDRESS_WIDTH-1:0] cell_address;
reg addr_valid = 'b0;
assign o_addr_valid = addr_valid;
assign o_addr = o_addr_valid ? cell_address : `ADDRESS_WIDTH'hx;

// output
reg [`MAX_INSTR_WIDTH-1:0] out_instr;
reg [3:0] out_instr_len; // 1-15 B
assign o_res_valid = (res_valid && (reg_status == `ST_IDLE));
assign o_ready = (reg_status == `ST_IDLE) && !reset;
assign o_instr = o_res_valid ? out_instr : `MAX_INSTR_WIDTH'hx;
assign o_instr_len = o_res_valid ? out_instr_len : 4'hx;

// synchronous reset
always @(posedge clk && reset) begin
reg_status <= `ST_RESET;
end

//
always @(posedge clk && i_dec_ready && res_valid) begin
    passed_to_dec = 1;
    res_valid = 0;
end

// fetch an instruction
always @(posedge clk) begin
$display("STATE = %d",reg_status);
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
        if(byte_index == 3'h4)
            valid_byte=0;
        else begin
            valid_byte=1;
            read_instr_len++;
        end
        // record the byte
        if(byte_index != 3'h4 && valid_byte == 1) begin
            $display("byte: %x",read_byte);
            case (read_instr_len)
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
        end
        byte_index++;
    end
    // init for a new instruction
    `ST_NEW_INST: begin
        instr = `MAX_INSTR_WIDTH'b0;
        instr_len = 0;
        read_instr_len = -1;
        reg_status = `ST_GET_BYTE;
        nxt_status = `ST_FIND_INST;
    end
    // find a new instruction
    `ST_FIND_INST: begin
        instr_len++;
        case (read_byte)
        // byte is a prefix
        8'hF0, 8'hF2, 8'hF3, 8'h2E, 8'h36, 8'h3E, 8'h26, 8'h64, 8'h65, 8'h66, 8'h67: begin
            nxt_status = `ST_FIND_INST;
            reg_status = `ST_GET_BYTE;
        end
        // byte is an instruction
        default: begin
            reg_status = `ST_PARSE_OP;
        end
        endcase
    end
    // determine the instruction length based on the opcode
    `ST_PARSE_OP: begin
        $display("found an opcode! %x",read_byte);
        casez (read_byte[7:4])
        // 0: ADD, OR, PUSH CS/ES, POP ES
        // 1: ADC, SBB, PUSH/POP SS
        // 2: AND, DAA, SUB, DAS
        // 3: XOR, CMP, AAA, AAS
        4'b00??: begin
            case (read_byte[2:1]) 
                2'b11: begin //specials
                    reg_status = `ST_IDLE;
                end
                // regulars
                2'b10: begin
                    nxt_status = `ST_IDLE;
                    reg_status = `ST_GET_BYTE;
                    if (read_byte[0]==1) //immediate word
                        instr_len+=4;
                    else // immediate byte
                        instr_len+=1;
                end
                default: begin // mod r/m
                    nxt_status = `ST_PARSE_MRM;
                    reg_status = `ST_GET_BYTE;
                    instr_len += 1;
                end
            endcase
        end
        // INC/DEC
        // PUSH/POP general reg
        4'b010?: begin
            reg_status = `ST_IDLE;
        end
        /*
        // Lots of random shit
        4'h6: begin
          case (read_byte[3:0])
          4'h8: begin // PUSH Iz
            reg_status = `ST_GET_BYTE;
            nxt_status = `ST_PARSE_IMM;
            opSRC_flags`FLG_VAL = 1;
            opSRC_flags`FLG_IMM = 1;
            imm_size = op_size;
          end
          endcase
        end
        // Immediate group 1
        // MOV with ModR/M
        4'h8: begin
          opDEST_flags`FLG_VAL = 1;
          opDEST_flags`FLG_REG = 1;
          nxt_status = `ST_PARSE_MRM;
          reg_status = `ST_GET_BYTE;
          casez (read_byte[3:0])
          // immediate group 1
          4'b00??: begin
            opSRC_flags`FLG_VAL = 1;
            opSRC_flags`FLG_IMM = 1;
            op_group = 5'h1;
            op_order = `ORD_MR;
            // operands
            casez (read_byte[2:0])
            3'b0?0: begin //0 and 2
              op_size = 3'h1;
              imm_size = 3'h1;
            end
            3'h1: begin
              // op_size set by prefix
              imm_size = op_size;
            end
            3'h3: begin 
              // op_size set by prefix
              imm_size = 3'h1;
            end
            endcase
          end
          // MOV
          4'b10??: begin
            opcode_str = "mov";
            opSRC_flags`FLG_VAL = 1;
            opSRC_flags`FLG_REG = 1;
            opDEST_flags`FLG_REG = 1;
            // operands
            case (read_byte[2:0])
            3'h0: begin
              op_size = 3'h1;
              op_order = `ORD_MR;
            end
            3'h1: begin
              // op_size set by prefix
              op_order = `ORD_MR;
            end
            3'h2: begin
              op_size = 3'h1;
              op_order = `ORD_RM;
            end
            3'h3: begin 
              // op_size set by prefix
              op_order = `ORD_RM;
            end
            endcase
          end
          endcase
        end
        // XCHG, other shit
        4'h9: begin
          if (read_byte[3] == 0) begin
            if (read_byte == 8'h90) begin
              opcode_str = "nop";
              opDEST_flags`FLG_VAL = 0;
            end
            else begin
              opcode_str = "xchg";
              opDEST_flags`FLG_VAL = 1;
              opDEST_flags`FLG_REG = 1;
            end

            case (read_byte[3:0])
            4'h0: begin
            end
            4'h1: begin
              opDEST_reg = `REG_ECX;
            end
            4'h2: begin
              opDEST_reg = `REG_EDX;
            end
            4'h3: begin 
              opDEST_reg = `REG_EBX;
            end
            4'h4: begin
              opDEST_reg = `REG_ESP;
            end
            4'h5: begin
              opDEST_reg = `REG_EBP;
            end
            4'h6: begin
              opDEST_reg = `REG_ESI;
            end
            4'h7: begin
              opDEST_reg = `REG_EDI;
            end
            endcase
            reg_status = `ST_PRINT_INST;
          end
        end
        // LOOP, IN, OUT, CALL, JMP
        4'hE: begin
          casez (read_byte[3:0])
          4'h8: begin
            opcode_str = "call";
            reg_status = `ST_GET_BYTE;
            nxt_status = `ST_PARSE_DISP;
            opDEST_flags`FLG_VAL = 1;
            opDEST_flags`FLG_OFF = 1;
            opDEST_flags`FLG_REL = 1;
            imm_size = 3'h0;
          end
          endcase
        end
        // more random shit
        4'hF: begin
          casez (read_byte[3:0])
          4'h4: begin
            opcode_str = "hlt";
            reg_status = `ST_PRINT_INST;
          end
          endcase
        end
        */
        endcase
    end
    `ST_PARSE_MRM: begin
        $display("parsing Mod R/M");
        reg_status = `ST_IDLE;
        // parse mod
        case (read_byte[7:6])
        2'b00: begin
            if (read_byte[2:0] == 3'b100)
                instr_len += 1;
        end
        2'b01: begin
            if (read_byte[2:0] == 3'b100)
                instr_len += 2;
            else
                instr_len += 1;
        end
        2'b10: begin
            if (read_byte[2:0] == 3'b100)
                instr_len += 5;
            else
                instr_len += 4;
        end
        2'b11: begin
        end
        endcase
    end
    `ST_END_INST: begin
        if (read_instr_len < instr_len)
            reg_status = `ST_GET_BYTE;
        else
            reg_status = `ST_IDLE;
    end
    `ST_IDLE: begin
        if (!passed_to_dec)   begin
            // if you haven't passed the last instruction to decode, STALL
        end	
        else begin // if the last instruction got passed, load in next 
                   // instruction to ready it for passing
            $display("%d byte: %x",instr_len,instr);
            passed_to_dec = 0;
            res_valid = 1;
            out_instr = instr;
            out_instr_len = instr_len;
            reg_status = `ST_NEW_INST;
        end
    end
endcase

end



endmodule

`endif
