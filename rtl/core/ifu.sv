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

// 取指模块
module ifu(

    input wire clk,
    input wire rst_n,

    input wire flush_i,                        // 跳转标志
    input wire[31:0] flush_addr_i,             // 跳转地址
    input wire[`STALL_WIDTH-1:0] stall_i,      // 流水线暂停标志
    input wire jtag_halt_i,
    output wire[31:0] inst_o,
    output wire[31:0] pc_o,
    output wire inst_valid_o,

    output wire instr_req_o,
    input wire instr_gnt_i,
    input wire instr_rvalid_i,
    output wire[31:0] instr_addr_o,
    input wire[31:0] instr_rdata_i,
    input wire instr_err_i

    );


    assign instr_req_o = ((~rst_n) | stall_i[`STALL_PC])? 1'b0: 1'b1;


    localparam S_FETCH       = 2'b01;
    localparam S_VALID       = 2'b10;

    reg[1:0] state;
    reg[1:0] next_state;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_FETCH;
        end else begin
            state <= next_state;
        end
    end

    always @ (*) begin
        case (state)
            S_FETCH: begin
                if (instr_gnt_i & (~stall_i[`STALL_PC]) & (~flush_i)) begin
                    next_state = S_VALID;
                end else begin
                    next_state = S_FETCH;
                end
            end

            S_VALID: begin
                if (stall_i[`STALL_PC] | flush_i) begin
                    next_state = S_FETCH;
                end else begin
                    next_state = S_VALID;
                end
            end

            default: begin
                next_state = S_FETCH;
            end
        endcase
    end

    wire inst_valid = (state == S_VALID) & instr_rvalid_i;
    assign inst_valid_o = inst_valid;
    assign inst_o = inst_valid? instr_rdata_i: `INST_NOP;

    wire[31:0] fetch_addr_d;
    reg[31:0] fetch_addr_q;
    wire fetch_addr_en = instr_req_o & instr_gnt_i & (~stall_i[`STALL_PC]);

    assign fetch_addr_d = flush_i? flush_addr_i:
                          stall_i[`STALL_PC]? fetch_addr_q:
                          inst_valid? fetch_addr_q + 4'h4:
                          fetch_addr_q;

    always @ (posedge clk or negedge rst_n) begin
        // 复位
        if (!rst_n) begin
            fetch_addr_q <= `CPU_RESET_ADDR;
        end else if (fetch_addr_en) begin
            fetch_addr_q <= fetch_addr_d;
        end
    end

    assign instr_addr_o = {fetch_addr_d[31:2], 2'b00};
    assign pc_o = fetch_addr_q;








/*
    assign instr_req_o = (~rst_n)? 1'b0: 1'b1;

    wire[31:0] fetch_addr_d;
    reg[31:0] fetch_addr_q;
    wire fetch_addr_en = instr_req_o & instr_gnt_i & (~stall_i[`STALL_PC]);

    assign fetch_addr_d = flush_i? flush_addr_i:
                          instr_rvalid_i? fetch_addr_q + 4'h4:
                          fetch_addr_q;

    always @ (posedge clk or negedge rst_n) begin
        // 复位
        if (!rst_n) begin
            fetch_addr_q <= `CPU_RESET_ADDR;
        end else if (fetch_addr_en) begin
            fetch_addr_q <= fetch_addr_d;
        end
    end

    assign instr_addr_o = {fetch_addr_d[31:2], 2'b00};
    assign pc_o = fetch_addr_q;

    wire inst_valid = instr_rvalid_i & (~flush_i);
    assign inst_valid_o = inst_valid;
    assign inst_o = inst_valid? instr_rdata_i: `INST_NOP;
*/


/*
    assign req_valid_o = (~rst_n)? 1'b0:
                         (flush_i)? 1'b0:
                         stall_i[`STALL_PC]? 1'b0:
                         jtag_halt_i? 1'b0:
                         1'b1;
    assign rsp_ready_o = (~rst_n)? 1'b0: 1'b1;

    wire ifu_req_hsked = (req_valid_o & req_ready_i);
    wire ifu_rsp_hsked = (rsp_valid_i & rsp_ready_o);

    // 在执行多周期指令或者请求不到总线时需要暂停
    wire stall = stall_i[`STALL_PC] | (~ifu_req_hsked);

    reg[31:0] pc;
    reg[31:0] pc_prev;

    always @ (posedge clk or negedge rst_n) begin
        // 复位
        if (!rst_n) begin
            pc <= `CPU_RESET_ADDR;
            pc_prev <= 32'h0;
        // 冲刷
        end else if (flush_i) begin
            pc <= flush_addr_i;
        // 暂停，取上一条指令
        end else if (stall) begin
            pc <= pc_prev;
        // 取下一条指令
        end else begin
            pc <= pc + 32'h4;
            pc_prev <= pc;
        end
    end

    wire[31:0] pc_r;
    // 将PC打一拍
    wire pc_ena = (~stall);
    gen_en_dff #(32) pc_dff(clk, rst_n, pc_ena, pc, pc_r);

    reg req_hasked_r;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_hasked_r <= 1'b1;
        end else begin
            req_hasked_r <= ifu_req_hsked;
        end
    end

    wire req_switched = ifu_req_hsked & (~req_hasked_r);

    reg rsp_hasked_r;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rsp_hasked_r <= 1'b1;
        end else begin
            rsp_hasked_r <= ifu_rsp_hsked;
        end
    end

    wire rsp_switched = ifu_rsp_hsked & (~rsp_hasked_r);

    // 总线切换有两种情况：
    // 1.访存地址位于指令存储器：当访存完成后，ifu_req_hsked和ifu_rsp_hsked信号会同时从0变为1
    // 2.访存地址不位于指令存储器：当访存完成后，ifu_req_hsked先从0变为1和ifu_rsp_hsked后从0变为1
    // 只有第2种情况下取出来的指令是有效的，这里要把这两种情况识别出来
    wire bus_switched = req_switched & rsp_switched;

    // 取指地址
    assign ibus_addr_o = pc;
    assign pc_o = pc_r;
    wire inst_valid = ifu_rsp_hsked & (~flush_i) & (~bus_switched);
    assign inst_valid_o = inst_valid;
    assign inst_o = inst_valid? ibus_data_i: `INST_NOP;

    assign ibus_sel_o = 4'b1111;
    assign ibus_we_o = 1'b0;
    assign ibus_data_o = 32'h0;
*/

endmodule
