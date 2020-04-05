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

// identification module
module id(

	input wire rst,

    // from if_id
	input wire[`InstBus] inst_i,             // inst content
    input wire[`InstAddrBus] inst_addr_i,    // inst addr

    // from regs
    input wire[`RegBus] reg1_rdata_i,       // reg1 read data
    input wire[`RegBus] reg2_rdata_i,       // reg2 read data

    // from csr reg
    input wire[`RegBus] csr_rdata_i,

    // from ex
    input wire ex_jump_flag_i,
    input wire[`INT_BUS] ex_int_flag_i,

    // to regs
    output reg[`RegAddrBus] reg1_raddr_o,    // reg1 read addr
    output reg[`RegAddrBus] reg2_raddr_o,    // reg2 read addr

    // to csr reg
    output reg[`MemAddrBus] csr_raddr_o,

    output wire mem_req_o,

    // to ex
    output reg[`InstBus] inst_o,
    output reg[`InstAddrBus] inst_addr_o,
    output reg[`RegBus] reg1_rdata_o,        // reg1 read data
    output reg[`RegBus] reg2_rdata_o,        // reg2 read data
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o,     // reg write addr
    output reg csr_we_o,
    output reg[`RegBus] csr_rdata_o,
    output reg[`MemAddrBus] csr_waddr_o

    );

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];
    wire[4:0] rd = inst_i[11:7];
    wire[4:0] rs1 = inst_i[19:15];
    wire[4:0] rs2 = inst_i[24:20];

    reg mem_req;

    assign mem_req_o = ((mem_req == `RIB_REQ) && (ex_jump_flag_i == `JumpDisable) && (ex_int_flag_i == `INT_NONE));


    always @ (*) begin
        if (rst == `RstEnable) begin
            reg1_raddr_o <= `ZeroWord;
            reg2_raddr_o <= `ZeroWord;
            csr_raddr_o <= `ZeroWord;
            inst_o <= `INST_NOP;
            inst_addr_o <= `ZeroWord;
            reg1_rdata_o <= `ZeroWord;
            reg2_rdata_o <= `ZeroWord;
            csr_rdata_o <= `ZeroWord;
            reg_we_o <= `WriteDisable;
            csr_we_o <= `WriteDisable;
            reg_waddr_o <= `ZeroWord;
            csr_waddr_o <= `ZeroWord;
            mem_req <= `RIB_NREQ;
        end else begin
            inst_o <= inst_i;
            inst_addr_o <= inst_addr_i;
            reg1_rdata_o <= reg1_rdata_i;
            reg2_rdata_o <= reg2_rdata_i;
            csr_rdata_o <= csr_rdata_i;
            mem_req <= `RIB_NREQ;
            csr_raddr_o <= `ZeroWord;
            csr_waddr_o <= `ZeroWord;
            csr_we_o <= `WriteDisable;

            case (opcode)
                `INST_TYPE_I: begin
                    case (funct3)
                        `INST_ADDI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_SLTI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_SLTIU: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_XORI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_ORI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_ANDI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_SLLI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        `INST_SRI: begin
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                        end
                        default: begin
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_R_M: begin
                    if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                        case (funct3)
                            `INST_ADD_SUB: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_SLL: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_SLT: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_SLTU: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_XOR: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_SR: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_OR: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_AND: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            default: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= `ZeroWord;
                                reg1_raddr_o <= `ZeroWord;
                                reg2_raddr_o <= `ZeroWord;
                            end
                        endcase
                    end else if (funct7 == 7'b0000001) begin
                        case (funct3)
                            `INST_MUL: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_MULHU: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_MULH: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_MULHSU: begin
                                reg_we_o <= `WriteEnable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_DIV: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_DIVU: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_REM: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            `INST_REMU: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= rd;
                                reg1_raddr_o <= rs1;
                                reg2_raddr_o <= rs2;
                            end
                            default: begin
                                reg_we_o <= `WriteDisable;
                                reg_waddr_o <= `ZeroWord;
                                reg1_raddr_o <= `ZeroWord;
                                reg2_raddr_o <= `ZeroWord;
                            end
                        endcase
                    end else begin
                        reg_we_o <= `WriteDisable;
                        reg_waddr_o <= `ZeroWord;
                        reg1_raddr_o <= `ZeroWord;
                        reg2_raddr_o <= `ZeroWord;
                    end
                end
                `INST_TYPE_L: begin
                    case (funct3)
                        `INST_LB: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_LH: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_LW: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_LBU: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_LHU: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            mem_req <= `RIB_REQ;
                        end
                        default: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_S: begin
                    case (funct3)
                        `INST_SB: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_SH: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                            mem_req <= `RIB_REQ;
                        end
                        `INST_SW: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                            mem_req <= `RIB_REQ;
                        end
                        default: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                    endcase
                end
                `INST_TYPE_B: begin
                    case (funct3)
                        `INST_BEQ: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        `INST_BNE: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        `INST_BLT: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        `INST_BGE: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        `INST_BLTU: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        `INST_BGEU: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= rs2;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                        default: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                        end
                    endcase
                end
                `INST_JAL: begin
                    reg_we_o <= `WriteEnable;
                    reg_waddr_o <= rd;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
                `INST_JALR: begin
                    reg_we_o <= `WriteEnable;
					reg1_raddr_o <= rs1;
                    reg2_raddr_o <= `ZeroWord;
                    reg_waddr_o <= rd;
                end
                `INST_LUI: begin
                    reg_we_o <= `WriteEnable;
                    reg_waddr_o <= rd;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
                `INST_AUIPC: begin
                    reg_we_o <= `WriteEnable;
                    reg_waddr_o <= rd;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
                `INST_NOP: begin
                    reg_we_o <= `WriteDisable;
                    reg_waddr_o <= `ZeroWord;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
                `INST_FENCE: begin
                    reg_we_o <= `WriteDisable;
                    reg_waddr_o <= `ZeroWord;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
                `INST_CSR: begin
                    reg_we_o <= `WriteDisable;
                    reg_waddr_o <= `ZeroWord;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                    csr_raddr_o <= {20'h0, inst_i[31:20]};
                    csr_waddr_o <= {20'h0, inst_i[31:20]};
                    case (funct3)
                        `INST_CSRRW: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        `INST_CSRRS: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        `INST_CSRRC: begin
                            reg1_raddr_o <= rs1;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        `INST_CSRRWI: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        `INST_CSRRSI: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        `INST_CSRRCI: begin
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            reg_we_o <= `WriteEnable;
                            reg_waddr_o <= rd;
                            csr_we_o <= `WriteEnable;
                        end
                        default: begin
                            reg_we_o <= `WriteDisable;
                            reg_waddr_o <= `ZeroWord;
                            reg1_raddr_o <= `ZeroWord;
                            reg2_raddr_o <= `ZeroWord;
                            csr_we_o <= `WriteDisable;
                        end
                    endcase
                end
                default: begin
                    reg_we_o <= `WriteDisable;
                    reg_waddr_o <= `ZeroWord;
                    reg1_raddr_o <= `ZeroWord;
                    reg2_raddr_o <= `ZeroWord;
                end
            endcase
        end
    end

endmodule
