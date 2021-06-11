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
    wire prdt_taken;
    wire[31:0] prdt_addr;

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
                          prdt_taken? prdt_addr:
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

    bpu u_bpu(
        .clk(clk),
        .rst_n(rst_n),
        .inst_i(instr_rdata_i),
        .inst_valid_i(inst_valid),
        .pc_i(fetch_addr_q),
        .prdt_taken_o(prdt_taken),
        .prdt_addr_o(prdt_addr)
    );

endmodule
