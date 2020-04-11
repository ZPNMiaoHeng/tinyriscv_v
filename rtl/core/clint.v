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

    input wire[`INT_BUS] int_flag_i,
    input wire[`InstBus] inst_i,
    input wire[`InstAddrBus] inst_addr_i,
    input wire[`Hold_Flag_Bus] hold_flag_i,
    input wire[`RegBus] data_i,

    output reg we_o,
    output reg[`MemAddrBus] waddr_o,
    output reg[`MemAddrBus] raddr_o,
    output reg[`RegBus] data_o,

    output reg[`InstAddrBus] int_addr_o,
    output reg int_assert_o

    );


    reg in_int_context;
    reg[`InstAddrBus] int_return_addr;


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            in_int_context <= `False;
            int_return_addr <= `ZeroWord;
            int_assert_o <= `INT_DEASSERT;
            int_addr_o <= `ZeroWord;
        end else begin
            if (int_flag_i != `INT_NONE && in_int_context == `False) begin
                int_assert_o <= `INT_ASSERT;
                in_int_context <= `True;
                int_return_addr <= inst_addr_i;
                int_addr_o <= data_i;
            end else if (inst_i == `INST_MRET) begin
                in_int_context <= `False;
                int_assert_o <= `INT_ASSERT;
                int_addr_o <= int_return_addr;
            end else begin
                int_assert_o <= `INT_DEASSERT;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            raddr_o <= `ZeroWord;
        end else begin
            raddr_o <= {20'h0, `CSR_MTVEC};
        end
    end

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            we_o <= `WriteDisable;
            waddr_o <= `ZeroWord;
            data_o <= `ZeroWord;
        end else begin
            we_o <= `WriteEnable;
            waddr_o <= {20'h0, `CSR_MCAUSE};
            data_o <= {24'h0, int_flag_i};
        end
    end

endmodule
