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

module flash_ctrl_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    // SPI引脚信号
    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
    output logic        spi_ss_o,
    output logic        spi_ss_oe_o,
    input  logic        spi_dq0_i,
    output logic        spi_dq0_o,
    output logic        spi_dq0_oe_o,
    input  logic        spi_dq1_i,
    output logic        spi_dq1_o,
    output logic        spi_dq1_oe_o,
    input  logic        spi_dq2_i,
    output logic        spi_dq2_o,
    output logic        spi_dq2_oe_o,
    input  logic        spi_dq3_i,
    output logic        spi_dq3_o,
    output logic        spi_dq3_oe_o,

    // OBI总线接口信号
    input  logic        req_i,
    input  logic        we_i,
    input  logic [ 3:0] be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] data_i,
    output logic        gnt_o,
    output logic        rvalid_o,
    output logic [31:0] data_o
    );

    import flash_ctrl_reg_pkg::*;

    flash_ctrl_reg_pkg::flash_ctrl_reg2hw_t reg2hw;
    flash_ctrl_reg_pkg::flash_ctrl_hw2reg_t hw2reg;

    // 状态
    localparam S_IDLE       = 5'b00001;
    localparam S_INIT       = 5'b00010;
    localparam S_READ       = 5'b00100;
    localparam S_PROGRAM    = 5'b01000;
    localparam S_ERASE      = 5'b10000;

    // 操作
    localparam OP_READ      = 2'b00;
    localparam OP_PROGRAM   = 2'b01;
    localparam OP_ERASE     = 2'b10;
    localparam OP_QSPI_INIT = 2'b11;

    logic [4:0] state_d, state_q;
    logic [31:0] op_addr_d, op_addr_q;
    logic [31:0] op_data_d, op_data_q;
    logic [1:0] op_mode_d, op_mode_q;
    logic op_start_d, op_start_q;
    logic sw_access_d, sw_access_q;

    logic we;
    logic re;
    logic [31:0] addr;
    logic [31:0] reg_rdata;
    logic rvalid;
    logic sw_access;

    logic op_ready;
    logic op_idle, op_idle_q;
    logic op_error;
    logic [31:0] op_rdata;

    logic sw_start;
    logic [1:0] sw_op_mode;
    logic sw_ctrl;
    logic sw_program_init;
    logic sw_program_init_q;
    logic [31:0] sw_rw_addr;
    logic [31:0] sw_rw_data;

    logic hw_write_start_bit_en;
    logic hw_write_start_bit_data;

    // 寄存器值
    assign sw_start         = reg2hw.ctrl.start.q && reg2hw.ctrl.start.qe;
    assign sw_op_mode       = reg2hw.ctrl.op_mode.q;
    assign sw_ctrl          = reg2hw.ctrl.sw_ctrl.q;
    assign sw_program_init  = reg2hw.ctrl.program_init.q;
    assign sw_rw_addr       = {9'h0, reg2hw.addr.rw_address.q};
    assign sw_rw_data       = reg2hw.data.q;

    always_comb begin
        // 操作完成清start位
        if ((op_ready && sw_access_q) ||
            ((~op_idle_q) && op_idle)) begin
            hw_write_start_bit_en = 1'b1;
            hw_write_start_bit_data = 1'b0;
        end else if (sw_program_init_q && (~sw_program_init)) begin
            hw_write_start_bit_en = 1'b1;
            hw_write_start_bit_data = 1'b1;
        end else begin
            hw_write_start_bit_en = 1'b0;
            hw_write_start_bit_data = 1'b0;
        end
    end

    // 硬件清start位
    assign hw2reg.ctrl.start.d  = hw_write_start_bit_data;
    assign hw2reg.ctrl.start.de = hw_write_start_bit_en;
    // 硬件更新data寄存器
    assign hw2reg.data.d        = op_rdata;
    assign hw2reg.data.de       = op_ready && sw_access_q && (state_q == S_READ);
    // 硬件更新write result位
    assign hw2reg.ctrl.write_error.d  = op_error;
    assign hw2reg.ctrl.write_error.de = op_ready && sw_access_q;

    assign we        = req_i && we_i;
    assign re        = req_i && (~we_i);
    assign addr      = {9'h0, addr_i[22:0]};
    // 软件访问，addr_i[23]=0表示是软件访问，addr_i[23]=1表示硬件访问(取指或者取数据)
    assign sw_access = (~addr_i[23]);

    always_comb begin
        state_d = state_q;
        op_addr_d = op_addr_q;
        op_data_d = op_data_q;
        op_mode_d = op_mode_q;
        op_start_d = 1'b0;
        sw_access_d = sw_access_q;

        case (state_q)
            S_IDLE: begin
                op_data_d = sw_rw_data;
                // addr_i[23]表示硬件访问(取指或者取数据)
                sw_access_d = sw_access;
                // 软件访问(读、编程、QSPI初始化)
                if (sw_start && sw_ctrl) begin
                    if (sw_op_mode == OP_READ) begin
                        state_d = S_READ;
                    end else if (sw_op_mode == OP_PROGRAM) begin
                        state_d = S_PROGRAM;
                    end else if (sw_op_mode == OP_ERASE) begin
                        state_d = S_ERASE;
                    end else begin
                        state_d = S_INIT;
                    end
                    op_addr_d = sw_rw_addr;
                    op_mode_d = sw_op_mode;
                    op_start_d = 1'b1;
                // 硬件访问(取指、取数据)
                end else if (re && (~sw_access)) begin
                    state_d = S_READ;
                    op_addr_d = addr;
                    op_mode_d = OP_READ;
                    op_start_d = 1'b1;
                end
            end

            S_INIT: begin
                if (op_ready) begin
                    state_d = S_IDLE;
                end
            end

            S_READ: begin
                if (op_ready) begin
                    state_d = S_IDLE;
                end
            end

            S_PROGRAM: begin
                if (op_ready) begin
                    state_d = S_IDLE;
                end
            end

            S_ERASE: begin
                if (op_ready) begin
                    state_d = S_IDLE;
                end
            end

            default: ;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            op_addr_q <= '0;
            op_data_q <= '0;
            op_mode_q <= '0;
            op_start_q <= '0;
            sw_access_q <= '0;
        end else begin
            state_q <= state_d;
            op_addr_q <= op_addr_d;
            op_data_q <= op_data_d;
            op_mode_q <= op_mode_d;
            op_start_q <= op_start_d;
            sw_access_q <= sw_access_d;
        end
    end

    assign gnt_o    = (state_q == S_IDLE) && req_i;
    assign rvalid   = (sw_access && req_i) || op_ready;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_o <= '0;
            data_o <= '0;
            op_idle_q <= 1'b1;
            sw_program_init_q <= '0;
        end else begin
            rvalid_o <= rvalid;
            data_o <= (op_ready ? op_rdata : reg_rdata);
            op_idle_q <= op_idle;
            sw_program_init_q <= sw_program_init;
        end
    end

    flash_n25q_top u_flash_n25q_top (
        .clk_i,
        .rst_ni,
        .start_i        (op_start_q),
        .program_init_i (sw_program_init),
        .addr_i         (op_addr_q),
        .data_i         (op_data_q),
        .op_mode_i      (op_mode_q),
        .data_o         (op_rdata),
        .ready_o        (op_ready),
        .idle_o         (op_idle),
        .write_error_o  (op_error),
        .spi_clk_o,
        .spi_clk_oe_o,
        .spi_ss_o,
        .spi_ss_oe_o,
        .spi_dq0_i,
        .spi_dq0_o,
        .spi_dq0_oe_o,
        .spi_dq1_i,
        .spi_dq1_o,
        .spi_dq1_oe_o,
        .spi_dq2_i,
        .spi_dq2_o,
        .spi_dq2_oe_o,
        .spi_dq3_i,
        .spi_dq3_o,
        .spi_dq3_oe_o
    );

    flash_ctrl_reg_top u_flash_ctrl_reg_top (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .reg2hw     (reg2hw),
        .hw2reg     (hw2reg),
        .reg_we     (we & sw_access),
        .reg_re     (re & sw_access),
        .reg_wdata  (data_i),
        .reg_be     (be_i),
        .reg_addr   (addr),
        .reg_rdata  (reg_rdata)
    );

endmodule
