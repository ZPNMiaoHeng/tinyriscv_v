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


module exu_commit(

    input wire clk,
    input wire rst_n,

    input wire req_muldiv_i,
    input wire muldiv_reg_we_i,
    input wire[4:0] muldiv_reg_waddr_i,
    input wire[31:0] muldiv_reg_wdata_i,

    input wire req_mem_i,
    input wire mem_reg_we_i,
    input wire[4:0] mem_reg_waddr_i,
    input wire[31:0] mem_reg_wdata_i,

    input wire req_csr_i,
    input wire csr_reg_we_i,
    input wire[4:0] csr_reg_waddr_i,
    input wire[31:0] csr_reg_wdata_i,

    input wire req_bjp_i,
    input wire bjp_reg_we_i,
    input wire[31:0] bjp_reg_wdata_i,
    input wire[4:0] bjp_reg_waddr_i,

    input wire rd_we_i,
    input wire[4:0] rd_waddr_i,
    input wire[31:0] alu_reg_wdata_i,

    output wire reg_we_o,
    output wire[4:0] reg_waddr_o,
    output wire[31:0] reg_wdata_o

    );

    wire use_alu_res = (~req_muldiv_i) &
                       (~req_mem_i) &
                       (~req_csr_i) &
                       (~req_bjp_i);

    assign reg_we_o = muldiv_reg_we_i | mem_reg_we_i | csr_reg_we_i | use_alu_res | bjp_reg_we_i;

    assign reg_waddr_o = ({5{muldiv_reg_we_i}} & muldiv_reg_waddr_i) |
                         ({5{mem_reg_we_i}} & mem_reg_waddr_i) |
                         ({5{csr_reg_we_i}} & csr_reg_waddr_i) |
                         ({5{bjp_reg_we_i}} & bjp_reg_waddr_i) |
                         ({5{rd_we_i}} & rd_waddr_i);

    assign reg_wdata_o = ({32{muldiv_reg_we_i}} & muldiv_reg_wdata_i) |
                         ({32{mem_reg_we_i}} & mem_reg_wdata_i) |
                         ({32{csr_reg_we_i}} & csr_reg_wdata_i) |
                         ({32{bjp_reg_we_i}} & bjp_reg_wdata_i) |
                         ({32{use_alu_res}} & alu_reg_wdata_i);

endmodule
