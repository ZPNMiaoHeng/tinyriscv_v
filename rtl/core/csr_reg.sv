 /*                                                                      
 Copyright 2020 Blue Liang, liangkangnan@163.com
                                                                         
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

`include "defines.sv"

// CSR寄存器模块
module csr_reg(

    input wire clk,
    input wire rst_n,

    // exu
    input wire exu_we_i,                    // exu模块写寄存器标志
    input wire[31:0] exu_waddr_i,           // exu模块写寄存器地址
    input wire[31:0] exu_wdata_i,           // exu模块写寄存器数据
    input wire[31:0] exu_raddr_i,           // exu模块读寄存器地址
    output wire[31:0] exu_rdata_o,          // exu模块读寄存器数据

    // clint
    input wire clint_we_i,                  // clint模块写寄存器标志
    input wire[31:0] clint_waddr_i,         // clint模块写寄存器地址
    input wire[31:0] clint_wdata_i,         // clint模块写寄存器数据

    output wire[31:0] mtvec_o,              // mtvec寄存器值
    output wire[31:0] mepc_o,               // mepc寄存器值
    output wire[31:0] mstatus_o,            // mstatus寄存器值
    output wire[31:0] mie_o,                // mie寄存器值
    output wire[31:0] dpc_o                 // dpc寄存器值

    );

    reg[31:0] mtvec_d;
    wire[31:0] mtvec_q;
    reg mtvec_we;
    reg[31:0] mcause_d;
    wire[31:0] mcause_q;
    reg mcause_we;
    reg[31:0] mepc_d;
    wire[31:0] mepc_q;
    reg mepc_we;
    reg[31:0] mie_d;
    wire[31:0] mie_q;
    reg mie_we;
    reg[31:0] mstatus_d;
    wire[31:0] mstatus_q;
    reg mstatus_we;
    reg[31:0] mscratch_d;
    wire[31:0] mscratch_q;
    reg mscratch_we;
    reg[31:0] dscratch0_d;
    wire[31:0] dscratch0_q;
    reg dscratch0_we;
    reg[31:0] dscratch1_d;
    wire[31:0] dscratch1_q;
    reg dscratch1_we;
    reg[31:0] mhartid_d;
    wire[31:0] mhartid_q;
    reg mhartid_we;
    reg[31:0] dpc_d;
    wire[31:0] dpc_q;
    reg dpc_we;

    reg[63:0] cycle;

    // cycle counter
    // 复位撤销后就一直计数
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle <= {32'h0, 32'h0};
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    assign mtvec_o = mtvec_q;
    assign mepc_o = mepc_q;
    assign mstatus_o = mstatus_q;
    assign mie_o = mie_q;
    assign dpc_o = dpc_q;

    reg[31:0] exu_rdata;

    // exu模块读CSR寄存器
    always @ (*) begin
        case (exu_raddr_i[11:0])
            `CSR_CYCLE: begin
                exu_rdata = cycle[31:0];
            end
            `CSR_CYCLEH: begin
                exu_rdata = cycle[63:32];
            end
            `CSR_MTVEC: begin
                exu_rdata = mtvec_q;
            end
            `CSR_MCAUSE: begin
                exu_rdata = mcause_q;
            end
            `CSR_MEPC: begin
                exu_rdata = mepc_q;
            end
            `CSR_MIE: begin
                exu_rdata = mie_q;
            end
            `CSR_MSTATUS: begin
                exu_rdata = mstatus_q;
            end
            `CSR_MSCRATCH: begin
                exu_rdata = mscratch_q;
            end
            `CSR_DSCRATCH0: begin
                exu_rdata = dscratch0_q;
            end
            `CSR_DSCRATCH1: begin
                exu_rdata = dscratch1_q;
            end
            `CSR_MHARTID: begin
                exu_rdata = mhartid_q;
            end
            `CSR_DPC: begin
                exu_rdata = dpc_q;
            end
            default: begin
                exu_rdata = 32'h0;
            end
        endcase
    end

    assign exu_rdata_o = exu_rdata;

    // 写CSR寄存器
    wire we = exu_we_i | clint_we_i;
    wire[31:0] waddr = exu_we_i? exu_waddr_i: clint_waddr_i;
    wire[31:0] wdata = exu_we_i? exu_wdata_i: clint_wdata_i;

    always @ (*) begin
        mtvec_d = mtvec_q;
        mtvec_we = 1'b0;
        mcause_d = mcause_q;
        mcause_we = 1'b0;
        mepc_d = mepc_q;
        mepc_we = 1'b0;
        mie_d = mie_q;
        mie_we = 1'b0;
        mstatus_d = mstatus_q;
        mstatus_we = 1'b0;
        mscratch_d = mscratch_q;
        mscratch_we = 1'b0;
        dscratch0_d = dscratch0_q;
        dscratch0_we = 1'b0;
        dscratch1_d = dscratch1_q;
        dscratch1_we = 1'b0;
        mhartid_d = mhartid_q;
        mhartid_we = 1'b0;
        dpc_d = dpc_q;
        dpc_we = 1'b0;

        if (we) begin
            case (waddr[11:0])
                `CSR_MTVEC: begin
                    mtvec_d = wdata;
                    mtvec_we = 1'b1;
                end
                `CSR_MCAUSE: begin
                    mcause_d = wdata;
                    mcause_we = 1'b1;
                end
                `CSR_MEPC: begin
                    mepc_d = wdata;
                    mepc_we = 1'b1;
                end
                `CSR_MIE: begin
                    mie_d = wdata;
                    mie_we = 1'b1;
                end
                `CSR_MSTATUS: begin
                    mstatus_d = wdata;
                    mstatus_we = 1'b1;
                end
                `CSR_MSCRATCH: begin
                    mscratch_d = wdata;
                    mscratch_we = 1'b1;
                end
                `CSR_DSCRATCH0: begin
                    dscratch0_d = wdata;
                    dscratch0_we = 1'b1;
                end
                `CSR_DSCRATCH1: begin
                    dscratch1_d = wdata;
                    dscratch1_we = 1'b1;
                end
                `CSR_MHARTID: begin
                    mhartid_d = wdata;
                    mhartid_we = 1'b1;
                end
                `CSR_DPC: begin
                    dpc_d = wdata;
                    dpc_we = 1'b1;
                end
                default:;
            endcase
        end
    end

    // mtvec
    csr #(
        .RESET_VAL(32'h0)
    ) mtvec_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mtvec_d),
        .we_i(mtvec_we),
        .rdata_o(mtvec_q)
    );

    // mcause
    csr #(
        .RESET_VAL(32'h0)
    ) mcause_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mcause_d),
        .we_i(mcause_we),
        .rdata_o(mcause_q)
    );

    // mepc
    csr #(
        .RESET_VAL(32'h0)
    ) mepc_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mepc_d),
        .we_i(mepc_we),
        .rdata_o(mepc_q)
    );

    // mie
    csr #(
        .RESET_VAL(32'h0)
    ) mie_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mie_d),
        .we_i(mie_we),
        .rdata_o(mie_q)
    );

    // mstatus
    csr #(
        .RESET_VAL(32'h0)
    ) mstatus_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mstatus_d),
        .we_i(mstatus_we),
        .rdata_o(mstatus_q)
    );

    // mscratch
    csr #(
        .RESET_VAL(32'h0)
    ) mscratch_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mscratch_d),
        .we_i(mscratch_we),
        .rdata_o(mscratch_q)
    );

    // dscratch0
    csr #(
        .RESET_VAL(32'h0)
    ) dscratch0_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(dscratch0_d),
        .we_i(dscratch0_we),
        .rdata_o(dscratch0_q)
    );

    // dscratch1
    csr #(
        .RESET_VAL(32'h0)
    ) dscratch1_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(dscratch1_d),
        .we_i(dscratch1_we),
        .rdata_o(dscratch1_q)
    );

    // mhartid
    csr #(
        .RESET_VAL(32'h0)
    ) mhartid_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(mhartid_d),
        .we_i(mhartid_we),
        .rdata_o(mhartid_q)
    );

    // dpc
    csr #(
        .RESET_VAL(32'h0)
    ) dpc_csr (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_i(dpc_d),
        .we_i(dpc_we),
        .rdata_o(dpc_q)
    );

endmodule
