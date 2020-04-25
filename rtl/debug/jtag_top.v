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
// 涉及跨时钟域传输，这里采用打两拍的方式进行同步
module jtag_top(

    input wire clk,

    input wire jtag_rst_n,

    input wire jtag_pin_TCK,
    input wire jtag_pin_TMS,
    input wire jtag_pin_TDI,
    output wire jtag_pin_TDO,

    output reg reg_we_o,
    output reg[4:0] reg_addr_o,
    output reg[31:0] reg_wdata_o,
    input wire[31:0] reg_rdata_i,
    output reg mem_we_o,
    output reg[31:0] mem_addr_o,
    output reg[31:0] mem_wdata_o,
    input wire[31:0] mem_rdata_i,
    output reg op_req_o,

    output reg halt_req_o,
    output reg reset_req_o

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
    wire dm_reg_we_o;
    wire[4:0] dm_reg_addr_o;
    wire[31:0] dm_reg_wdata_o;
    wire dm_mem_we_o;
    wire[31:0] dm_mem_addr_o;
    wire[31:0] dm_mem_wdata_o;
    wire dm_op_req_o;
    wire dm_halt_req_o;
    wire dm_reset_req_o;

    reg tmp_reg_we_o;
    reg[4:0] tmp_reg_addr_o;
    reg[31:0] tmp_reg_wdata_o;
    reg tmp_mem_we_o;
    reg[31:0] tmp_mem_addr_o;
    reg[31:0] tmp_mem_wdata_o;
    reg tmp_op_req_o;
    reg tmp_halt_req_o;
    reg tmp_reset_req_o;


    // 打第一拍
    always @ (posedge clk) begin
        if (!jtag_rst_n) begin
            tmp_reg_we_o <= `WriteDisable;
            tmp_reg_addr_o <= `ZeroReg;
            tmp_reg_wdata_o <= `ZeroWord;
            tmp_mem_we_o <= `WriteDisable;
            tmp_mem_addr_o <= `ZeroWord;
            tmp_mem_wdata_o <= `ZeroWord;
            tmp_op_req_o <= 1'b0;
            tmp_halt_req_o <= 1'b0;
            tmp_reset_req_o <= 1'b0;
        end else begin
            tmp_reg_we_o <= dm_reg_we_o;
            tmp_reg_addr_o <= dm_reg_addr_o;
            tmp_reg_wdata_o <= dm_reg_wdata_o;
            tmp_mem_we_o <= dm_mem_we_o;
            tmp_mem_addr_o <= dm_mem_addr_o;
            tmp_mem_wdata_o <= dm_mem_wdata_o;
            tmp_op_req_o <= dm_op_req_o;
            tmp_halt_req_o <= dm_halt_req_o;
            tmp_reset_req_o <= dm_reset_req_o;
        end
    end

    // 打第二拍
    always @ (posedge clk) begin
        if (!jtag_rst_n) begin
            reg_we_o <= `WriteDisable;
            reg_addr_o <= `ZeroReg;
            reg_wdata_o <= `ZeroWord;
            mem_we_o <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_wdata_o <= `ZeroWord;
            op_req_o <= 1'b0;
            halt_req_o <= 1'b0;
            reset_req_o <= 1'b0;
        end else begin
            reg_we_o <= tmp_reg_we_o;
            reg_addr_o <= tmp_reg_addr_o;
            reg_wdata_o <= tmp_reg_wdata_o;
            mem_we_o <= tmp_mem_we_o;
            mem_addr_o <= tmp_mem_addr_o;
            mem_wdata_o <= tmp_mem_wdata_o;
            op_req_o <= tmp_op_req_o;
            halt_req_o <= tmp_halt_req_o;
            reset_req_o <= tmp_reset_req_o;
        end
    end

    jtag_driver u_jtag_driver(
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

    jtag_dm u_jtag_dm(
        .clk(jtag_pin_TCK),
        .rst_n(jtag_rst_n),
        .dtm_req_valid(dtm_req_valid),
        .dtm_req_data(dtm_req_data),
        .dm_is_busy(dm_is_busy),
        .dm_resp_data(dm_resp_data),
        .dm_reg_we(dm_reg_we_o),
        .dm_reg_addr(dm_reg_addr_o),
        .dm_reg_wdata(dm_reg_wdata_o),
        .dm_reg_rdata(reg_rdata_i),
        .dm_mem_we(dm_mem_we_o),
        .dm_mem_addr(dm_mem_addr_o),
        .dm_mem_wdata(dm_mem_wdata_o),
        .dm_mem_rdata(mem_rdata_i),
        .dm_op_req(dm_op_req_o),
        .dm_halt_req(dm_halt_req_o),
        .dm_reset_req(dm_reset_req_o)
    );

endmodule
