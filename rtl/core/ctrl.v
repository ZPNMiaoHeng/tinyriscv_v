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

module ctrl(

    input wire rst,

    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    input wire hold_flag_ex_i,
    input wire hold_flag_rib_i,
    input wire jtag_halt_flag_i,

    output reg[`Hold_Flag_Bus] hold_flag_o,
    output reg jump_flag_o,
    output reg[`InstAddrBus] jump_addr_o

    );


    always @ (*) begin
        if (rst == `RstEnable) begin
            hold_flag_o <= `Hold_None;
            jump_flag_o <= `JumpDisable;
            jump_addr_o <= `ZeroWord;
        end else begin
            jump_addr_o <= jump_addr_i;
            jump_flag_o <= jump_flag_i;
            hold_flag_o <= `Hold_None;
            if (jump_flag_i == `JumpEnable || hold_flag_ex_i == `HoldEnable) begin
                hold_flag_o <= `Hold_Id;
            end else if (hold_flag_rib_i == `HoldEnable) begin
                hold_flag_o <= `Hold_Pc;
            end else if (jtag_halt_flag_i == `HoldEnable) begin
                hold_flag_o <= `Hold_Id;
            end else begin
                hold_flag_o <= `Hold_None;
            end
        end
    end

endmodule
