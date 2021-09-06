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
`include "../debug/jtag_def.sv"

// tinyriscv soc顶层模块
module tinyriscv_soc_top #(
    parameter bit          TRACE_ENABLE         = 1'b0,
    parameter int          GPIO_NUM             = 2
    )(

    input wire clk_50m_i,           // 时钟引脚
    input wire rst_ext_ni,          // 复位引脚，低电平有效

    output wire halted_ind_pin,     // jtag是否已经halt住CPU，高电平有效

    output wire uart_tx_pin,        // UART发送引脚
    input wire uart_rx_pin,         // UART接收引脚

    inout wire i2c_scl_pin,         // I2C SCL引脚
    inout wire i2c_sda_pin,         // I2C SDA引脚

    inout wire spi_clk_pin,         // SPI CLK引脚
    inout wire spi_ss_pin,          // SPI SS引脚
    inout wire spi_dq0_pin,         // SPI DQ0(MOSI)引脚
    inout wire spi_dq1_pin,         // SPI DQ1(MISO)引脚
    inout wire spi_dq2_pin,         // SPI DQ2引脚
    inout wire spi_dq3_pin,         // SPI DQ3引脚

    inout wire[1:0] gpio_pins,      // GPIO引脚，1bit代表一个GPIO

`ifdef VERILATOR
    output wire dump_wave_en_o,     // dump wave使能
`endif

    input wire jtag_TCK_pin,        // JTAG TCK引脚
    input wire jtag_TMS_pin,        // JTAG TMS引脚
    input wire jtag_TDI_pin,        // JTAG TDI引脚
    output wire jtag_TDO_pin        // JTAG TDO引脚

    );

    localparam int MASTERS      = 3; // Number of master ports
`ifdef VERILATOR
    localparam int SLAVES       = 10; // Number of slave ports
`else
    localparam int SLAVES       = 9; // Number of slave ports
`endif

    // masters
    localparam int JtagHost     = 0;
    localparam int CoreD        = 1;
    localparam int CoreI        = 2;

    // slaves
    localparam int Rom          = 0;
    localparam int Ram          = 1;
    localparam int JtagDevice   = 2;
    localparam int Timer0       = 3;
    localparam int Gpio         = 4;
    localparam int Uart0        = 5;
    localparam int Rvic         = 6;
    localparam int I2c0         = 7;
    localparam int Spi0         = 8;
`ifdef VERILATOR
    localparam int SimCtrl      = 9;
`endif


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

`ifdef VERILATOR
    wire           sim_jtag_tck;
    wire           sim_jtag_tms;
    wire           sim_jtag_tdi;
    wire           sim_jtag_trstn;
    wire           sim_jtag_tdo;
    wire [31:0]    sim_jtag_exit;
`endif

    wire clk;

    wire ndmreset;
    wire ndmreset_n;
    wire debug_req;
    wire core_halted;

    reg[31:0] irq_src;
    wire int_req;
    wire[7:0] int_id;

    wire timer0_irq;
    wire uart0_irq;
    wire gpio0_irq;
    wire gpio1_irq;
    wire i2c0_irq;
    wire spi0_irq;

    wire[GPIO_NUM-1:0] gpio_data_in;
    wire[GPIO_NUM-1:0] gpio_oe;
    wire[GPIO_NUM-1:0] gpio_data_out;

    wire i2c_scl_in;
    wire i2c_scl_oe;
    wire i2c_scl_out;
    wire i2c_sda_in;
    wire i2c_sda_oe;
    wire i2c_sda_out;

    wire spi_clk_in;
    wire spi_clk_oe;
    wire spi_clk_out;
    wire spi_ss_in;
    wire spi_ss_oe;
    wire spi_ss_out;
    wire spi_dq0_in;
    wire spi_dq0_oe;
    wire spi_dq0_out;
    wire spi_dq1_in;
    wire spi_dq1_oe;
    wire spi_dq1_out;
    wire spi_dq2_in;
    wire spi_dq2_oe;
    wire spi_dq2_out;
    wire spi_dq3_in;
    wire spi_dq3_oe;
    wire spi_dq3_out;

    always @ (*) begin
        irq_src    = 32'h0;
        irq_src[0] = timer0_irq;
        irq_src[1] = uart0_irq;
        irq_src[2] = gpio0_irq;
        irq_src[3] = gpio1_irq;
        irq_src[4] = i2c0_irq;
        irq_src[5] = spi0_irq;
    end

`ifdef VERILATOR
    assign halted_ind_pin = core_halted;
`else
    // FPGA低电平点亮LED
    assign halted_ind_pin = ~core_halted;
`endif

    tinyriscv_core #(
        .DEBUG_HALT_ADDR(`DEBUG_ADDR_BASE + `HaltAddress),
        .DEBUG_EXCEPTION_ADDR(`DEBUG_ADDR_BASE + `ExceptionAddress),
        .BranchPredictor(1'b1),
        .TRACE_ENABLE(TRACE_ENABLE)
    ) u_tinyriscv_core (
        .clk            (clk),
        .rst_n          (ndmreset_n),

        .instr_req_o    (master_req[CoreI]),
        .instr_gnt_i    (master_gnt[CoreI]),
        .instr_rvalid_i (master_rvalid[CoreI]),
        .instr_addr_o   (master_addr[CoreI]),
        .instr_rdata_i  (master_rdata[CoreI]),
        .instr_err_i    (1'b0),

        .data_req_o     (master_req[CoreD]),
        .data_gnt_i     (master_gnt[CoreD]),
        .data_rvalid_i  (master_rvalid[CoreD]),
        .data_we_o      (master_we[CoreD]),
        .data_be_o      (master_be[CoreD]),
        .data_addr_o    (master_addr[CoreD]),
        .data_wdata_o   (master_wdata[CoreD]),
        .data_rdata_i   (master_rdata[CoreD]),
        .data_err_i     (1'b0),

        .int_req_i      (int_req),
        .int_id_i       (int_id),

        .debug_req_i    (debug_req)
    );

    assign slave_addr_mask[Rom] = `ROM_ADDR_MASK;
    assign slave_addr_base[Rom] = `ROM_ADDR_BASE;
    // 1.指令存储器
    rom #(
        .DP(`ROM_DEPTH)
    ) u_rom (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .req_i      (slave_req[Rom]),
        .addr_i     (slave_addr[Rom]),
        .data_i     (slave_wdata[Rom]),
        .be_i       (slave_be[Rom]),
        .we_i       (slave_we[Rom]),
        .gnt_o      (slave_gnt[Rom]),
        .rvalid_o   (slave_rvalid[Rom]),
        .data_o     (slave_rdata[Rom])
    );

    assign slave_addr_mask[Ram] = `RAM_ADDR_MASK;
    assign slave_addr_base[Ram] = `RAM_ADDR_BASE;
    // 2.数据存储器
    ram #(
        .DP(`RAM_DEPTH)
    ) u_ram (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .req_i      (slave_req[Ram]),
        .addr_i     (slave_addr[Ram]),
        .data_i     (slave_wdata[Ram]),
        .be_i       (slave_be[Ram]),
        .we_i       (slave_we[Ram]),
        .gnt_o      (slave_gnt[Ram]),
        .rvalid_o   (slave_rvalid[Ram]),
        .data_o     (slave_rdata[Ram])
    );

    assign slave_addr_mask[Timer0] = `TIMER0_ADDR_MASK;
    assign slave_addr_base[Timer0] = `TIMER0_ADDR_BASE;
    // 3.定时器0模块
    timer_top timer0(
        .clk_i   (clk),
        .rst_ni  (ndmreset_n),
        .irq_o   (timer0_irq),
        .req_i   (slave_req[Timer0]),
        .we_i    (slave_we[Timer0]),
        .be_i    (slave_be[Timer0]),
        .addr_i  (slave_addr[Timer0]),
        .data_i  (slave_wdata[Timer0]),
        .gnt_o   (slave_gnt[Timer0]),
        .rvalid_o(slave_rvalid[Timer0]),
        .data_o  (slave_rdata[Timer0])
    );

    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_data
        assign gpio_pins[i] = gpio_oe[i] ? gpio_data_out[i] : 1'bz;
        assign gpio_data_in[i] = gpio_pins[i];
    end

    assign slave_addr_mask[Gpio] = `GPIO_ADDR_MASK;
    assign slave_addr_base[Gpio] = `GPIO_ADDR_BASE;
    // 4.GPIO模块
    gpio_top #(
        .GPIO_NUM(GPIO_NUM)
    ) u_gpio (
        .clk_i          (clk),
        .rst_ni         (ndmreset_n),
        .gpio_oe_o      (gpio_oe),
        .gpio_data_o    (gpio_data_out),
        .gpio_data_i    (gpio_data_in),
        .irq_gpio0_o    (gpio0_irq),
        .irq_gpio1_o    (gpio1_irq),
        .irq_gpio2_4_o  (),
        .irq_gpio5_7_o  (),
        .req_i          (slave_req[Gpio]),
        .we_i           (slave_we[Gpio]),
        .be_i           (slave_be[Gpio]),
        .addr_i         (slave_addr[Gpio]),
        .data_i         (slave_wdata[Gpio]),
        .gnt_o          (slave_gnt[Gpio]),
        .rvalid_o       (slave_rvalid[Gpio]),
        .data_o         (slave_rdata[Gpio])
    );

    assign slave_addr_mask[Uart0] = `UART0_ADDR_MASK;
    assign slave_addr_base[Uart0] = `UART0_ADDR_BASE;
    // 5.串口0模块
    uart_top uart0 (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .rx_i       (uart_rx_pin),
        .tx_o       (uart_tx_pin),
        .irq_o      (uart0_irq),
        .req_i      (slave_req[Uart0]),
        .we_i       (slave_we[Uart0]),
        .be_i       (slave_be[Uart0]),
        .addr_i     (slave_addr[Uart0]),
        .data_i     (slave_wdata[Uart0]),
        .gnt_o      (slave_gnt[Uart0]),
        .rvalid_o   (slave_rvalid[Uart0]),
        .data_o     (slave_rdata[Uart0])
    );

    assign slave_addr_mask[Rvic] = `RVIC_ADDR_MASK;
    assign slave_addr_base[Rvic] = `RVIC_ADDR_BASE;
    // 6.中断控制器模块
    rvic_top u_rvic(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .src_i      (irq_src),
        .irq_o      (int_req),
        .irq_id_o   (int_id),
        .req_i      (slave_req[Rvic]),
        .we_i       (slave_we[Rvic]),
        .be_i       (slave_be[Rvic]),
        .addr_i     (slave_addr[Rvic]),
        .data_i     (slave_wdata[Rvic]),
        .gnt_o      (slave_gnt[Rvic]),
        .rvalid_o   (slave_rvalid[Rvic]),
        .data_o     (slave_rdata[Rvic])
    );

    assign i2c_scl_pin = i2c_scl_oe ? i2c_scl_out : 1'bz;
    assign i2c_scl_in = i2c_scl_pin;
    assign i2c_sda_pin = i2c_sda_oe ? i2c_sda_out : 1'bz;
    assign i2c_sda_in = i2c_sda_pin;

    assign slave_addr_mask[I2c0] = `I2C0_ADDR_MASK;
    assign slave_addr_base[I2c0] = `I2C0_ADDR_BASE;
    // 7.I2C0模块
    i2c_top i2c0(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .scl_o      (i2c_scl_out),
        .scl_oe_o   (i2c_scl_oe),
        .scl_i      (i2c_scl_in),
        .sda_o      (i2c_sda_out),
        .sda_oe_o   (i2c_sda_oe),
        .sda_i      (i2c_sda_in),
        .irq_o      (i2c0_irq),
        .req_i      (slave_req[I2c0]),
        .we_i       (slave_we[I2c0]),
        .be_i       (slave_be[I2c0]),
        .addr_i     (slave_addr[I2c0]),
        .data_i     (slave_wdata[I2c0]),
        .gnt_o      (slave_gnt[I2c0]),
        .rvalid_o   (slave_rvalid[I2c0]),
        .data_o     (slave_rdata[I2c0])
    );

    assign spi_clk_pin = spi_clk_oe ? spi_clk_out : 1'bz;
    assign spi_clk_in = spi_clk_pin;
    assign spi_ss_pin = spi_ss_oe ? spi_ss_out : 1'bz;
    assign spi_ss_in = spi_ss_pin;
    assign spi_dq0_pin = spi_dq0_oe ? spi_dq0_out : 1'bz;
    assign spi_dq0_in = spi_dq0_pin;
    assign spi_dq1_pin = spi_dq1_oe ? spi_dq1_out : 1'bz;
    assign spi_dq1_in = spi_dq1_pin;
    assign spi_dq2_pin = spi_dq2_oe ? spi_dq2_out : 1'bz;
    assign spi_dq2_in = spi_dq2_pin;
    assign spi_dq3_pin = spi_dq3_oe ? spi_dq3_out : 1'bz;
    assign spi_dq3_in = spi_dq3_pin;

    assign slave_addr_mask[Spi0] = `SPI0_ADDR_MASK;
    assign slave_addr_base[Spi0] = `SPI0_ADDR_BASE;
    // 8.SPI0模块
    spi_top spi0(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .spi_clk_i  (spi_clk_in),
        .spi_clk_o  (spi_clk_out),
        .spi_clk_oe_o(spi_clk_oe),
        .spi_ss_i   (spi_ss_in),
        .spi_ss_o   (spi_ss_out),
        .spi_ss_oe_o(spi_ss_oe),
        .spi_dq0_i  (spi_dq0_in),
        .spi_dq0_o  (spi_dq0_out),
        .spi_dq0_oe_o(spi_dq0_oe),
        .spi_dq1_i  (spi_dq1_in),
        .spi_dq1_o  (spi_dq1_out),
        .spi_dq1_oe_o(spi_dq1_oe),
        .spi_dq2_i  (spi_dq2_in),
        .spi_dq2_o  (spi_dq2_out),
        .spi_dq2_oe_o(spi_dq2_oe),
        .spi_dq3_i  (spi_dq3_in),
        .spi_dq3_o  (spi_dq3_out),
        .spi_dq3_oe_o(spi_dq3_oe),
        .irq_o      (spi0_irq),
        .req_i      (slave_req[Spi0]),
        .we_i       (slave_we[Spi0]),
        .be_i       (slave_be[Spi0]),
        .addr_i     (slave_addr[Spi0]),
        .data_i     (slave_wdata[Spi0]),
        .gnt_o      (slave_gnt[Spi0]),
        .rvalid_o   (slave_rvalid[Spi0]),
        .data_o     (slave_rdata[Spi0])
    );

`ifdef VERILATOR
    assign slave_addr_mask[SimCtrl] = `SIM_CTRL_ADDR_MASK;
    assign slave_addr_base[SimCtrl] = `SIM_CTRL_ADDR_BASE;
    // 9.仿真控制模块
    sim_ctrl u_sim_ctrl(
        .clk_i         (clk),
        .rst_ni        (ndmreset_n),
        .dump_wave_en_o(dump_wave_en_o),
        .req_i         (slave_req[SimCtrl]),
        .gnt_o         (slave_gnt[SimCtrl]),
        .addr_i        (slave_addr[SimCtrl]),
        .we_i          (slave_we[SimCtrl]),
        .be_i          (slave_be[SimCtrl]),
        .wdata_i       (slave_wdata[SimCtrl]),
        .rvalid_o      (slave_rvalid[SimCtrl]),
        .rdata_o       (slave_rdata[SimCtrl])
    );
`endif

    obi_interconnect #(
        .MASTERS(MASTERS),
        .SLAVES(SLAVES)
    ) bus (
        .clk_i              (clk),
        .rst_ni             (ndmreset_n),
        .master_req_i       (master_req),
        .master_gnt_o       (master_gnt),
        .master_rvalid_o    (master_rvalid),
        .master_we_i        (master_we),
        .master_be_i        (master_be),
        .master_addr_i      (master_addr),
        .master_wdata_i     (master_wdata),
        .master_rdata_o     (master_rdata),
        .slave_addr_mask_i  (slave_addr_mask),
        .slave_addr_base_i  (slave_addr_base),
        .slave_req_o        (slave_req),
        .slave_gnt_i        (slave_gnt),
        .slave_rvalid_i     (slave_rvalid),
        .slave_we_o         (slave_we),
        .slave_be_o         (slave_be),
        .slave_addr_o       (slave_addr),
        .slave_wdata_o      (slave_wdata),
        .slave_rdata_i      (slave_rdata)
    );

`ifdef VERILATOR
    assign clk = clk_50m_i;
`else
    // 使用xilinx vivado中的mmcm IP进行分频
    // 输入为50MHZ，输出为25MHZ
    mmcm_main_clk u_mmcm_main_clk(
      .clk_out1(clk),
      .resetn(rst_ext_ni),
      .clk_in1(clk_50m_i)
    );
`endif

    rst_gen #(
        .RESET_FIFO_DEPTH(5)
    ) u_rst (
        .clk    (clk),
        .rst_ni (rst_ext_ni & (~ndmreset)),
        .rst_no (ndmreset_n)
    );

    assign slave_addr_mask[JtagDevice] = `DEBUG_ADDR_MASK;
    assign slave_addr_base[JtagDevice] = `DEBUG_ADDR_BASE;
    // JTAG module
    jtag_top #(

    ) u_jtag_top (
        .clk_i              (clk),
        .rst_ni             (rst_ext_ni),
        .debug_req_o        (debug_req),
        .ndmreset_o         (ndmreset),
        .halted_o           (core_halted),
`ifdef VERILATOR
        .jtag_tck_i         (sim_jtag_tck),
        .jtag_tdi_i         (sim_jtag_tdi),
        .jtag_tms_i         (sim_jtag_tms),
        .jtag_trst_ni       (sim_jtag_trstn),
        .jtag_tdo_o         (sim_jtag_tdo),
`else
        .jtag_tck_i         (jtag_TCK_pin),
        .jtag_tdi_i         (jtag_TDI_pin),
        .jtag_tms_i         (jtag_TMS_pin),
        .jtag_trst_ni       (rst_ext_ni),
        .jtag_tdo_o         (jtag_TDO_pin),
`endif
        .master_req_o       (master_req[JtagHost]),
        .master_gnt_i       (master_gnt[JtagHost]),
        .master_rvalid_i    (master_rvalid[JtagHost]),
        .master_we_o        (master_we[JtagHost]),
        .master_be_o        (master_be[JtagHost]),
        .master_addr_o      (master_addr[JtagHost]),
        .master_wdata_o     (master_wdata[JtagHost]),
        .master_rdata_i     (master_rdata[JtagHost]),
        .master_err_i       (1'b0),
        .slave_req_i        (slave_req[JtagDevice]),
        .slave_we_i         (slave_we[JtagDevice]),
        .slave_addr_i       (slave_addr[JtagDevice]),
        .slave_be_i         (slave_be[JtagDevice]),
        .slave_wdata_i      (slave_wdata[JtagDevice]),
        .slave_gnt_o        (slave_gnt[JtagDevice]),
        .slave_rvalid_o     (slave_rvalid[JtagDevice]),
        .slave_rdata_o      (slave_rdata[JtagDevice])
    );

`ifdef VERILATOR
    sim_jtag #(
        .TICK_DELAY(10),
        .PORT(9999)
    ) u_sim_jtag (
        .clock                ( clk                  ),
        .reset                ( ~rst_ext_ni          ),
        .enable               ( 1'b1                 ),
        .init_done            ( rst_ext_ni           ),
        .jtag_TCK             ( sim_jtag_tck         ),
        .jtag_TMS             ( sim_jtag_tms         ),
        .jtag_TDI             ( sim_jtag_tdi         ),
        .jtag_TRSTn           ( sim_jtag_trstn       ),
        .jtag_TDO_data        ( sim_jtag_tdo         ),
        .jtag_TDO_driven      ( 1'b1                 ),
        .exit                 ( sim_jtag_exit        )
    );

    always @ (*) begin
        if (sim_jtag_exit) begin
            $display("jtag exit...");
            $finish(2);
        end
    end
`endif

endmodule
