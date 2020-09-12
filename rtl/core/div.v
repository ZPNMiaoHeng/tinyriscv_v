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
    localparam STATE_IDLE   = 5'b00001;
    localparam STATE_START  = 5'b00010;
    localparam STATE_CALC   = 5'b00100;
    localparam STATE_INVERT = 5'b01000;
    localparam STATE_END    = 5'b10000;

    reg[4:0] state;
    reg[4:0] next_state;
    reg[`RegBus] dividend_r;
    reg[`RegBus] divisor_r;
    reg[2:0] op_r;
    reg[31:0] count;
    reg[`RegBus] div_result;
    reg[`RegBus] div_remain;
    reg[`RegBus] minuend;
    reg invert_result;

    wire[31:0] dividend_invert = (-dividend_r);
    wire[31:0] divisor_invert = (-divisor_r);
    wire[31:0] minuend_sub_res = (minuend - divisor_r);
    wire minuend_ge_divisor = (minuend >= divisor_r);

    wire op_div = (op_r == `INST_DIV);
    wire op_divu = (op_r == `INST_DIVU);
    wire op_rem = (op_r == `INST_REM);
    wire op_remu = (op_r == `INST_REMU);
    wire is_divisor_zero = (divisor_r == `ZeroWord);


    // 当前状态切换
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 下一个状态切换
    always @ (*) begin
        if (start_i == `DivStart) begin
            case (state)
                STATE_IDLE: begin
                    next_state = STATE_START;
                end
                STATE_START: begin
                    if (is_divisor_zero) begin
                        next_state = STATE_IDLE;
                    end else begin
                        next_state = STATE_CALC;
                    end
                end
                STATE_CALC: begin
                    if (count == `ZeroWord) begin
                        next_state = STATE_INVERT;
                    end else begin
                        next_state = STATE_CALC;
                    end
                end
                STATE_INVERT: begin
                    next_state = STATE_END;
                end
                STATE_END: begin
                    next_state = STATE_IDLE;
                end
                default: begin
                    next_state = STATE_IDLE;
                end
            endcase
        end else begin
            next_state = STATE_IDLE;
        end
    end

    // 具体操作
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            op_r <= 3'h0;
        end else begin
            if (start_i == `DivStart && state == STATE_IDLE) begin
                op_r <= op_i;
            end
        end
    end

    // 运算完后要写的寄存器地址
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            reg_waddr_o <= `ZeroReg;
        end else begin
            if (start_i == `DivStart && state == STATE_IDLE) begin
                reg_waddr_o <= reg_waddr_i;
            end
        end
    end

    // 被除数
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            dividend_r <= `ZeroWord;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_i == `DivStart) begin
                        dividend_r <= dividend_i;
                    end
                end
                STATE_START: begin
                    // 除数不为0
                    if (!is_divisor_zero) begin
                        // DIV和REM这两条指令是有符号数运算
                        if ((op_div | op_rem) & dividend_r[31]) begin
                            // 被除数求补码
                            dividend_r <= dividend_invert;
                        end
                    end
                end
                STATE_CALC: begin
                    if (|count) begin
                        dividend_r <= {dividend_r[30:0], 1'b0};
                    end
                end
            endcase
        end
    end

    // 除数
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            divisor_r <= `ZeroWord;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_i == `DivStart) begin
                        divisor_r <= divisor_i;
                    end
                end
                STATE_START: begin
                    // 除数不为0
                    if (!is_divisor_zero) begin
                        // DIV和REM这两条指令是有符号数运算
                        if ((op_div | op_rem) & divisor_r[31]) begin
                            // 除数求补码
                            divisor_r <= divisor_invert;
                        end
                    end
                end
            endcase
        end
    end

    // 运算结束
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ready_o <= `DivResultNotReady;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready_o <= `DivResultNotReady;
                end
                STATE_START: begin
                    // 除数为0
                    if (is_divisor_zero) begin
                        ready_o <= `DivResultReady;
                    end
                end
                STATE_END: begin
                    ready_o <= `DivResultReady;
                end
            endcase
        end
    end

    // 最终结果
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            result_o <= `ZeroWord;
        end else begin
            case (state)
                STATE_IDLE: begin
                    result_o <= `ZeroWord;
                end
                STATE_START: begin
                    // 除数为0
                    if (is_divisor_zero) begin
                        if (op_div | op_divu) begin
                            result_o <= 32'hffffffff;
                        end else begin
                            result_o <= dividend_r;
                        end
                    end
                end
                STATE_END: begin
                    if (op_div | op_divu) begin
                        result_o <= div_result;
                    end else begin
                        result_o <= div_remain;
                    end
                end
            endcase
        end
    end

    // bit计数
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            count <= `ZeroWord;
        end else begin
            case (state)
                STATE_START: begin
                    // 除数不为0
                    if (!is_divisor_zero) begin
                        count <= 32'h80000000;
                    end
                end
                STATE_CALC: begin
                    if (|count) begin
                        count <= {1'b0, count[31:1]};
                    end
                end
            endcase
        end
    end

    // 结果是否取补码
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            invert_result <= 1'b0;
        end else begin
            case (state)
                STATE_START: begin
                    // 除数不为0
                    if (!is_divisor_zero) begin
                        // 运算结束后是否要对结果取补码
                        if (((op_div) && (dividend_r[31] ^ divisor_r[31] == 1'b1))
                            || ((op_rem) && (dividend_r[31] == 1'b1))) begin
                            invert_result <= 1'b1;
                        end else begin
                            invert_result <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end

    // 被减数
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            minuend <= `ZeroWord;
        end else begin
            case (state)
                STATE_START: begin
                    // 除数不为0
                    if (!is_divisor_zero) begin
                        // DIV和REM这两条指令是有符号数运算
                        if ((op_div | op_rem) & dividend_r[31]) begin
                            minuend <= dividend_invert[31];
                        end else begin
                            minuend <= dividend_r[31];
                        end
                    end
                end
                STATE_CALC: begin
                    if (|count) begin
                        if (minuend_ge_divisor) begin
                            minuend <= {minuend_sub_res[30:0], dividend_r[31]};
                        end else begin
                            minuend <= {minuend[30:0], dividend_r[31]};
                        end
                    end
                end
            endcase
        end
    end

    // 商
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            div_result <= `ZeroWord;
        end else begin
            case (state)
                STATE_CALC: begin
                    div_result <= {div_result[30:0], minuend_ge_divisor};
                end
                STATE_INVERT: begin
                    if (invert_result == 1'b1) begin
                        div_result <= -div_result;
                    end
                end
            endcase
        end
    end

    // 余数
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            div_remain <= `ZeroWord;
        end else begin
            case (state)
                STATE_CALC: begin
                    if (count == `ZeroWord) begin
                        if (minuend_ge_divisor) begin
                            div_remain <= minuend_sub_res;
                        end else begin
                            div_remain <= minuend;
                        end
                    end
                end
                STATE_INVERT: begin
                    if (invert_result == 1'b1) begin
                        div_remain <= -div_remain;
                    end
                end
            endcase
        end
    end

    // busy信号要比ready信号提前一个时钟撤销
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            busy_o <= `False;
        end else begin
            case (state)
                STATE_CALC, STATE_INVERT: begin
                    busy_o <= `True;
                end
                default: begin
                    busy_o <= `False;
                end
            endcase
        end
    end

endmodule
