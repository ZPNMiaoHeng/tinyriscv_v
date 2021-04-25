 /*                                                                      
 Copyright 2021 Blue Liang, liangkangnan@163.com
                                                                         
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


module jtag_sba #(

    )(

    input wire                      clk,
    input wire                      rst_n,

    output wire                     sbbusy_o,

    output wire                     master_req_o,
    input  wire                     master_gnt_i,
    input  wire                     master_rvalid_i,
    output wire                     master_we_o,
    output wire [3:0]               master_be_o,
    output wire [31:0]              master_addr_o,
    output wire [31:0]              master_wdata_o,
    input  wire [31:0]              master_rdata_i,
    input  wire                     master_err_i

    );


    assign sbbusy_o = 1'b0;

    assign master_req_o = 1'b0;
    assign master_we_o = 1'b0;



endmodule
