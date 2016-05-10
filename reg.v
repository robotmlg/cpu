`ifndef REG_V
`define REG_V

`include "header.v"

`define REG_CMD_WIDTH   2
`define REG_CMD_READ    `REG_CMD_WIDTH'h0
`define REG_CMD_WRITE   `REG_CMD_WIDTH'h1
`define REG_CMD_MARKD   `REG_CMD_WIDTH'h2 // mark register as dirty,
                                          // i.e., will be written to soon
`define REG_CMD_CHECK   `REG_CMD_WIDTH'h3

module reg_file(
  input clk,
  input reset,

  input [3:0] i_reg,
  input [`DATA_WIDTH-1:0] i_data,
  input [`REG_CMD_WIDTH-1:0] i_cmd,
  input i_valid,
  input i_res_ready,

  output [`DATA_WIDTH-1:0] o_data,
  output o_res_valid,
  output o_ready
);

reg [`DATA_WIDTH-1:0] data;
reg res_valid;
reg ready;

assign o_data = data;
assign o_res_valid = res_valid;
assign o_ready = ready;

reg [`DATA_WIDTH-1:0] eax = 0;
reg d_eax = 0;
reg [`DATA_WIDTH-1:0] ecx = 0;
reg d_ecx = 0;
reg [`DATA_WIDTH-1:0] edx = 0;
reg d_edx = 0;
reg [`DATA_WIDTH-1:0] ebx = 0;
reg d_ebx = 0;
reg [`DATA_WIDTH-1:0] esp = 0;
reg d_esp = 0;
reg [`DATA_WIDTH-1:0] ebp = 0;
reg d_ebp = 0;
reg [`DATA_WIDTH-1:0] esi = 0;
reg d_esi = 0;
reg [`DATA_WIDTH-1:0] edi = 0;
reg d_edi = 0;


// reset
always @(posedge clk) begin
    if (reset) begin
        ready = 1'b1;
        res_valid = 1'b0;
        data  = 1'bx;
    end

    if (!reset && i_valid && ready) begin
        case (i_cmd)
        `REG_CMD_READ: begin
            case (i_reg)
            `REG_EAX: data <= eax;
            `REG_ECX: data <= ecx;
            `REG_EDX: data <= edx;
            `REG_EBX: data <= ebx;
            `REG_ESP: data <= esp;
            `REG_EBP: data <= ebp;
            `REG_ESI: data <= esi;
            `REG_EDI: data <= edi;
            endcase
        end
        `REG_CMD_WRITE: begin
            case (i_reg)
            `REG_EAX: begin eax <= i_data; d_eax = 0; end  
            `REG_ECX: begin ecx <= i_data; d_ecx = 0; end
            `REG_EDX: begin edx <= i_data; d_edx = 0; end
            `REG_EBX: begin ebx <= i_data; d_ebx = 0; end
            `REG_ESP: begin esp <= i_data; d_esp = 0; end
            `REG_EBP: begin ebp <= i_data; d_ebp = 0; end
            `REG_ESI: begin esi <= i_data; d_esi = 0; end
            `REG_EDI: begin edi <= i_data; d_edi = 0; end
            endcase
        end
        `REG_CMD_MARKD: begin
            case (i_reg)
            `REG_EAX:  d_eax = 1;  
            `REG_ECX:  d_ecx = 1; 
            `REG_EDX:  d_edx = 1; 
            `REG_EBX:  d_ebx = 1; 
            `REG_ESP:  d_esp = 1; 
            `REG_EBP:  d_ebp = 1; 
            `REG_ESI:  d_esi = 1; 
            `REG_EDI:  d_edi = 1; 
            endcase
        end
        `REG_CMD_CHECK: begin
            case (i_reg)
            `REG_EAX: data <= {{31{1'b0}},d_eax};
            `REG_ECX: data <= {{31{1'b0}},d_ecx};
            `REG_EDX: data <= {{31{1'b0}},d_edx};
            `REG_EBX: data <= {{31{1'b0}},d_ebx};
            `REG_ESP: data <= {{31{1'b0}},d_esp};
            `REG_EBP: data <= {{31{1'b0}},d_ebp};
            `REG_ESI: data <= {{31{1'b0}},d_esi};
            `REG_EDI: data <= {{31{1'b0}},d_edi};
            endcase
        end
        endcase
        res_valid <= 1'b1;
        ready <= 1'b0;
    end

    if (!reset && res_valid && i_res_ready) begin
        ready <= 1'b1;
        res_valid <= 1'b0;
        data  <= 1'bx;
    end
end

endmodule
`endif
