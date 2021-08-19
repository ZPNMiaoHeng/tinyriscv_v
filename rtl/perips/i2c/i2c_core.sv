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

module i2c_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    output logic        scl_o,
    output logic        scl_oe_o,
    input  logic        scl_i,
    output logic        sda_o,
    output logic        sda_oe_o,
    input  logic        sda_i,

    output logic        irq_o,

    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import i2c_reg_pkg::*;

    i2c_reg_pkg::i2c_reg2hw_t reg2hw;
    i2c_reg_pkg::i2c_hw2reg_t hw2reg;

    logic master_mode;
    logic slave_mode;
    logic op_write;
    logic op_read;
    logic start;
    logic [15:0] clk_div;
    logic int_enable;
    logic [7:0] master_address;
    logic [7:0] master_register;
    logic [7:0] master_data;
    logic master_ready, master_ready_q;
    logic master_start;
    logic master_error;
    logic [7:0] master_read_data;

    assign master_mode = ~reg2hw.ctrl.mode.q;
    assign slave_mode  = reg2hw.ctrl.mode.q;
    assign op_write    = ~reg2hw.ctrl.write.q;
    assign op_read     = reg2hw.ctrl.write.q;
    assign start       = reg2hw.ctrl.start.q;
    assign clk_div     = reg2hw.ctrl.clk_div.q;
    assign int_enable  = reg2hw.ctrl.int_en.q;

    assign master_address  = reg2hw.master_data.address.q;
    assign master_register = reg2hw.master_data.regreg.q;
    assign master_data     = reg2hw.master_data.data.q;

    // 软件写1启动master传输
    assign master_start = reg2hw.ctrl.start.qe && reg2hw.ctrl.start.q && master_ready;

    // master传输完成后，硬件清start位
    assign hw2reg.ctrl.start.d = 1'b0;
    // master传输完成上升沿脉冲
    assign hw2reg.ctrl.start.de = (~master_ready_q) && master_ready;

    // 传输完成产生中断pending
    assign hw2reg.ctrl.int_pending.d = 1'b1;
    assign hw2reg.ctrl.int_pending.de = int_enable && (~master_ready_q) && master_ready;

    // 传输完成并且是读操作，则更新master data
    assign hw2reg.master_data.data.d = master_read_data;
    assign hw2reg.master_data.data.de = op_read && (~master_ready_q) && master_ready;

    // 传输完成更新error
    assign hw2reg.ctrl.error.d = master_error;
    assign hw2reg.ctrl.error.de = (~master_ready_q) && master_ready;

    assign irq_o = reg2hw.ctrl.int_pending.q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            master_ready_q <= 1'b1;
        end else begin
            master_ready_q <= master_ready;
        end
    end

    i2c_master u_i2c_master (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .enable_i     (master_mode),
        .div_ratio_i  (clk_div),
        .read_i       (op_read),
        .slave_addr_i (master_address),
        .slave_reg_i  (master_register),
        .slave_data_i (master_data),
        .start_i      (master_start),
        .ready_o      (master_ready),
        .error_o      (master_error),
        .data_o       (master_read_data),
        .scl_i        (scl_i),
        .scl_o        (scl_o),
        .scl_oe_o     (scl_oe_o),
        .sda_i        (sda_i),
        .sda_o        (sda_o),
        .sda_oe_o     (sda_oe_o)
    );

    i2c_reg_top u_i2c_reg_top (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .reg2hw     (reg2hw),
        .hw2reg     (hw2reg),
        .reg_we     (reg_we_i),
        .reg_re     (reg_re_i),
        .reg_wdata  (reg_wdata_i),
        .reg_be     (reg_be_i),
        .reg_addr   (reg_addr_i),
        .reg_rdata  (reg_rdata_o)
    );

endmodule
