 /*                                                                      
 Copyright 2021 Blue Liang, liangkangnan@163.com
                                                                         
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

`define CAUSE_IRQ_EXTERNAL_M    {1'b1, 31'd11}
`define CAUSE_IRQ_SOFTWARE_M    {1'b1, 31'd3}
`define CAUSE_IRQ_TIMER_M       {1'b1, 31'd7}

`define CAUSE_EXCEP_ECALL_M     {1'b0, 31'd11}
`define CAUSE_EXCEP_EBREAK_M    {1'b0, 31'd3}

`define MIE_MTIE_BIT            7
`define MIE_MEIE_BIT            11
`define MIE_MSIE_BIT            3



module exception (

    input wire clk,
    input wire rst_n,

    input wire inst_valid_i,
    input wire inst_ecall_i,                    // ecall指令
    input wire inst_ebreak_i,                   // ebreak指令
    input wire inst_mret_i,                     // mret指令
    input wire inst_dret_i,                     // dret指令
    input wire[31:0] inst_addr_i,               // 指令地址

    input wire[31:0] mtvec_i,                   // mtvec寄存器
    input wire[31:0] mepc_i,                    // mepc寄存器
    input wire[31:0] mstatus_i,                 // mstatus寄存器
    input wire[31:0] mie_i,                     // mie寄存器
    input wire[31:0] dpc_i,                     // dpc寄存器
    input wire[31:0] dcsr_i,                    // dcsr寄存器

    input wire irq_software_i,
    input wire irq_timer_i,
    input wire irq_external_i,
    input wire[14:0] irq_fast_i,

    input wire[31:0] debug_halt_addr_i,
    input wire debug_req_i,

    output wire csr_we_o,                       // 写CSR寄存器标志
    output wire[31:0] csr_waddr_o,              // 写CSR寄存器地址
    output wire[31:0] csr_wdata_o,              // 写CSR寄存器数据

    output wire stall_flag_o,                   // 流水线暂停标志
    output wire[31:0] int_addr_o,               // 中断入口地址
    output wire int_assert_o                    // 中断标志

    );


    localparam ILLEGAL_INSTR_OFFSET         = 0;
    localparam INSTR_ADDR_MISA_OFFSET       = 4;
    localparam ECALL_OFFSET                 = 8;
    localparam EBREAK_OFFSET                = 12;
    localparam LOAD_MISA_OFFSET             = 16;
    localparam STORE_MISA_OFFSET            = 20;
    localparam RESERVED1_EXCEPTION_OFFSET   = 24;
    localparam RESERVED2_EXCEPTION_OFFSET   = 28;

    localparam EXTERNAL_INT_OFFSET          = 32;
    localparam SOFTWARE_INT_OFFSET          = 36;
    localparam TIMER_INT_OFFSET             = 40;
    localparam FAST_INT_OFFSET              = 44;


    localparam S_IDLE       = 3'b001;
    localparam S_W_MEPC     = 3'b010;
    localparam S_ASSERT     = 3'b100;


    reg debug_mode_d, debug_mode_q;
    reg[2:0] state_d, state_q;
    reg[31:0] assert_addr_d, assert_addr_q;
    reg[31:0] return_addr_d, return_addr_q;
    reg csr_we;
    reg[31:0] csr_waddr;
    reg[31:0] csr_wdata;

    wire global_int_en;

    assign global_int_en = mstatus_i[3];

    reg[3:0] fast_irq_id;
    wire fast_irq_req;

    always @ (*) begin
        if      (irq_fast_i[ 0]) fast_irq_id = 4'd0;
        else if (irq_fast_i[ 1]) fast_irq_id = 4'd1;
        else if (irq_fast_i[ 2]) fast_irq_id = 4'd2;
        else if (irq_fast_i[ 3]) fast_irq_id = 4'd3;
        else if (irq_fast_i[ 4]) fast_irq_id = 4'd4;
        else if (irq_fast_i[ 5]) fast_irq_id = 4'd5;
        else if (irq_fast_i[ 6]) fast_irq_id = 4'd6;
        else if (irq_fast_i[ 7]) fast_irq_id = 4'd7;
        else if (irq_fast_i[ 8]) fast_irq_id = 4'd8;
        else if (irq_fast_i[ 9]) fast_irq_id = 4'd9;
        else if (irq_fast_i[10]) fast_irq_id = 4'd10;
        else if (irq_fast_i[11]) fast_irq_id = 4'd11;
        else if (irq_fast_i[12]) fast_irq_id = 4'd12;
        else if (irq_fast_i[13]) fast_irq_id = 4'd13;
        else                     fast_irq_id = 4'd14;
    end

    assign fast_irq_req = |irq_fast_i;

    reg interrupt_req_tmp;
    reg[31:0] interrupt_cause;
    reg[31:0] interrupt_offset;
    wire interrupt_req = inst_valid_i & interrupt_req_tmp;

    always @ (*) begin
        if (fast_irq_req) begin
            interrupt_req_tmp = 1'b1;
            interrupt_cause = {1'b1, {26{1'b0}}, 1'b1, fast_irq_id};
            interrupt_offset = {fast_irq_id, 2'b0} + FAST_INT_OFFSET;
        end else if (irq_external_i & mie_i[`MIE_MEIE_BIT]) begin
            interrupt_req_tmp = 1'b1;
            interrupt_cause = `CAUSE_IRQ_EXTERNAL_M;
            interrupt_offset = EXTERNAL_INT_OFFSET;
        end else if (irq_software_i & mie_i[`MIE_MSIE_BIT]) begin
            interrupt_req_tmp = 1'b1;
            interrupt_cause = `CAUSE_IRQ_SOFTWARE_M;
            interrupt_offset = SOFTWARE_INT_OFFSET;
        end else if (irq_timer_i & mie_i[`MIE_MTIE_BIT]) begin
            interrupt_req_tmp = 1'b1;
            interrupt_cause = `CAUSE_IRQ_TIMER_M;
            interrupt_offset = TIMER_INT_OFFSET;
        end else begin
            interrupt_req_tmp = 1'b0;
            interrupt_cause = 32'h0;
            interrupt_offset = 32'h0;
        end
    end

    reg exception_req;
    reg[31:0] exception_cause;
    reg[31:0] exception_offset;

    always @ (*) begin
        if (inst_ecall_i) begin
            exception_req = 1'b1;
            exception_cause = `CAUSE_EXCEP_ECALL_M;
            exception_offset = ECALL_OFFSET;
        end else if (inst_ebreak_i & (!dcsr_i[15]) & (~debug_mode_q)) begin
            exception_req = 1'b1;
            exception_cause = `CAUSE_EXCEP_EBREAK_M;
            exception_offset = EBREAK_OFFSET;
        end else begin
            exception_req = 1'b0;
            exception_cause = 32'h0;
            exception_offset = 32'h0;
        end
    end

    wire int_or_exception_req;
    wire[31:0] int_or_exception_cause;
    wire[31:0] int_or_exception_offset;

    assign int_or_exception_req     = (interrupt_req & global_int_en) | exception_req;
    assign int_or_exception_cause   = exception_req ? exception_cause  : interrupt_cause;
    assign int_or_exception_offset  = exception_req ? exception_offset : interrupt_offset;

    wire debug_mode_req = ((~debug_mode_q) & debug_req_i & inst_valid_i) |
                          (inst_ebreak_i & dcsr_i[15]) |
                          (inst_ebreak_i & debug_mode_q);

    assign stall_flag_o = ((state_q != S_IDLE) & (state_q != S_ASSERT)) |
                          (interrupt_req & global_int_en) | exception_req |
                          debug_mode_req |
                          inst_mret_i |
                          inst_dret_i;

    always @ (*) begin
        state_d = state_q;
        assert_addr_d = assert_addr_q;
        debug_mode_d = debug_mode_q;
        return_addr_d = return_addr_q;
        csr_we = 1'b0;
        csr_waddr = 32'h0;
        csr_wdata = 32'h0;

        case (state_q)
            S_IDLE: begin
                if (int_or_exception_req) begin
                    csr_we = 1'b1;
                    csr_waddr = {20'h0, `CSR_MCAUSE};
                    csr_wdata = int_or_exception_cause;
                    assert_addr_d = mtvec_i + int_or_exception_offset;
                    return_addr_d = inst_addr_i;
                    state_d = S_W_MEPC;
                end else if (debug_mode_req) begin
                    debug_mode_d = 1'b1;
                    if (!inst_ebreak_i) begin
                        csr_we = 1'b1;
                        csr_waddr = {20'h0, `CSR_DPC};
                        csr_wdata = inst_addr_i;
                    end
                    assert_addr_d = debug_halt_addr_i;
                    state_d = S_ASSERT;
                end else if (inst_mret_i) begin
                    assert_addr_d = mepc_i;
                    state_d = S_ASSERT;
                end else if (inst_dret_i) begin
                    assert_addr_d = dpc_i;
                    state_d = S_ASSERT;
                    debug_mode_d = 1'b0;
                end
            end

            S_W_MEPC: begin
                csr_we = 1'b1;
                csr_waddr = {20'h0, `CSR_MEPC};
                csr_wdata = return_addr_q;
                state_d = S_ASSERT;
            end

            S_ASSERT: begin
                csr_we = 1'b0;
                state_d = S_IDLE;
            end

            default:;

        endcase
    end

    assign csr_we_o = csr_we;
    assign csr_waddr_o = csr_waddr;
    assign csr_wdata_o = csr_wdata;

    assign int_assert_o = (state_q == S_ASSERT);
    assign int_addr_o   = assert_addr_q;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
            assert_addr_q <= 32'h0;
            debug_mode_q <= 1'b0;
            return_addr_q <= 32'h0;
        end else begin
            state_q <= state_d;
            assert_addr_q <= assert_addr_d;
            debug_mode_q <= debug_mode_d;
            return_addr_q <= return_addr_d;
        end
    end

endmodule
