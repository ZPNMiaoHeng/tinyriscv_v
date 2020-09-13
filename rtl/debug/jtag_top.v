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

`include "../core/defines.v"

// JTAG顶层模块
module jtag_top #(
    parameter DMI_ADDR_BITS = 6,
    parameter DMI_DATA_BITS = 32,
    parameter DMI_OP_BITS = 2)(

    input wire clk,
    input wire jtag_rst_n,

    input wire jtag_pin_TCK,
    input wire jtag_pin_TMS,
    input wire jtag_pin_TDI,
    output wire jtag_pin_TDO,

    output wire reg_we_o,
    output wire[4:0] reg_addr_o,
    output wire[31:0] reg_wdata_o,
    input wire[31:0] reg_rdata_i,
    output wire mem_we_o,
    output wire[31:0] mem_addr_o,
    output wire[31:0] mem_wdata_o,
    input wire[31:0] mem_rdata_i,
    output wire op_req_o,

    output wire halt_req_o,
    output wire reset_req_o

    );

    parameter DM_RESP_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    parameter DTM_REQ_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;

    // jtag_driver
    wire dtm_req_valid;
    wire[DTM_REQ_BITS - 1:0] dtm_req_data;

    // jtag_dm
    wire dm_is_busy;
    wire[DM_RESP_BITS - 1:0] dm_resp_data;
    wire dm_reg_we_o;
    wire[4:0] dm_reg_addr_o;
    wire[31:0] dm_reg_wdata_o;
    wire dm_mem_we_o;
    wire[31:0] dm_mem_addr_o;
    wire[31:0] dm_mem_wdata_o;
    wire dm_op_req_sync;
    wire dm_halt_req_o;
    wire dm_reset_req_o;
    wire dm_resp_ready;
    wire halt_req_sync;
    wire reset_req_sync;

    assign reg_addr_o = dm_op_req_sync? dm_reg_addr_o: 5'h0;
    assign reg_wdata_o = dm_op_req_sync? dm_reg_wdata_o: 32'h0;
    assign reg_we_o = dm_op_req_sync? dm_reg_we_o: 1'b0;
    assign mem_addr_o = dm_op_req_sync? dm_mem_addr_o: 32'h0;
    assign mem_wdata_o = dm_op_req_sync? dm_mem_wdata_o: 32'h0;
    assign mem_we_o = dm_op_req_sync? dm_mem_we_o: 1'b0;
    assign halt_req_o = halt_req_sync;
    assign reset_req_o = reset_req_sync;

    assign op_req_o = dm_op_req_sync;

    gen_ticks_sync #(
        .DW(1),
        .DP(2) 
    ) u_halt_sync_o(
        .rst(jtag_rst_n),
        .clk(clk),
        .din(dm_halt_req_o),
        .dout(halt_req_sync)
    );

    gen_ticks_sync #(
        .DW(1),
        .DP(2) 
    ) u_reset_sync_o(
        .rst(jtag_rst_n),
        .clk(clk),
        .din(dm_reset_req_o),
        .dout(reset_req_sync)
    );

    gen_ticks_sync #(
        .DW(1),
        .DP(2) 
    ) u_jtag_sync_o(
        .rst(jtag_rst_n),
        .clk(clk),
        .din(dm_op_req_o),
        .dout(dm_op_req_sync)
    );

    gen_ticks_sync #(
        .DW(1),
        .DP(2) 
    ) u_jtag_sync_i(
        .rst(jtag_rst_n),
        .clk(jtag_pin_TCK),
        .din(dm_op_req_sync),
        .dout(dm_resp_ready)
    );

    jtag_driver #(
        .DMI_ADDR_BITS(DMI_ADDR_BITS),
        .DMI_DATA_BITS(DMI_DATA_BITS),
        .DMI_OP_BITS(DMI_OP_BITS)
    ) u_jtag_driver(
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

    jtag_dm #(
        .DMI_ADDR_BITS(DMI_ADDR_BITS),
        .DMI_DATA_BITS(DMI_DATA_BITS),
        .DMI_OP_BITS(DMI_OP_BITS)
    ) u_jtag_dm(
        .clk(jtag_pin_TCK),
        .rst_n(jtag_rst_n),
        .dm_resp_ready_i(dm_resp_ready),
        .dtm_req_valid_i(dtm_req_valid),
        .dtm_req_data_i(dtm_req_data),
        .dm_is_busy_o(dm_is_busy),
        .dm_resp_data_o(dm_resp_data),
        .dm_reg_we_o(dm_reg_we_o),
        .dm_reg_addr_o(dm_reg_addr_o),
        .dm_reg_wdata_o(dm_reg_wdata_o),
        .dm_reg_rdata_i(reg_rdata_i),
        .dm_mem_we_o(dm_mem_we_o),
        .dm_mem_addr_o(dm_mem_addr_o),
        .dm_mem_wdata_o(dm_mem_wdata_o),
        .dm_mem_rdata_i(mem_rdata_i),
        .dm_op_req_o(dm_op_req_o),
        .dm_halt_req_o(dm_halt_req_o),
        .dm_reset_req_o(dm_reset_req_o)
    );

endmodule
