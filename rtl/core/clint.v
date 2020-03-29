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


// core local interruptor module
module clint(

    input wire clk,
    input wire rst,

    input wire we_i,                  // write enable
    input wire[`RegAddrBus] addr_i,   // addr
    input wire[`RegBus] data_i,       // write data

    output reg[`RegBus] data_o        // read data

    );

    reg[`RegBus] regs[0:`RegNum - 1];


    // write reg
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            regs[0] <= `ZeroWord;
        end else begin
            if (we_i == `WriteEnable) begin
                regs[addr_i] <= data_i;
            end
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
            data_o <= regs[addr_i];
        end
    end

endmodule
