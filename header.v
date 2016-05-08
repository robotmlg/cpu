`ifndef HEADER_V
`define HEADER_V

`define ADDRESS_WIDTH 32 // 32 bit addresses
`define DATA_WIDTH 32    // 4 byte memory lines
//`define DATA_WIDTH 512    // 64 byte memory lines
`define MAX_INSTR_WIDTH 120 // 15 bytes, x86 


// general register macros and segment macros
`define REG_EAX 4'h0
`define REG_ECX 4'h1
`define REG_EDX 4'h2
`define REG_EBX 4'h3
`define REG_ESP 4'h4
`define REG_EBP 4'h5
`define REG_ESI 4'h6
`define REG_EDI 4'h7
`define SEG_CS  4'h8
`define SEG_SS  4'h9
`define SEG_DS  4'hA
`define SEG_ES  4'hB
`define SEG_FS  4'hC
`define SEG_GS  4'hD

// operand addressing mdoe flag macros
`define FLG_VAL [8]  // whether this operand is used
`define FLG_REL [7]  // this is an immediate relative address offset
`define FLG_IMM [6]  // this is an immediate operand
`define FLG_ABS [5]  // this is an absolute mem address
`define FLG_REG [4]  // this operand has a register
`define FLG_MEM [3]  // this operand references memory
`define FLG_SCA [2]  // this operand has a register scale factor
`define FLG_OFF [1]  // this operand has a register offset
`define FLG_BAS [0]  // this operand has a base register offset
`define FLG_RESET [8:0]
`define RESET_FLAGS 9'b0

// simplified opcodes
`define OPC_PUSH    8'h00
`define OPC_POP     8'h01
`define OPC_ADD     8'h02
`define OPC_OR      8'h03
`define OPC_ADC     8'h04
`define OPC_SBB     8'h05
`define OPC_AND     8'h06
`define OPC_SUB     8'h07
`define OPC_XOR     8'h08
`define OPC_CMP     8'h09
`define OPC_MOV     8'h0A
`define OPC_DAA     8'h0B
`define OPC_AAA     8'h0C
`define OPC_DAS     8'h0D
`define OPC_AAS     8'h0E

`endif
