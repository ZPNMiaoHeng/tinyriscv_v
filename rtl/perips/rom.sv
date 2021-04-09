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

`include "../core/defines.sv"


module rom #(
    parameter DP = 4096)(

    input wire clk,
    input wire rst_n,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    input wire[3:0] sel_i,
    input wire we_i,
	output wire[31:0] data_o

    );

    wire[31:0] addr = addr_i[31:2];

    gen_ram #(
        .DP(DP),
        .DW(32),
        .MW(4),
        .AW(32)
    ) u_gen_ram(
        .clk(clk),
        .addr_i(addr),
        .data_i(data_i),
        .sel_i(sel_i),
        .we_i(we_i),
        .data_o(data_o)
    );

endmodule
