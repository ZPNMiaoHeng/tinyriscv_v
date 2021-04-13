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

// tinyriscv soc顶层模块
module tinyriscv_soc_top(

    input wire clk,
    input wire rst_ext_ni,

    output wire halted_ind,  // jtag是否已经halt住CPU信号

    output wire uart_tx_pin, // UART发送引脚
    input wire uart_rx_pin,  // UART接收引脚

    inout wire[1:0] gpio,    // GPIO引脚

    input wire jtag_TCK,     // JTAG TCK引脚
    input wire jtag_TMS,     // JTAG TMS引脚
    input wire jtag_TDI,     // JTAG TDI引脚
    output wire jtag_TDO     // JTAG TDO引脚

    );



    localparam int MASTERS = 2; //Number of master ports
    localparam int SLAVES  = 2; //Number of slave ports

    localparam int CoreD = 0;
    localparam int CoreI = 1;

    localparam int Rom = 0;
    localparam int Ram = 1;


    wire           master_req       [MASTERS];
    wire           master_gnt       [MASTERS];
    wire           master_rvalid    [MASTERS];
    wire [31:0]    master_addr      [MASTERS];
    wire           master_we        [MASTERS];
    wire [ 3:0]    master_be        [MASTERS];
    wire [31:0]    master_rdata     [MASTERS];
    wire [31:0]    master_wdata     [MASTERS];

    wire           slave_req        [SLAVES];
    wire           slave_gnt        [SLAVES];
    wire           slave_rvalid     [SLAVES];
    wire [31:0]    slave_addr       [SLAVES];
    wire           slave_we         [SLAVES];
    wire [ 3:0]    slave_be         [SLAVES];
    wire [31:0]    slave_rdata      [SLAVES];
    wire [31:0]    slave_wdata      [SLAVES];

    wire [31:0]    slave_addr_mask  [SLAVES];
    wire [31:0]    slave_addr_base  [SLAVES];

    wire ndmreset;
    wire ndmreset_n;

    assign ndmreset = 1'b0;

    tinyriscv_core #(
        .DEBUG_HALT_ADDR(`DEBUG_ADDR_BASE + 16'h800),
        .DEBUG_EXCEPTION_ADDR(`DEBUG_ADDR_BASE + 16'h808)
    ) u_tinyriscv_core (
        .clk(clk),
        .rst_n(ndmreset_n),

        .instr_req_o(master_req[CoreI]),
        .instr_gnt_i(master_gnt[CoreI]),
        .instr_rvalid_i(master_rvalid[CoreI]),
        .instr_addr_o(master_addr[CoreI]),
        .instr_rdata_i(master_rdata[CoreI]),
        .instr_err_i(1'b0),

        .data_req_o(master_req[CoreD]),
        .data_gnt_i(master_gnt[CoreD]),
        .data_rvalid_i(master_rvalid[CoreD]),
        .data_we_o(master_we[CoreD]),
        .data_be_o(master_be[CoreD]),
        .data_addr_o(master_addr[CoreD]),
        .data_wdata_o(master_wdata[CoreD]),
        .data_rdata_i(master_rdata[CoreD]),
        .data_err_i(1'b0),

        .irq_software_i(1'b0),
        .irq_timer_i(1'b0),
        .irq_external_i(1'b0),
        .irq_fast_i(15'b0),
        .irq_nm_i(1'b0),

        .debug_req_i(1'b0)
    );


    assign slave_addr_mask[Rom] = `ROM_ADDR_MASK;
    assign slave_addr_base[Rom] = `ROM_ADDR_BASE;
    // 指令存储器
    rom #(
        .DP(`ROM_DEPTH)
    ) u_rom(
        .clk(clk),
        .rst_n(ndmreset_n),
        .addr_i(slave_addr[Rom]),
        .data_i(slave_wdata[Rom]),
        .sel_i(slave_be[Rom]),
        .we_i(slave_we[Rom]),
        .data_o(slave_rdata[Rom])
    );

    assign slave_addr_mask[Ram] = `RAM_ADDR_MASK;
    assign slave_addr_base[Ram] = `RAM_ADDR_BASE;
    // 数据存储器
    ram #(
        .DP(`RAM_DEPTH)
    ) u_ram(
        .clk(clk),
        .rst_n(ndmreset_n),
        .addr_i(slave_addr[Ram]),
        .data_i(slave_wdata[Ram]),
        .sel_i(slave_be[Ram]),
        .we_i(slave_we[Ram]),
        .data_o(slave_rdata[Ram])
    );

    obi_interconnect #(
        .MASTERS(MASTERS),
        .SLAVES(SLAVES)
    ) bus (
        .clk_i(clk),
        .rst_ni(ndmreset_n),
        .master_req_i(master_req),
        .master_gnt_o(master_gnt),
        .master_rvalid_o(master_rvalid),
        .master_we_i(master_we),
        .master_be_i(master_be),
        .master_addr_i(master_addr),
        .master_wdata_i(master_wdata),
        .master_rdata_o(master_rdata),
        .slave_addr_mask_i(slave_addr_mask),
        .slave_addr_base_i(slave_addr_base),
        .slave_req_o(slave_req),
        .slave_gnt_i(slave_gnt),
        .slave_rvalid_i(slave_rvalid),
        .slave_we_o(slave_we),
        .slave_be_o(slave_be),
        .slave_addr_o(slave_addr),
        .slave_wdata_o(slave_wdata),
        .slave_rdata_i(slave_rdata)
    );


    rst_gen #(
        .RESET_FIFO_DEPTH(5)
    ) u_rst (
        .clk(clk),
        .rst_ni(rst_ext_ni & (~ndmreset)),
        .rst_no(ndmreset_n)
    );


endmodule
