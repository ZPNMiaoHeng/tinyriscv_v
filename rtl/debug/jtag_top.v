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


module jtag_top (

    input wire jtag_rst_n,

    input wire jtag_pin_TCK,
    input wire jtag_pin_TMS,
    input wire jtag_pin_TDI,
    output wire jtag_pin_TDO,

    output wire reg_we,
    output wire[4:0] reg_addr,
    output wire[31:0] reg_wdata,
    input wire[31:0] reg_rdata,
    output wire mem_we,
    output wire[31:0] mem_addr,
    output wire[31:0] mem_wdata,
    input wire[31:0] mem_rdata,

    output wire halt_req,
    output wire reset_req

    );

    parameter DMI_ADDR_BITS = 6;
    parameter DMI_DATA_BITS = 32;
    parameter DMI_OP_BITS = 2;
    parameter DM_RESP_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    parameter DTM_REQ_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;

    // jtag_driver
    wire dtm_req_valid;
    wire[DTM_REQ_BITS - 1:0] dtm_req_data;

    // jtag_dm
    wire dm_is_busy;
    wire[DM_RESP_BITS - 1:0] dm_resp_data;


    jtag_driver u_jtag_driver (
        .rst_n(jtag_rst_n),
        .jtag_TCK(jtag_pin_TCK),
        .jtag_TDI(jtag_pin_TDI),
        .jtag_TMS(jtag_pin_TMS),
        .jtag_TDO(jtag_pin_TDO),
        .dm_is_busy(dm_is_busy),
        .dm_resp_data(dm_resp_data),
        .dtm_req_valid(dtm_req_valid),
        .dtm_req_data(dtm_req_data)
    );

    jtag_dm u_jtag_dm (
        .clk(jtag_pin_TCK),
        .rst_n(jtag_rst_n),
        .dtm_req_valid(dtm_req_valid),
        .dtm_req_data(dtm_req_data),
        .dm_is_busy(dm_is_busy),
        .dm_resp_data(dm_resp_data),
        .dm_reg_we(reg_we),
        .dm_reg_addr(reg_addr),
        .dm_reg_wdata(reg_wdata),
        .dm_reg_rdata(reg_rdata),
        .dm_mem_we(mem_we),
        .dm_mem_addr(mem_addr),
        .dm_mem_wdata(mem_wdata),
        .dm_mem_rdata(mem_rdata),
        .dm_halt_req(halt_req),
        .dm_reset_req(reset_req)
    );

endmodule
