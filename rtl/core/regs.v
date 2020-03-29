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

// common reg module
module regs(

    input wire clk,
    input wire rst,

    input wire we_i,                  // reg write enable
    input wire[`RegAddrBus] waddr_i,  // reg write addr
    input wire[`RegBus] wdata_i,      // reg write data

    input wire jtag_we_i,                 // reg write enable
    input wire[`RegAddrBus] jtag_addr_i,  // reg write addr
    input wire[`RegBus] jtag_data_i,      // reg write data

    input wire[`RegAddrBus] raddr1_i, // reg1 read addr
    output reg[`RegBus] rdata1_o,     // reg1 read data

    input wire[`RegAddrBus] raddr2_i, // reg2 read addr
    output reg[`RegBus] rdata2_o,     // reg2 read data

    output reg[`RegBus] jtag_data_o

    );

    reg[`RegBus] regs[0:`RegNum - 1];

    // write reg
    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if ((we_i == `WriteEnable) && (waddr_i != `RegNumLog2'h0)) begin
                regs[waddr_i] <= wdata_i;
            end else if ((jtag_we_i == `WriteEnable) && (jtag_addr_i != `RegNumLog2'h0)) begin
                regs[jtag_addr_i] <= jtag_data_i;
            end
        end
    end

    // read reg1
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata1_o <= `ZeroWord;
        end else if (raddr1_i == `RegNumLog2'h0) begin
            rdata1_o <= `ZeroWord;
        end else if (raddr1_i == waddr_i && we_i == `WriteEnable) begin
            rdata1_o <= wdata_i;
        end else begin
            rdata1_o <= regs[raddr1_i];
        end
    end

    // read reg2
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata2_o <= `ZeroWord;
        end else if (raddr2_i == `RegNumLog2'h0) begin
            rdata2_o <= `ZeroWord;
        end else if (raddr2_i == waddr_i && we_i == `WriteEnable) begin
            rdata2_o <= wdata_i;
        end else begin
            rdata2_o <= regs[raddr2_i];
        end
    end

    // jtag read reg
    always @ (*) begin
        if (rst == `RstEnable) begin
            jtag_data_o <= `ZeroWord;
        end else if (jtag_addr_i == `RegNumLog2'h0) begin
            jtag_data_o <= `ZeroWord;
        end else begin
            jtag_data_o <= regs[jtag_addr_i];
        end
    end

endmodule
