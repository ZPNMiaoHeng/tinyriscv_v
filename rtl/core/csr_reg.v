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

// csr reg module
module csr_reg(

    input wire clk,
    input wire rst,

    input wire we_i,
    input wire[`MemAddrBus] raddr_i,
    input wire[`MemAddrBus] waddr_i,
    input wire[`RegBus] data_i,

    output reg[`RegBus] data_o

    );


    localparam CSR_CYCLE  = 12'hc00;
    localparam CSR_CYCLEH = 12'hc80;

    reg[63:0] cycle;


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            cycle <= 64'h0;
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    // read reg
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
            case (raddr_i[11:0])
                CSR_CYCLE: begin
                    data_o <= cycle[31:0];
                end
                CSR_CYCLEH: begin
                    data_o <= cycle[63:32];
                end
                default: begin
                    data_o <= `ZeroWord;
                end
            endcase
        end
    end

endmodule
