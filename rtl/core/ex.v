 /*                                                                      
 Copyright 2019 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

`include "defines.v"

// execute and writeback module
module ex(

    input wire rst,

    // from id
    input wire[`InstBus] inst_i,            // inst content
    input wire[`InstAddrBus] inst_addr_i,   // inst addr
    input wire reg_we_i,
    input wire[`RegAddrBus] reg_waddr_i,
    input wire[`RegBus] reg1_rdata_i,       // reg1 read data
    input wire[`RegBus] reg2_rdata_i,       // reg2 read data

    // from mem
    input wire[`MemBus] mem_rdata_i,      // mem read data

    // from div
    input wire div_ready_i,
    input wire[`DoubleRegBus] div_result_i,
    input wire div_busy_i,
    input wire[2:0] div_op_i,
    input wire[`RegAddrBus] div_reg_waddr_i,

    // from core
    input wire[`INT_BUS] int_flag_i,

    // from clint
    input wire[`RegBus] clint_data_i,

    // to mem
    output reg[`MemBus] mem_wdata_o,      // mem write data
    output reg[`MemAddrBus] mem_raddr_o,  // mem read addr
    output reg[`MemAddrBus] mem_waddr_o,  // mem write addr
    output reg mem_we_o,                  // mem write enable
    output reg mem_req_o,

    // to regs
    output wire[`RegBus] reg_wdata_o,        // reg write data
    output wire reg_we_o,                    // reg write enable
    output wire[`RegAddrBus] reg_waddr_o,    // reg write addr

    // to div
    output reg div_start_o,
    output reg[`RegBus] div_dividend_o,
    output reg[`RegBus] div_divisor_o,
    output reg[2:0] div_op_o,
    output reg[`RegAddrBus] div_reg_waddr_o,

    // to clint
    output reg clint_we_o,
    output reg[`RegAddrBus] clint_addr_o,
    output reg[`RegBus] clint_data_o,

    // to ctrl
    output reg[`InstAddrBus] int_return_addr_o,
    output reg[`INT_BUS] int_flag_o,
    output wire hold_flag_o,
    output wire jump_flag_o,                // whether jump or not flag
    output wire[`InstAddrBus] jump_addr_o   // jump dest addr

    );

    wire[31:0] sign_extend_tmp;
    wire[4:0] shift_bits;
    wire[1:0] mem_raddr_index;
    wire[1:0] mem_waddr_index;
    wire[`DoubleRegBus] mul_temp;
    wire[`DoubleRegBus] mul_temp_invert;
    reg[`RegBus] mul_op1;
    reg[`RegBus] mul_op2;
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[4:0] rd;
    reg[`RegBus] reg_wdata;
    reg reg_we;
    reg[`RegAddrBus] reg_waddr;
    reg[`RegBus] div_wdata;
    reg div_we;
    reg[`RegAddrBus] div_waddr;
    reg div_hold_flag;
    reg div_jump_flag;
    reg[`InstAddrBus] div_jump_addr;
    reg hold_flag;
    reg jump_flag;
    reg[`InstAddrBus] jump_addr;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];
    assign rd = inst_i[11:7];

    assign sign_extend_tmp = {{20{inst_i[31]}}, inst_i[31:20]};
    assign shift_bits = inst_i[24:20];

    assign mul_temp = mul_op1 * mul_op2;
    assign mul_temp_invert = ~mul_temp + 1;

    assign mem_raddr_index = ((reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) - ((reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & 32'hfffffffc)) & 2'b11;
    assign mem_waddr_index = ((reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}) - (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]} & 32'hfffffffc)) & 2'b11;

    assign reg_wdata_o = reg_wdata | div_wdata;
    assign reg_we_o = reg_we || div_we;
    assign reg_waddr_o = reg_waddr | div_waddr;

    assign hold_flag_o = hold_flag || div_hold_flag;
    assign jump_flag_o = jump_flag || div_jump_flag;
    assign jump_addr_o = jump_addr | div_jump_addr;


    // handle interrupt
    always @ (*) begin
        if (rst == `RstEnable) begin
            int_flag_o <= `INT_NONE;
            clint_we_o <= `WriteDisable;
            clint_addr_o <= `ZeroWord;
            clint_data_o <= `ZeroWord;
            int_return_addr_o <= `ZeroWord;
        end else if (int_flag_i != `INT_NONE) begin
            clint_addr_o <= `ZeroWord;
            int_return_addr_o <= `ZeroWord;
            if (clint_data_i[0] == 1'b0) begin
                int_flag_o <= int_flag_i;
                clint_we_o <= `WriteEnable;
                clint_data_o <= inst_addr_i + 4'h4 + 1'b1;  // save return address and set interrupt flag
            end else begin
                int_flag_o <= `INT_NONE;
                clint_we_o <= `WriteDisable;
                clint_data_o <= `ZeroWord;
            end
        end else begin
            clint_addr_o <= `ZeroWord;
            int_return_addr_o <= `ZeroWord;
            if (inst_i == `INST_MRET) begin
                int_flag_o <= `INT_RET;
                int_return_addr_o <= {clint_data_i[31:2], 2'b00};
                clint_we_o <= `WriteEnable;
                clint_data_o <= `ZeroWord;
            end else begin
                int_flag_o <= `INT_NONE;
                clint_we_o <= `WriteDisable;
                clint_data_o <= `ZeroWord;
            end
        end
    end

    // handle mul
    always @ (*) begin
        if (rst == `RstEnable) begin
            mul_op1 <= `ZeroWord;
            mul_op2 <= `ZeroWord;
        end else begin
            if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
                if ((funct3 == `INST_MUL) || (funct3 == `INST_MULHU)) begin
                    mul_op1 <= reg1_rdata_i;
                    mul_op2 <= reg2_rdata_i;
                end else if (funct3 == `INST_MULHSU) begin
                    mul_op1 <= (reg1_rdata_i[31] == 1'b1)? (~reg1_rdata_i + 1): reg1_rdata_i;
                    mul_op2 <= reg2_rdata_i;
                end else if (funct3 == `INST_MULH) begin
                    mul_op1 <= (reg1_rdata_i[31] == 1'b1)? (~reg1_rdata_i + 1): reg1_rdata_i;
                    mul_op2 <= (reg2_rdata_i[31] == 1'b1)? (~reg2_rdata_i + 1): reg2_rdata_i;
                end else begin
                    mul_op1 <= reg1_rdata_i;
                    mul_op2 <= reg2_rdata_i;
                end
            end else begin
                mul_op1 <= reg1_rdata_i;
                mul_op2 <= reg2_rdata_i;
            end
        end
    end

    // handle div
    always @ (*) begin
        if (rst == `RstEnable) begin
            div_dividend_o <= `ZeroWord;
            div_divisor_o <= `ZeroWord;
            div_op_o <= 3'b0;
            div_reg_waddr_o <= `ZeroWord;
            div_waddr <= `ZeroWord;
            div_hold_flag <= `HoldDisable;
            div_we <= `WriteDisable;
            div_wdata <= `ZeroWord;
            div_start_o <= `DivStop;
            div_jump_flag <= `JumpDisable;
            div_jump_addr <= `ZeroWord;
        end else begin
            div_dividend_o <= reg1_rdata_i;
            div_divisor_o <= reg2_rdata_i;
            div_op_o <= funct3;
            div_reg_waddr_o <= reg_waddr_i;
            if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
                div_we <= `WriteDisable;
                div_wdata <= `ZeroWord;
                div_waddr <= `ZeroWord;
                case (funct3)
                    `INST_DIV: begin
                        div_start_o <= `DivStart;
                        div_jump_flag <= `JumpEnable;
                        div_hold_flag <= `HoldEnable;
                        div_jump_addr <= inst_addr_i + 4'h4;
                    end
                    `INST_DIVU: begin
                        div_start_o <= `DivStart;
                        div_jump_flag <= `JumpEnable;
                        div_hold_flag <= `HoldEnable;
                        div_jump_addr <= inst_addr_i + 4'h4;
                    end
                    `INST_REM: begin
                        div_start_o <= `DivStart;
                        div_jump_flag <= `JumpEnable;
                        div_hold_flag <= `HoldEnable;
                        div_jump_addr <= inst_addr_i + 4'h4;
                    end
                    `INST_REMU: begin
                        div_start_o <= `DivStart;
                        div_jump_flag <= `JumpEnable;
                        div_hold_flag <= `HoldEnable;
                        div_jump_addr <= inst_addr_i + 4'h4;
                    end
                    default: begin
                        div_start_o <= `DivStop;
                        div_jump_flag <= `JumpDisable;
                        div_hold_flag <= `HoldDisable;
                        div_jump_addr <= `ZeroWord;
                    end
                endcase
            end else begin
                div_jump_flag <= `JumpDisable;
                div_jump_addr <= `ZeroWord;
                if (div_busy_i == `True) begin
                    div_start_o <= `DivStart;
                    div_we <= `WriteDisable;
                    div_wdata <= `ZeroWord;
                    div_waddr <= `ZeroWord;
                    div_hold_flag <= `HoldEnable;
                end else begin
                    div_start_o <= `DivStop;
                    div_hold_flag <= `HoldDisable;
                    if (div_ready_i == `DivResultReady) begin
                        case (div_op_i)
                            `INST_DIV: begin
                                div_wdata <= div_result_i[31:0];
                                div_waddr <= div_reg_waddr_i;
                                div_we <= `WriteEnable;
                            end
                            `INST_DIVU: begin
                                div_wdata <= div_result_i[31:0];
                                div_waddr <= div_reg_waddr_i;
                                div_we <= `WriteEnable;
                            end
                            `INST_REM: begin
                                div_wdata <= div_result_i[63:32];
                                div_waddr <= div_reg_waddr_i;
                                div_we <= `WriteEnable;
                            end
                            `INST_REMU: begin
                                div_wdata <= div_result_i[63:32];
                                div_waddr <= div_reg_waddr_i;
                                div_we <= `WriteEnable;
                            end
                            default: begin
                                div_wdata <= `ZeroWord;
                                div_waddr <= `ZeroWord;
                                div_we <= `WriteDisable;
                            end
                        endcase
                    end else begin
                        div_we <= `WriteDisable;
                        div_wdata <= `ZeroWord;
                        div_waddr <= `ZeroWord;
                    end
                end
            end
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            jump_flag <= `JumpDisable;
            hold_flag <= `HoldDisable;
            jump_addr <= `ZeroWord;
            mem_wdata_o <= `ZeroWord;
            mem_raddr_o <= `ZeroWord;
            mem_waddr_o <= `ZeroWord;
            mem_we_o <= `WriteDisable;
            mem_req_o <= `RIB_NREQ;
            reg_wdata <= `ZeroWord;
            reg_we <= `WriteDisable;
            reg_waddr <= `ZeroWord;
        end else begin
            reg_we <= reg_we_i;
            reg_waddr <= reg_waddr_i;
            mem_req_o <= `RIB_NREQ;

            case (opcode)
                `INST_TYPE_I: begin
                    case (funct3)
                        `INST_ADDI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `INST_SLTI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            if (reg1_rdata_i[31] == 1'b1 && sign_extend_tmp[31] == 1'b1) begin
                                if (reg1_rdata_i < sign_extend_tmp) begin
                                    reg_wdata <= 32'h00000001;
                                end else begin
                                    reg_wdata <= 32'h00000000;
                                end
                            end else if (reg1_rdata_i[31] == 1'b1 && sign_extend_tmp[31] == 1'b0) begin
                                reg_wdata <= 32'h00000001;
                            end else if (reg1_rdata_i[31] == 1'b0 && sign_extend_tmp[31] == 1'b1) begin
                                reg_wdata <= 32'h00000000;
                            end else begin
                                if (reg1_rdata_i < sign_extend_tmp) begin
                                    reg_wdata <= 32'h00000001;
                                end else begin
                                    reg_wdata <= 32'h00000000;
                                end
                            end
                        end
                        `INST_SLTIU: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            if (reg1_rdata_i[31] == 1'b1 && sign_extend_tmp[31] == 1'b1) begin
                                if (reg1_rdata_i < sign_extend_tmp) begin
                                    reg_wdata <= 32'h00000001;
                                end else begin
                                    reg_wdata <= 32'h00000000;
                                end
                            end else if (reg1_rdata_i[31] == 1'b1 && sign_extend_tmp[31] == 1'b0) begin
                                reg_wdata <= 32'h00000000;
                            end else if (reg1_rdata_i[31] == 1'b0 && sign_extend_tmp[31] == 1'b1) begin
                                reg_wdata <= 32'h00000001;
                            end else begin
                                if (reg1_rdata_i < sign_extend_tmp) begin
                                    reg_wdata <= 32'h00000001;
                                end else begin
                                    reg_wdata <= 32'h00000000;
                                end
                            end
                        end
                        `INST_XORI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= reg1_rdata_i ^ {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `INST_ORI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= reg1_rdata_i | {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `INST_ANDI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= reg1_rdata_i & {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `INST_SLLI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= reg1_rdata_i << shift_bits;
                        end
                        `INST_SRI: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            if (inst_i[30] == 1'b1) begin
                                reg_wdata <= ({32{reg1_rdata_i[31]}} << (6'd32 - {1'b0, shift_bits})) | (reg1_rdata_i >> shift_bits);
                            end else begin
                                reg_wdata <= reg1_rdata_i >> shift_bits;
                            end
                        end
                        default: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_R_M: begin
                    if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                        case (funct3)
                            `INST_ADD_SUB: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if (inst_i[30] == 1'b0) begin
                                    reg_wdata <= reg1_rdata_i + reg2_rdata_i;
                                end else begin
                                    reg_wdata <= reg1_rdata_i - reg2_rdata_i;
                                end
                            end
                            `INST_SLL: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= reg1_rdata_i << reg2_rdata_i[4:0];
                            end
                            `INST_SLT: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                    if (reg1_rdata_i < reg2_rdata_i) begin
                                        reg_wdata <= 32'h00000001;
                                    end else begin
                                        reg_wdata <= 32'h00000000;
                                    end
                                end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b0) begin
                                    reg_wdata <= 32'h00000001;
                                end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b1) begin
                                    reg_wdata <= 32'h00000000;
                                end else begin
                                    if (reg1_rdata_i < reg2_rdata_i) begin
                                        reg_wdata <= 32'h00000001;
                                    end else begin
                                        reg_wdata <= 32'h00000000;
                                    end
                                end
                            end
                            `INST_SLTU: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                    if (reg1_rdata_i < reg2_rdata_i) begin
                                        reg_wdata <= 32'h00000001;
                                    end else begin
                                        reg_wdata <= 32'h00000000;
                                    end
                                end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b0) begin
                                    reg_wdata <= 32'h00000000;
                                end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b1) begin
                                    reg_wdata <= 32'h00000001;
                                end else begin
                                    if (reg1_rdata_i < reg2_rdata_i) begin
                                        reg_wdata <= 32'h00000001;
                                    end else begin
                                        reg_wdata <= 32'h00000000;
                                    end
                                end
                            end
                            `INST_XOR: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= reg1_rdata_i ^ reg2_rdata_i;
                            end
                            `INST_SR: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if (inst_i[30] == 1'b1) begin
                                    reg_wdata <= ({32{reg1_rdata_i[31]}} << (6'd32 - {1'b0, reg2_rdata_i[4:0]})) | (reg1_rdata_i >> reg2_rdata_i[4:0]);
                                end else begin
                                    reg_wdata <= reg1_rdata_i >> reg2_rdata_i[4:0];
                                end
                            end
                            `INST_OR: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= reg1_rdata_i | reg2_rdata_i;
                            end
                            `INST_AND: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= reg1_rdata_i & reg2_rdata_i;
                            end
                            default: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end
                        endcase
                    end else if (funct7 == 7'b0000001) begin
                        case (funct3)
                            `INST_MUL: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= mul_temp[31:0];
                            end
                            `INST_MULHU: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= mul_temp[63:32];
                            end
                            `INST_MULH: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if ((reg1_rdata_i[31] == 1'b0) && (reg2_rdata_i[31] == 1'b0)) begin
                                    reg_wdata <= mul_temp[63:32];
                                end else if ((reg1_rdata_i[31] == 1'b1) && (reg2_rdata_i[31] == 1'b1)) begin
                                    reg_wdata <= mul_temp[63:32];
                                end else if ((reg1_rdata_i[31] == 1'b1) && (reg2_rdata_i[31] == 1'b0)) begin
                                    reg_wdata <= mul_temp_invert[63:32];
                                end else begin
                                    reg_wdata <= mul_temp_invert[63:32];
                                end
                            end
                            `INST_MULHSU: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                if (reg1_rdata_i[31] == 1'b1) begin
                                    reg_wdata <= mul_temp_invert[63:32];
                                end else begin
                                    reg_wdata <= mul_temp[63:32];
                                end
                            end/*
                            `INST_DIV: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end
                            `INST_DIVU: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end
                            `INST_REM: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end
                            `INST_REMU: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end*/
                            default: begin
                                jump_flag <= `JumpDisable;
                                hold_flag <= `HoldDisable;
                                jump_addr <= `ZeroWord;
                                mem_wdata_o <= `ZeroWord;
                                mem_raddr_o <= `ZeroWord;
                                mem_waddr_o <= `ZeroWord;
                                mem_we_o <= `WriteDisable;
                                reg_wdata <= `ZeroWord;
                            end
                        endcase
                    end else begin
                        jump_flag <= `JumpDisable;
                        hold_flag <= `HoldDisable;
                        jump_addr <= `ZeroWord;
                        mem_wdata_o <= `ZeroWord;
                        mem_raddr_o <= `ZeroWord;
                        mem_waddr_o <= `ZeroWord;
                        mem_we_o <= `WriteDisable;
                        reg_wdata <= `ZeroWord;
                    end
                end
                `INST_TYPE_L: begin
                    case (funct3)
                        `INST_LB: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            //mem_req_o <= `RIB_REQ;
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                            if (mem_raddr_index == 2'b0) begin
                                reg_wdata <= {{24{mem_rdata_i[7]}}, mem_rdata_i[7:0]};
                            end else if (mem_raddr_index == 2'b01) begin
                                reg_wdata <= {{24{mem_rdata_i[15]}}, mem_rdata_i[15:8]};
                            end else if (mem_raddr_index == 2'b10) begin
                                reg_wdata <= {{24{mem_rdata_i[23]}}, mem_rdata_i[23:16]};
                            end else begin
                                reg_wdata <= {{24{mem_rdata_i[31]}}, mem_rdata_i[31:24]};
                            end
                        end
                        `INST_LH: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            //mem_req_o <= `RIB_REQ;
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                            if (mem_raddr_index == 2'b0) begin
                                reg_wdata <= {{16{mem_rdata_i[15]}}, mem_rdata_i[15:0]};
                            end else begin
                                reg_wdata <= {{16{mem_rdata_i[31]}}, mem_rdata_i[31:16]};
                            end
                        end
                        `INST_LW: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            //mem_req_o <= `RIB_REQ;
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                            reg_wdata <= mem_rdata_i;
                        end
                        `INST_LBU: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            //mem_req_o <= `RIB_REQ;
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                            if (mem_raddr_index == 2'b0) begin
                                reg_wdata <= {24'h0, mem_rdata_i[7:0]};
                            end else if (mem_raddr_index == 2'b01) begin
                                reg_wdata <= {24'h0, mem_rdata_i[15:8]};
                            end else if (mem_raddr_index == 2'b10) begin
                                reg_wdata <= {24'h0, mem_rdata_i[23:16]};
                            end else begin
                                reg_wdata <= {24'h0, mem_rdata_i[31:24]};
                            end
                        end
                        `INST_LHU: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            //mem_req_o <= `RIB_REQ;
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]};
                            if (mem_raddr_index == 2'b0) begin
                                reg_wdata <= {16'h0, mem_rdata_i[15:0]};
                            end else begin
                                reg_wdata <= {16'h0, mem_rdata_i[31:16]};
                            end
                        end
                        default: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_S: begin
                    case (funct3)
                        `INST_SB: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            reg_wdata <= `ZeroWord;
                            mem_we_o <= `WriteEnable;
                            mem_req_o <= `RIB_REQ;
                            mem_waddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            if (mem_waddr_index == 2'b00) begin
                                mem_wdata_o <= {mem_rdata_i[31:8], reg2_rdata_i[7:0]};
                            end else if (mem_waddr_index == 2'b01) begin
                                mem_wdata_o <= {mem_rdata_i[31:16], reg2_rdata_i[7:0], mem_rdata_i[7:0]};
                            end else if (mem_waddr_index == 2'b10) begin
                                mem_wdata_o <= {mem_rdata_i[31:24], reg2_rdata_i[7:0], mem_rdata_i[15:0]};
                            end else begin
                                mem_wdata_o <= {reg2_rdata_i[7:0], mem_rdata_i[23:0]};
                            end
                        end
                        `INST_SH: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            reg_wdata <= `ZeroWord;
                            mem_we_o <= `WriteEnable;
                            mem_req_o <= `RIB_REQ;
                            mem_waddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            if (mem_waddr_index == 2'b00) begin
                                mem_wdata_o <= {mem_rdata_i[31:16], reg2_rdata_i[15:0]};
                            end else begin
                                mem_wdata_o <= {reg2_rdata_i[15:0], mem_rdata_i[15:0]};
                            end
                        end
                        `INST_SW: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            reg_wdata <= `ZeroWord;
                            mem_we_o <= `WriteEnable;
                            mem_req_o <= `RIB_REQ;
                            mem_waddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            mem_raddr_o <= reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                            mem_wdata_o <= reg2_rdata_i;
                        end
                        default: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_B: begin
                    case (funct3)
                        `INST_BEQ: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i == reg2_rdata_i) begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end else begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end
                        end
                        `INST_BNE: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i != reg2_rdata_i) begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end else begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end
                        end
                        `INST_BLT: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b0) begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                if (reg1_rdata_i >= reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b0) begin
                                if (reg1_rdata_i >= reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end
                        end
                        `INST_BGE: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b1) begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                if (reg1_rdata_i < reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b0) begin
                                if (reg1_rdata_i < reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end
                        end
                        `INST_BLTU: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b0) begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                if (reg1_rdata_i >= reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b0) begin
                                if (reg1_rdata_i >= reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end
                        end
                        `INST_BGEU: begin
                            hold_flag <= `HoldDisable;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                            if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b1) begin
                                jump_flag <= `JumpDisable;
                                jump_addr <= `ZeroWord;
                            end else if (reg1_rdata_i[31] == 1'b1 && reg2_rdata_i[31] == 1'b1) begin
                                if (reg1_rdata_i < reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else if (reg1_rdata_i[31] == 1'b0 && reg2_rdata_i[31] == 1'b0) begin
                                if (reg1_rdata_i < reg2_rdata_i) begin
                                    jump_flag <= `JumpDisable;
                                    jump_addr <= `ZeroWord;
                                end else begin
                                    jump_flag <= `JumpEnable;
                                    jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                                end
                            end else begin
                                jump_flag <= `JumpEnable;
                                jump_addr <= inst_addr_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                            end
                        end
                        default: begin
                            jump_flag <= `JumpDisable;
                            hold_flag <= `HoldDisable;
                            jump_addr <= `ZeroWord;
                            mem_wdata_o <= `ZeroWord;
                            mem_raddr_o <= `ZeroWord;
                            mem_waddr_o <= `ZeroWord;
                            mem_we_o <= `WriteDisable;
                            reg_wdata <= `ZeroWord;
                        end
                    endcase
                end
                `INST_JAL: begin
                    hold_flag <= `HoldDisable;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    jump_flag <= `JumpEnable;
                    jump_addr <= inst_addr_i + {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
                    reg_wdata <= inst_addr_i + 4'h4;
                end
                `INST_JALR: begin
                    hold_flag <= `HoldDisable;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    jump_flag <= `JumpEnable;
                    jump_addr <= (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & (32'hfffffffe);
                    reg_wdata <= inst_addr_i + 4'h4;
                end
                `INST_LUI: begin
                    hold_flag <= `HoldDisable;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    jump_addr <= `ZeroWord;
                    jump_flag <= `JumpDisable;
                    reg_wdata <= {inst_i[31:12], 12'b0};
                end
                `INST_AUIPC: begin
                    hold_flag <= `HoldDisable;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    jump_addr <= `ZeroWord;
                    jump_flag <= `JumpDisable;
                    reg_wdata <= {inst_i[31:12], 12'b0} + inst_addr_i;
                end
                `INST_NOP: begin
                    jump_flag <= `JumpDisable;
                    hold_flag <= `HoldDisable;
                    jump_addr <= `ZeroWord;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    reg_wdata <= `ZeroWord;
                end
                `INST_FENCE: begin
                    hold_flag <= `HoldDisable;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    reg_wdata <= `ZeroWord;
                    jump_flag <= `JumpEnable;
                    jump_addr <= inst_addr_i + 4'h4;
                end
                default: begin
                    jump_flag <= `JumpDisable;
                    hold_flag <= `HoldDisable;
                    jump_addr <= `ZeroWord;
                    mem_wdata_o <= `ZeroWord;
                    mem_raddr_o <= `ZeroWord;
                    mem_waddr_o <= `ZeroWord;
                    mem_we_o <= `WriteDisable;
                    reg_wdata <= `ZeroWord;
                end
            endcase
        end
    end

endmodule
