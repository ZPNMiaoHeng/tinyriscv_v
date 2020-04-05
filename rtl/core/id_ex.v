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

// identification to execute module
module id_ex(

    input wire clk,
	input wire rst,

    input wire[`InstBus] inst_i,            // inst content
    input wire[`InstAddrBus] inst_addr_i,   // inst addr
    input wire reg_we_i,
    input wire[`RegAddrBus] reg_waddr_i,
    input wire[`RegBus] reg1_rdata_i,       // reg1 read data
    input wire[`RegBus] reg2_rdata_i,       // reg2 read data
    input wire csr_we_i,
    input wire[`MemAddrBus] csr_waddr_i,
    input wire[`RegBus] csr_rdata_i,

    input wire[`Hold_Flag_Bus] hold_flag_i,

    output reg[`InstBus] inst_o,            // inst content
    output reg[`InstAddrBus] inst_addr_o,   // inst addr
    output reg reg_we_o,
    output reg[`RegAddrBus] reg_waddr_o,
    output reg[`RegBus] reg1_rdata_o,       // reg1 read data
    output reg[`RegBus] reg2_rdata_o,       // reg2 read data
    output reg csr_we_o,
    output reg[`MemAddrBus] csr_waddr_o,
    output reg[`RegBus] csr_rdata_o

    );

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            inst_o <= `INST_NOP;
            inst_addr_o <= `ZeroWord;
            reg_we_o <= `WriteDisable;
            reg_waddr_o <= `ZeroWord;
            reg1_rdata_o <= `ZeroWord;
            reg2_rdata_o <= `ZeroWord;
            csr_we_o <= `WriteDisable;
            csr_waddr_o <= `ZeroWord;
            csr_rdata_o <= `ZeroWord;
        end else begin
            if (hold_flag_i >= `Hold_Id) begin
                inst_o <= `INST_NOP;
                inst_addr_o <= `ZeroWord;
                reg_we_o <= `WriteDisable;
                reg_waddr_o <= `ZeroWord;
                reg1_rdata_o <= `ZeroWord;
                reg2_rdata_o <= `ZeroWord;
                csr_we_o <= `WriteDisable;
                csr_waddr_o <= `ZeroWord;
                csr_rdata_o <= `ZeroWord;
            end else begin
                inst_o <= inst_i;
                inst_addr_o <= inst_addr_i;
                reg_we_o <= reg_we_i;
                reg_waddr_o <= reg_waddr_i;
                reg1_rdata_o <= reg1_rdata_i;
                reg2_rdata_o <= reg2_rdata_i;
                csr_we_o <= csr_we_i;
                csr_waddr_o <= csr_waddr_i;
                csr_rdata_o <= csr_rdata_i;
            end
        end
    end

endmodule
