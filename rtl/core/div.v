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

// 除法模块
// 试商法实现32位整数除法
// 每次除法运算需要33个时钟周期才能完成
module div(

    input wire clk,
    input wire rst,

    // from ex
    input wire[`RegBus] dividend_i,      // 被除数
    input wire[`RegBus] divisor_i,       // 除数
    input wire start_i,                  // 开始信号，运算期间这个信号需要一直保持有效
    input wire[2:0] op_i,                // 具体是哪一条指令
    input wire[`RegAddrBus] reg_waddr_i, // 运算结束后需要写的寄存器

    // to ex
    output reg[`RegBus] result_o,        // 除法结果
    output reg ready_o,                  // 运算结束信号
    output reg busy_o,                   // 正在运算信号
    output reg[`RegAddrBus] reg_waddr_o  // 运算结束后需要写的寄存器

    );

    // 状态定义
    localparam STATE_IDLE   = 4'b0001;
    localparam STATE_START  = 4'b0010;
    localparam STATE_INVERT = 4'b0100;
    localparam STATE_END    = 4'b1000;

    reg[`RegBus] dividend_temp;
    reg[`RegBus] divisor_temp;
    reg[3:0] state;
    reg[31:0] count;
    reg[`RegBus] div_result;
    reg[`RegBus] div_remain;
    reg[`RegBus] minuend;
    reg invert_result;
    reg inst_div;
    reg inst_divu;

    wire[31:0] dividend_invert = -dividend_i;
    wire[31:0] divisor_invert = -divisor_i;
    wire[31:0] minuend_sub_res = minuend - divisor_temp;
    wire minuend_ge_divisor = minuend >= divisor_temp;

    wire op_div = (op_i == `INST_DIV);
    wire op_divu = (op_i == `INST_DIVU);
    wire op_rem = (op_i == `INST_REM);
    wire op_remu = (op_i == `INST_REMU);

    // 状态机实现
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= STATE_IDLE;
            ready_o <= `DivResultNotReady;
            result_o <= `ZeroWord;
            div_result <= `ZeroWord;
            div_remain <= `ZeroWord;
            reg_waddr_o <= `ZeroWord;
            dividend_temp <= `ZeroWord;
            divisor_temp <= `ZeroWord;
            minuend <= `ZeroWord;
            count <= `ZeroWord;
            invert_result <= 1'b0;
            busy_o <= `False;
            inst_div <= 1'b0;
            inst_divu <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    busy_o <= `False;
                    if (start_i == `DivStart) begin
                        reg_waddr_o <= reg_waddr_i;
                        inst_div <= op_div;
                        inst_divu <= op_divu;

                        // 除数为0
                        if (divisor_i == `ZeroWord) begin
                            ready_o <= `DivResultReady;
                            if (op_div | op_divu) begin
                                result_o <= 32'hffffffff;
                            end else begin
                                result_o <= dividend_i;
                            end
                        // 除数不为0
                        end else begin
                            count <= 32'h80000000;
                            state <= STATE_START;

                            // DIV和REM这两条指令是有符号数运算
                            if ((op_div) || (op_rem)) begin
                                // 被除数求补码
                                if (dividend_i[31] == 1'b1) begin
                                    dividend_temp <= dividend_invert;
                                    minuend <= dividend_invert[31];
                                end else begin
                                    dividend_temp <= dividend_i;
                                    minuend <= dividend_i[31];
                                end
                                // 除数求补码
                                if (divisor_i[31] == 1'b1) begin
                                    divisor_temp <= divisor_invert;
                                end else begin
                                    divisor_temp <= divisor_i;
                                end
                            end else begin
                                dividend_temp <= dividend_i;
                                minuend <= dividend_i[31];
                                divisor_temp <= divisor_i;
                            end

                            // 运算结束后是否要对结果取补码
                            if (((op_div) && (dividend_i[31] ^ divisor_i[31] == 1'b1))
                                || ((op_rem) && (dividend_i[31] == 1'b1))) begin
                                invert_result <= 1'b1;
                            end else begin
                                invert_result <= 1'b0;
                            end
                        end
                    end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= `ZeroWord;
                    end
                end

                STATE_START: begin
                    busy_o <= `True;
                    if (start_i == `DivStart) begin
                        div_result <= {div_result[30:0], minuend_ge_divisor};
                        if (|count) begin
                            if (minuend_ge_divisor) begin
                                minuend <= {minuend_sub_res[30:0], dividend_temp[31]};
                            end else begin
                                minuend <= {minuend[30:0], dividend_temp[31]};
                            end
                            count <= {1'b0, count[31:1]};
                            dividend_temp <= {dividend_temp[30:0], 1'b0};
                        end else begin
                            state <= STATE_INVERT;
                            if (minuend_ge_divisor) begin
                                div_remain <= minuend_sub_res;
                            end else begin
                                div_remain <= minuend;
                            end
                        end
                    end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= `ZeroWord;
                        state <= STATE_IDLE;
                    end
                end

                STATE_INVERT: begin
                    busy_o <= `True;
                    if (start_i == `DivStart) begin
                        if (invert_result == 1'b1) begin
                            div_result <= -div_result;
                            div_remain <= -div_remain;
                        end
                        state <= STATE_END;
                    end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= `ZeroWord;
                        state <= STATE_IDLE;
                    end
                end

                STATE_END: begin
                    busy_o <= `False;
                    if (start_i == `DivStart) begin
                        ready_o <= `DivResultReady;
                        if (inst_div | inst_divu) begin
                            result_o <= div_result;
                        end else begin
                            result_o <= div_remain;
                        end
                        state <= STATE_IDLE;
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                    end
                end

            endcase
        end
    end

endmodule
