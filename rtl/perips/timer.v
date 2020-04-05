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

`include "defines.v"


// 32 bits count up timer module
module timer(

    input wire clk,
    input wire rst,

    input wire[31:0] data_i,
    input wire[31:0] addr_i,
    input wire we_i,
    input wire req_i,

    output reg[31:0] data_o,
    output wire int_sig_o,
    output reg ack_o

    );

    localparam ctrl_reg = 32'h00;
    localparam count_reg = 32'h04;
    localparam value_reg = 32'h08;

    // [0]: timer enable
    // [1]: timer int enable
    // [2]: timer int pending, write 1 to clear it
    // addr offset: 0x00
    reg[31:0] timer_ctrl;

    // timer current count, read only
    // addr offset: 0x04
    reg[31:0] timer_count;

    // timer expired value
    // addr offset: 0x08
    reg[31:0] timer_value;


    assign int_sig_o = ((timer_ctrl[0] == 1'b1) && (timer_ctrl[1] == 1'b1) && (timer_ctrl[2] == 1'b1)) ? `INT_ASSERT : `INT_DEASSERT;


    // write timer regs
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            timer_count <= `ZeroWord;
            timer_value <= `ZeroWord;
            timer_ctrl <= `ZeroWord;
            ack_o <= `RIB_ACK;
        end else begin
            if (timer_ctrl[0] == 1'b1) begin
                timer_count <= timer_count + 1'b1;
                if (timer_count == timer_value) begin
                    timer_ctrl[2] <= 1'b1;
                    timer_count <= `ZeroWord;
                end
            end
            if (we_i == `WriteEnable) begin
                if (addr_i == value_reg) begin
                    timer_value <= data_i;
                end else if (addr_i == ctrl_reg) begin
                    if (data_i[2] == 1'b0) begin
                        timer_ctrl <= {data_i[31:3], timer_ctrl[2], data_i[1:0]};
                    // write 1 to clear pending
                    end else begin
                        timer_ctrl <= {data_i[31:3], 1'b0, data_i[1:0]};
                    end
                end
            end
        end
    end

    // read timer regs
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
            case (addr_i)
                value_reg: begin
                    data_o <= timer_value;
                end
                ctrl_reg: begin
                    data_o <= timer_ctrl;
                end
                count_reg: begin
                    data_o <= timer_count;
                end
                default: begin
                    data_o <= `ZeroWord;
                end
            endcase
        end
    end

endmodule