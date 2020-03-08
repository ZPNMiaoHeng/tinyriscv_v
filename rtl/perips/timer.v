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


// 32 bits count up timer module
module timer (

    input wire clk,
    input wire rst,

    input wire[31:0] wdata,
    input wire[31:0] waddr,
    input wire[31:0] raddr,
    input wire we,

    output reg[31:0] rdata,
    output wire int_sig

    );

    // timer expired value
    // addr: 0x10000008
    reg[31:0] timer_value;

    // timer current count, read only
    // addr: 0x10000004
    reg[31:0] timer_count;

    // [0]: timer enable
    // [1]: timer int enable
    // [2]: timer int pending, write 1 to clear it
    // addr: 0x10000000
    reg[31:0] timer_ctrl;


    assign int_sig = ((timer_ctrl[0] == 1'b1) && (timer_ctrl[1] == 1'b1) && (timer_ctrl[2] == 1'b1)) ? 1'b1 : 1'b0;

    // write timer regs
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            timer_count <= 32'h0;
            timer_value <= 32'h0;
            timer_ctrl <= 32'h0;
        end else begin
            if (timer_ctrl[0] == 1'b1) begin
                timer_count <= timer_count + 1'b1;
                if (timer_count == timer_value) begin
                    timer_ctrl[2] <= 1'b1;
                    timer_count <= 32'h0;
                end
            end
            if (we == 1'b1) begin
                if (waddr == 32'h10000008) begin
                    timer_value <= wdata;
                end else if (waddr == 32'h10000000) begin
                    if (wdata[2] == 1'b0) begin
                        timer_ctrl <= wdata;
                    // write 1 to clear pending
                    end else begin
                        timer_ctrl <= {wdata[31:3], 1'b0, wdata[1:0]};
                    end
                end
            end
        end
    end

    // read timer regs
    always @ (*) begin
        if (rst == 1'b0) begin
            rdata <= 32'h0;
        end else begin
            if (raddr == 32'h10000008) begin
                rdata <= timer_value;
            end else if (raddr == 32'h10000000) begin
                rdata <= timer_ctrl;
            end else if (raddr == 32'h10000004) begin
                rdata <= timer_count;
            end else begin
                rdata <= 32'h0;
            end
        end
    end

endmodule
