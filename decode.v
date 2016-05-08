`ifndef DECODE_V
`define DECODE_V

`include "header.v"

// decodes the x86 instruction passed
module decode(
    input clk,
    input reset,

    // fetch-decode comms
    input i_instr_valid,
    input [`MAX_INSTR_WIDTH-1:0] i_instr,
    input [3:0] i_instr_len,
    input [`ADDRESS_WIDTH-1:0] i_pc,
    output o_fetching,

    // deocde-execute comms
    input i_next_ready,
    output o_res_valid,
    output o_ready
);

// ID state machine macros
`define ST_RESET      4'h0
`define ST_IDLE       4'h1
`define ST_GET_BYTE   4'h2
`define ST_NEW_INST   4'h4
`define ST_PARSE_INST 4'h5
`define ST_PARSE_PRE  4'h6
`define ST_PARSE_OP   4'h7
`define ST_PARSE_2B   4'h8
`define ST_PARSE_MRM  4'h9
`define ST_PARSE_SIB  4'hA
`define ST_PARSE_DISP 4'hB
`define ST_PARSE_IMM  4'hC
`define ST_FIX_ADDR   4'hD
`define ST_END_INST 4'hF

// operand encoding macros
`define ORD_RM 3'h0
`define ORD_MR 3'h1
`define ORD_MI 3'h2
`define ORD_I  3'h3

// operand size macros
`define OP_PREFIX 3'h3 // 3 is not a standard word size, so use this to represent
                        // that the prefix needs to be checked


`define PRINT_REG(x)  case (x)\
                      `REG_EAX: begin\
                        $write("%%eax");\
                      end\
                      `REG_ECX: begin\
                        $write("%%ecx");\
                      end\
                      `REG_EDX: begin\
                        $write("%%edx");\
                      end\
                      `REG_EBX: begin\
                        $write("%%ebx");\
                      end\
                      `REG_ESP: begin\
                        $write("%%esp");\
                      end\
                      `REG_EBP: begin\
                        $write("%%ebp");\
                      end\
                      `REG_ESI: begin\
                        $write("%%esi");\
                      end\
                      `REG_EDI: begin\
                        $write("%%edi");\
                      end\
                      endcase

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
reg [`MAX_INSTR_WIDTH-1:0] instr;
reg [`ADDRESS_WIDTH-1:0] instr_len;
integer instr_len_int=0;
reg [`ADDRESS_WIDTH-1:0] instr_address = `ADDRESS_WIDTH'h0; // the PC address
reg [7:0] opcode;
reg [15*8:0] opcode_str;
reg [15*8:0] instr_bytes;
reg [2:0] op_order;
reg [2:0] op_size; // size of data operated on (bytes)
reg [4:0] op_group; // group of the opcode for modr/m parsing
reg [3:0] ModRM_reg;
reg [3:0] ModRM_RM;
reg [8:0] ModRM_flags;
reg [8:0] ModRM_reg_flags;
reg [2:0] disp_size;
reg [2:0] disp_count;
reg [`ADDRESS_WIDTH-1:0] disp_data; // displacement offset
reg [2:0] imm_size;
reg [2:0] imm_count;
reg [4:0] SIB_scale;
reg [3:0] SIB_base_reg;

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
assign o_fetching = fetching;

// synchronous reset
always @(posedge clk && reset) begin
  reg_status <= `ST_RESET;
end

// synchronous retrieve instruction
always @(posedge clk && i_instr_valid) begin
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
        /*
        if (!passed_out) begin
            // if you haven't passed the last instruction, STALL
        end
        else begin
        */
            passed_out = 0;
            res_valid = 1;
            out_opcode = opcode;
            out_opDEST_flags = opDEST_flags;
            out_opDEST_reg = opDEST_reg;
            out_opDEST_data = opDEST_data;
            out_opDEST_scale = opDEST_scale;
            out_opDEST_base_reg = opDEST_base_reg;
            out_opSRC_flags = opSRC_flags;
            out_opSRC_reg = opSRC_reg;
            out_opSRC_data = opSRC_data;
            out_opSRC_scale = opSRC_scale;
            out_opSRC_base_reg = opSRC_base_reg;
        //end
    end
    // get the requested bytes from the instruction
    `ST_GET_BYTE: begin
        case (byte_index)
        4'h0: curr_byte = instr[7:0];
        4'h1: curr_byte = instr[15:8];
        4'h2: curr_byte = instr[23:16];
        4'h3: curr_byte = instr[31:24];
        4'h4: curr_byte = instr[39:32];
        4'h5: curr_byte = instr[47:40];
        4'h6: curr_byte = instr[55:48];
        4'h7: curr_byte = instr[63:56];
        4'h8: curr_byte = instr[71:64];
        4'h9: curr_byte = instr[79:72];
        4'hA: curr_byte = instr[87:80];
        4'hB: curr_byte = instr[95:88];
        4'hC: curr_byte = instr[103:96];
        4'hD: curr_byte = instr[111:104];
        4'hE: curr_byte = instr[119:112];
        4'hF: $display("Instruction only 15 bytes!");
        endcase
        byte_index++;
        reg_status = nxt_status;
    end
    // start a new instruction
    `ST_NEW_INST: begin
        instr_len = i_instr_len;
        instr = i_instr;
        op_size = 3'h4;
        imm_size = 3'h4;
        disp_size = 3'h4;
        imm_count = 3'h0;
        op_group = 5'h0;
        opDEST_flags`FLG_RESET = `RESET_FLAGS;
        opSRC_flags`FLG_RESET = `RESET_FLAGS;
        instr_address = i_pc;
        byte_index=4'h0;
        reg_status = `ST_GET_BYTE;
        nxt_status = `ST_PARSE_INST;
        $display("decoding %x",instr);
    end
    // evaluate a new instruction or prefixes
    `ST_PARSE_INST: begin
        case (curr_byte)
        8'hF0, 8'hF2, 8'hF3, 8'h2E, 8'h36, 8'h3E, 8'h26, 8'h64, 8'h65, 8'h66, 8'h67: begin
            reg_status = `ST_PARSE_PRE;
        end
        default: begin
            reg_status = `ST_PARSE_OP;
        end
        endcase
    end
    `ST_PARSE_PRE: begin
        $display("PREFIXES NOT IMPLEMENTED");
        reg_status = `ST_GET_BYTE;
        nxt_status = `ST_PARSE_INST;
    end
    // evaluate an opcode first byte
    `ST_PARSE_OP: begin
        //$display("decoding opcode %x",curr_byte);
        casez (curr_byte[7:4])
        // 0: ADD, OR, PUSH CS/ES, POP ES
        // 1: ADC, SBB, PUSH/POP SS
        // 2: AND, DAA, SUB, DAS
        // 3: XOR, CMP, AAA, AAS
        4'b00??: begin
            opDEST_flags`FLG_VAL = 1;
            opDEST_flags`FLG_REG = 1;
            // specials
            if (curr_byte[2:1] == 2'b11) begin
                reg_status = `ST_END_INST;
                // select opcode
                case (curr_byte) 
                8'h06: begin
                    opcode = `OPC_PUSH;
                    opcode_str = "push";
                    opDEST_reg = `SEG_ES;
                end
                8'h07: begin
                    opcode = `OPC_POP;
                    opcode_str = "pop";
                    opDEST_reg = `SEG_ES;
                end
                8'h16: begin
                    opcode = `OPC_PUSH;
                    opcode_str = "push";
                    opDEST_reg = `SEG_SS;
                end
                8'h17: begin
                    opcode = `OPC_POP;
                    opcode_str = "pop";
                    opDEST_reg = `SEG_SS;
                end
                8'h27: begin
                    opcode = `OPC_DAA;
                    opcode_str = "daa";
                    opDEST_flags`FLG_VAL = 0;
                end
                8'h37: begin
                    opcode=`OPC_AAA;
                    opcode_str = "aaa";
                    opDEST_flags`FLG_VAL = 0;
                end
                8'h0E: begin
                    opcode = `OPC_PUSH;
                    opcode_str = "push";
                    opDEST_reg = `SEG_CS;
                end
                8'h1E: begin
                    opcode = `OPC_PUSH;
                    opcode_str = "push";
                    opDEST_reg = `SEG_DS;
                end
                8'h1F: begin
                    opcode = `OPC_POP;
                    opcode_str = "pop";
                    opDEST_reg = `SEG_DS;
                end
                8'h2F: begin
                    opcode = `OPC_DAS;
                    opcode_str = "das";
                    opDEST_flags`FLG_VAL = 0;
                end
                8'h3F: begin
                    opcode = `OPC_AAS;
                    opcode_str = "aas";
                    opDEST_flags`FLG_VAL = 0;
                end
                endcase
            end
            // regulars
            else begin
                opSRC_flags`FLG_VAL = 1;
                opSRC_flags`FLG_REG = 1;
                reg_status = `ST_GET_BYTE;
                // select opcode
                case (curr_byte[5:3])
                3'b000: begin opcode = `OPC_ADD; opcode_str = "and"; end
                3'b001: begin opcode = `OPC_OR;  opcode_str = "or";  end
                3'b010: begin opcode = `OPC_ADC; opcode_str = "adc"; end
                3'b011: begin opcode = `OPC_SBB; opcode_str = "sbb"; end
                3'b100: begin opcode = `OPC_AND; opcode_str = "and"; end
                3'b101: begin opcode = `OPC_SUB; opcode_str = "sub"; end
                3'b110: begin opcode = `OPC_XOR; opcode_str = "xor"; end
                3'b111: begin opcode = `OPC_CMP; opcode_str = "cmp"; end
                endcase
                // decode args
                case (curr_byte[2:0])
                3'h0: begin
                    op_size = 3'h1;
                    op_order = `ORD_MR;
                    nxt_status = `ST_PARSE_MRM;
                end
                3'h1: begin
                    // op_size set by prefix
                    op_order = `ORD_MR;
                    nxt_status = `ST_PARSE_MRM;
                end
                3'h2: begin
                    op_size = 3'h1;
                    op_order = `ORD_RM;
                    nxt_status = `ST_PARSE_MRM;
                end
                3'h3: begin 
                    // op_size set by prefix
                    op_order = `ORD_RM;
                    nxt_status = `ST_PARSE_MRM;
                end
                3'h4: begin
                    op_size = 3'h1;
                    op_order = `ORD_I;
                    nxt_status = `ST_PARSE_IMM;
                    opDEST_reg = `REG_EAX;
                    opSRC_flags`FLG_VAL = 0;
                end
                3'h5: begin
                    // op_size set by prefix
                    op_order = `ORD_I;
                    nxt_status = `ST_PARSE_IMM;
                    opDEST_reg = `REG_EAX;
                    opSRC_flags`FLG_VAL = 0;
                end
                endcase
            end
        end
        // INC/DEC
        // PUSH/POP general reg
        4'b010?: begin
          opDEST_flags`FLG_VAL = 1;
          opDEST_flags`FLG_REG = 1;
          opSRC_flags`FLG_VAL = 0;
          // opcode
          case (curr_byte[4:3])
          2'b00: begin opcode_str="inc"; opcode = `OPC_INC; end
          2'b01: begin opcode_str="dec"; opcode = `OPC_DEC; end
          2'b10: begin opcode_str="push";opcode = `OPC_PUSH; end
          2'b11: begin opcode_str="pop"; opcode = `OPC_POP; end
          endcase
          // register
          case (curr_byte[2:0])
          3'h0: begin
            opDEST_reg = `REG_EAX;
          end
          3'h1: begin
            opDEST_reg = `REG_ECX;
          end
          3'h2: begin
            opDEST_reg = `REG_EDX;
          end
          3'h3: begin 
            opDEST_reg = `REG_EBX;
          end
          3'h4: begin
            opDEST_reg = `REG_ESP;
          end
          3'h5: begin
            opDEST_reg = `REG_EBP;
          end
          3'h6: begin
            opDEST_reg = `REG_ESI;
          end
          3'h7: begin
            opDEST_reg = `REG_EDI;
          end
          endcase
          reg_status = `ST_END_INST;
        end
        
        default: begin
          $display("OPCODE NOT IMPLEMENTED");
          reg_status = `ST_NEW_INST;
        end
        /*
        // Lots of random shit
        4'h6: begin
          case (curr_byte[3:0])
          4'h8: begin // PUSH Iz
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
          casez (curr_byte[3:0])
          // immediate group 1
          4'b00??: begin
            opSRC_flags`FLG_VAL = 1;
            opSRC_flags`FLG_IMM = 1;
            op_group = 5'h1;
            op_order = `ORD_MR;
            // operands
            casez (curr_byte[2:0])
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
            case (curr_byte[2:0])
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
          if (curr_byte[3] == 0) begin
            if (curr_byte == 8'h90) begin
              opcode_str = "nop";
              opDEST_flags`FLG_VAL = 0;
            end
            else begin
              opcode_str = "xchg";
              opDEST_flags`FLG_VAL = 1;
              opDEST_flags`FLG_REG = 1;
            end

            case (curr_byte[3:0])
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
            reg_status = `ST_END_INST;
          end
        end
        // LOOP, IN, OUT, CALL, JMP
        4'hE: begin
          casez (curr_byte[3:0])
          4'h8: begin
            opcode_str = "call";
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
          casez (curr_byte[3:0])
          4'h4: begin
            opcode_str = "hlt";
            reg_status = `ST_END_INST;
          end
          endcase
        end
        */
        endcase
    end
    `ST_PARSE_2B: begin
    end
    `ST_PARSE_MRM: begin
        //$display("Parsing ModR/M");
        reg_status = `ST_GET_BYTE;
        ModRM_flags`FLG_RESET = `RESET_FLAGS;
        ModRM_reg_flags`FLG_RESET = `RESET_FLAGS;
        // parse mod
        case (curr_byte[7:6])
        2'b00:begin
            ModRM_flags`FLG_VAL = 1;
            ModRM_flags`FLG_REG = 1;
            ModRM_flags`FLG_MEM = 1;
            reg_status = `ST_END_INST;
        end
        2'b01:begin
            ModRM_flags`FLG_VAL = 1;
            ModRM_flags`FLG_REG = 1;
            ModRM_flags`FLG_MEM = 1;
            ModRM_flags`FLG_OFF = 1;
            disp_size = 3'h1;
            nxt_status = `ST_PARSE_DISP;
        end
        2'b10:begin
            ModRM_flags`FLG_VAL = 1;
            ModRM_flags`FLG_REG = 1;
            ModRM_flags`FLG_MEM = 1;
            ModRM_flags`FLG_OFF = 1;
            disp_size = op_size;
            nxt_status = `ST_PARSE_DISP;
        end
        2'b11:begin
            ModRM_flags`FLG_VAL = 1;
            ModRM_flags`FLG_REG = 1;
            reg_status = `ST_END_INST;
        end
        endcase
        // parse reg
        case (op_group)
        5'h0: begin
            ModRM_reg_flags`FLG_REG = 1;
            ModRM_reg_flags`FLG_VAL = 1;
            case (curr_byte[5:3])
            3'b000: ModRM_reg = `REG_EAX;
            3'b001: ModRM_reg = `REG_ECX;
            3'b010: ModRM_reg = `REG_EDX;
            3'b011: ModRM_reg = `REG_EBX;
            3'b100: ModRM_reg = `REG_ESP;
            3'b101: ModRM_reg = `REG_EBP;
            3'b110: ModRM_reg = `REG_ESI;
            3'b111: ModRM_reg = `REG_EDI;
            endcase
        end
        5'h1: begin //immediate group 1
            reg_status = `ST_GET_BYTE;
            nxt_status = `ST_PARSE_IMM;
            disp_count = 3'h0;
            case (curr_byte[5:3])
            3'b000: begin opcode = `OPC_ADD; opcode_str = "and"; end
            3'b001: begin opcode = `OPC_OR;  opcode_str = "or";  end
            3'b010: begin opcode = `OPC_ADC; opcode_str = "adc"; end
            3'b011: begin opcode = `OPC_SBB; opcode_str = "sbb"; end
            3'b100: begin opcode = `OPC_AND; opcode_str = "and"; end
            3'b101: begin opcode = `OPC_SUB; opcode_str = "sub"; end
            3'b110: begin opcode = `OPC_XOR; opcode_str = "xor"; end
            3'b111: begin opcode = `OPC_CMP; opcode_str = "cmp"; end
            endcase
        end
        endcase
        // parse R/M
        case (curr_byte[2:0])
        3'b000: begin 
            ModRM_RM = `REG_EAX;
        end
        3'b001: begin 
            ModRM_RM = `REG_ECX;
        end
        3'b010: begin 
            ModRM_RM = `REG_EDX;
        end
        3'b011: begin 
            ModRM_RM = `REG_EBX;
        end
        3'b100: begin 
            if (curr_byte[7:6] == 2'b11) begin
                ModRM_RM = `REG_ESP;
            end
            else begin
                nxt_status = `ST_PARSE_SIB;
            end
        end
        3'b101: begin 
            if (curr_byte[7:6] == 2'b00) begin
                ModRM_flags`FLG_REG = 0;
                ModRM_flags`FLG_MEM = 1;
                ModRM_flags`FLG_OFF = 1;
                nxt_status = `ST_PARSE_DISP;
            end
            else
                ModRM_RM = `REG_EBP;
        end
        3'b110: begin 
            ModRM_RM = `REG_ESI;
        end
        3'b111: begin 
            ModRM_RM = `REG_EDI;
        end
        endcase
        // assign Mod R/M to operands
        case (op_order)
        `ORD_MR: begin
            if (opSRC_flags`FLG_REG == 1) begin
                opSRC_reg = ModRM_reg;
                opSRC_flags = ModRM_reg_flags;
            end

            if (opDEST_flags`FLG_REG == 1) begin
                opDEST_reg = ModRM_RM;
                opDEST_flags = ModRM_flags;
            end
        end
        `ORD_RM: begin
            if (opDEST_flags`FLG_REG == 1) begin
                opDEST_reg = ModRM_reg;
                opDEST_flags = ModRM_reg_flags;
            end

            if (opSRC_flags`FLG_REG == 1) begin
                opSRC_reg = ModRM_RM;
                opSRC_flags = ModRM_flags;
            end
        end
        endcase
    end
    `ST_PARSE_SIB: begin
    end
    `ST_PARSE_DISP: begin
        reg_status = `ST_GET_BYTE;

        if (disp_size == 0 || disp_count == disp_size-1) begin
            nxt_status = `ST_PARSE_IMM;
        end
        else
            nxt_status = `ST_PARSE_DISP;


        case (disp_count)
        3'h0: begin
            disp_data = {{24{curr_byte[7]}},curr_byte[7:0]};
        end
        3'h1: begin
            disp_data = {{16{curr_byte[7]}},curr_byte[7:0],disp_data[7:0]};
        end
        3'h2: begin
            disp_data = {{8{curr_byte[7]}},curr_byte[7:0],disp_data[15:0]};
        end
        3'h3: begin
            disp_data = {curr_byte[7:0],disp_data[23:0]};
        end
        endcase

        disp_count++;
    end
    `ST_PARSE_IMM: begin
        nxt_status = `ST_PARSE_IMM;

        //$display("IMM SIZE = %x",imm_size);

        if (imm_size == 0 || imm_count == imm_size-1)
            reg_status = `ST_FIX_ADDR;
        else
            reg_status = `ST_GET_BYTE;
          

        case (imm_count)
        3'h0: begin
            opSRC_data = {{24{curr_byte[7]}},curr_byte[7:0]};
        end
        3'h1: begin
            opSRC_data = {{16{curr_byte[7]}},curr_byte[7:0],opSRC_data[7:0]};
        end
        3'h2: begin
            opSRC_data = {{8{curr_byte[7]}},curr_byte[7:0],opSRC_data[15:0]};
        end
        3'h3: begin
            opSRC_data = {curr_byte[7:0],opSRC_data[23:0]};
        end
        endcase

        imm_count++;
    end
    `ST_FIX_ADDR: begin
        reg_status = `ST_END_INST;

        if (opDEST_flags`FLG_OFF == 1)
            opDEST_data = disp_data;
        else if (opSRC_flags`FLG_OFF == 1)
            opSRC_data = disp_data;

        // fix the relative address
        if (opSRC_flags`FLG_REL == 1) begin
            opSRC_data = opSRC_data + instr_address + 5;
        end
        if (opDEST_flags`FLG_REL == 1) begin
            opDEST_data = opDEST_data + instr_address + 5;
        end
    end
    // print the instruction
    `ST_END_INST: begin
      $write("%x:\t%x\t%s",instr_address,instr,opcode_str);
      if (opSRC_flags`FLG_VAL == 1 || opDEST_flags`FLG_VAL == 1)
        $write("\t");
      if (opSRC_flags`FLG_VAL == 1) begin
        if (opSRC_flags`FLG_IMM == 1) begin
          $write("$0x%x",opSRC_data);
        end
        else if (opSRC_flags`FLG_ABS == 1) begin
          $write("0x%x",opSRC_data);
        end
        // offset
        else if (opSRC_flags`FLG_OFF == 1) begin
          $write("0x%x",opSRC_data);
          if (opSRC_flags`FLG_BAS == 1 || opSRC_flags`FLG_REG == 1) begin
            $write("(");
          end
          // base
          if (opSRC_flags`FLG_BAS == 1) begin
            `PRINT_REG(opSRC_base_reg)
          end
          // reg
          if (opSRC_flags`FLG_REG == 1) begin
            $write(",");
            `PRINT_REG(opSRC_reg)
          end
          // scale
          if (opSRC_flags`FLG_SCA == 1) begin
            $write(",%d",opSRC_scale);
          end
          if (opSRC_flags`FLG_BAS == 1 || opSRC_flags`FLG_REG == 1) begin
            $write(")");
          end
        end
        else if (opSRC_flags`FLG_REG == 1) begin
          if (opSRC_flags`FLG_MEM == 1)
            $write("(");
          `PRINT_REG(opSRC_reg)
          if (opSRC_flags`FLG_MEM == 1)
            $write(")");
        end

        if (opDEST_flags`FLG_VAL == 1)  
          $write(",");
      end
      if (opDEST_flags`FLG_VAL == 1) begin
        if (opDEST_flags`FLG_IMM == 1) begin
          $write("$0x%x",opDEST_data);
        end
        else if (opDEST_flags`FLG_ABS == 1) begin
          $write("0x%x",opDEST_data);
        end
        // offset
        else if (opDEST_flags`FLG_OFF == 1) begin
          $write("0x%x",opDEST_data);
          if (opDEST_flags`FLG_BAS == 1 || opDEST_flags`FLG_REG == 1) begin
            $write("(");
          end
          // base
          if (opDEST_flags`FLG_BAS == 1) begin
            `PRINT_REG(opDEST_base_reg)
          end
          // reg
          if (opDEST_flags`FLG_REG == 1) begin
            $write(",");
            `PRINT_REG(opDEST_reg)
          end
          // scale
          if (opDEST_flags`FLG_SCA == 1) begin
            $write(",%d",opDEST_scale);
          end
          if (opDEST_flags`FLG_BAS == 1 || opDEST_flags`FLG_REG == 1) begin
            $write(")");
          end
        end
        else if (opDEST_flags`FLG_REG == 1) begin
          if (opDEST_flags`FLG_MEM == 1)
            $write("(");
          `PRINT_REG(opDEST_reg)
          if (opDEST_flags`FLG_MEM == 1)
            $write(")");
        end
      end
      $display("");
      reg_status = `ST_IDLE;
    end
  

  endcase

end


endmodule

`endif
