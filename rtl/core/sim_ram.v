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

// simulation ram module
module sim_ram (

    input wire clk,
    input wire rst,

    input wire we_i,                     // write enable
    input wire[`SramAddrBus] waddr_i,    // write addr
    input wire[`SramBus] wdata_i,        // write data

    input wire dm_we_i,                  // dm write enable
    input wire[`SramAddrBus] dm_addr_i,  // dm write or read addr
    input wire[`SramBus] dm_wdata_i,     // dm write data

    output reg[`SramBus] dm_rdata_o,     // dm read data

    input wire pc_re_i,                  // pc read enable
    input wire[`SramAddrBus] pc_raddr_i, // pc read addr
    output reg[`SramBus] pc_rdata_o,     // pc read data

    input wire ex_re_i,                  // ex read enable
    input wire[`SramAddrBus] ex_raddr_i, // ex read addr
    output reg[`SramBus] ex_rdata_o      // ex read data

    );

    reg[`SramBus] ram[0:`SramMemNum - 1];
    reg[`SramBus] rom[0:`SramMemNum - 1];

    // ex write mem
    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if (we_i == `WriteEnable) begin
                ram[waddr_i[13:2]] <= wdata_i;
            end
        end
    end

    // dm write rom
    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if (dm_we_i == `WriteEnable) begin
                rom[dm_addr_i[13:2]] <= dm_wdata_i;
            end
        end
    end

    // pc read inst
    always @ (*) begin
        if (rst == `RstEnable) begin
            pc_rdata_o <= `ZeroWord;
        end else if ((pc_raddr_i == waddr_i) && (pc_re_i == `ReadEnable)) begin
            pc_rdata_o <= wdata_i;
        end else if (pc_re_i == `ReadEnable) begin
            if (pc_raddr_i < (`SramMemNum - 1)) begin
                pc_rdata_o <= rom[pc_raddr_i >> 2];
            end else begin
                pc_rdata_o <= `INST_NOP;
            end
        end else begin
            pc_rdata_o <= `INST_NOP;
        end
    end

    // ex read mem
    always @ (*) begin
        if (rst == `RstEnable) begin
            ex_rdata_o <= `ZeroWord;
        end else if (ex_re_i == `ReadEnable) begin
            ex_rdata_o <= ram[ex_raddr_i[13:2]];
        end else begin
            ex_rdata_o <= `ZeroWord;
        end
    end

    // dm read rom
    always @ (*) begin
        if (rst == `RstEnable) begin
            dm_rdata_o <= `ZeroWord;
        end else begin
            dm_rdata_o <= rom[dm_addr_i[13:2]];
        end
    end

endmodule
