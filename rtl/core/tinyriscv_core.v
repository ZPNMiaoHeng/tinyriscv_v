 /*                                                                      
 Copyright 2019 Blue Liang, liangkangnan@163.com
                                                                         
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

// CPU core top module
module tinyriscv_core (

    input wire clk,
    input wire rst,

    output reg over,
    output reg succ,

    output wire halt_signal,

    input wire jtag_TCK,
    input wire jtag_TMS,
    input wire jtag_TDI,
    output wire jtag_TDO

    );

    // pc_reg
	wire[`SramAddrBus] pc_pc_o;
	wire pc_re_o;

    // if_id
	wire[`SramBus] if_inst_o;
    wire[`SramAddrBus] if_inst_addr_o;

    // id
    wire id_reg1_re_o;
    wire[`RegAddrBus] id_reg1_raddr_o;
    wire id_reg2_re_o;
    wire[`RegAddrBus] id_reg2_raddr_o;
    wire[`SramBus] id_inst_o;
    wire id_inst_valid_o;
    wire id_reg_we_o;
    wire[`RegAddrBus] id_reg_waddr_o;
    wire id_sram_re_o;
    wire id_sram_we_o;
    wire[`SramAddrBus] id_pc_o;
    wire[`SramAddrBus] id_inst_addr_o;

    // ex
    wire[`RegBus] ex_reg_wdata_o;
    wire[`SramBus] ex_sram_wdata_o;
    wire[`SramAddrBus] ex_sram_raddr_o;
    wire[`SramAddrBus] ex_sram_waddr_o;
    wire ex_jump_flag_o;
    wire[`RegBus] ex_jump_addr_o;
    wire ex_int_flag_o;
    wire[`RegBus] ex_int_addr_o;
    wire[`RegBus] ex_div_dividend_o;
    wire[`RegBus] ex_div_divisor_o;
    wire ex_div_start_o;
    wire ex_hold_flag_o;
    wire[`RegBus] ex_hold_addr_o;
    wire ex_reg_we_o;
    wire[`RegAddrBus] ex_reg_waddr_o;

    // regs
    wire[`RegBus] regs_rdata1_o;
    wire[`RegBus] regs_rdata2_o;

    // sim_ram
    wire[`SramBus] ram_pc_rdata_o;
    wire[`SramBus] ram_ex_rdata_o;
    wire[`SramBus] ram_dm_rdata_o;
    wire ram_we_o;

    // div
    wire[`DoubleRegBus] div_result_o;
    wire div_ready_o;

    // timer
    wire timer_int_o;
    wire[`SramBus] timer_rdata_o;

    // jtag
    wire jtag_halt_req;
    wire jtag_reset_req;
    reg jtag_rst;
    reg[2:0] jtag_rst_cnt;
    wire jtag_mem_we;
    wire[31:0] jtag_mem_addr;
    wire[31:0] jtag_mem_wdata;

    assign halt_signal = jtag_halt_req;

    always @ (posedge clk) begin
        if (!rst) begin
            over <= 1'b1;
            succ <= 1'b1;
        end else begin
            over <= ~u_regs.regs[26];  // when = 1, run over
            succ <= ~u_regs.regs[27];  // when = 1, succ
        end
    end

    // jtag module reset logic
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            jtag_rst <= 1'b1;
            jtag_rst_cnt <= 3'h0;
        end else begin
            if (jtag_rst_cnt < 3'h5) begin
                jtag_rst <= ~jtag_rst;
                jtag_rst_cnt <= jtag_rst_cnt + 1'b1;
            end else begin
                jtag_rst <= 1'b1;
            end
        end
    end

    sim_ram u_sim_ram(
        .clk(clk),
        .rst(rst),
        .we_i(id_sram_we_o),
        .waddr_i(ex_sram_waddr_o),
        .wdata_i(ex_sram_wdata_o),
        .dm_we_i(jtag_mem_we),
        .dm_addr_i(jtag_mem_addr),
        .dm_wdata_i(jtag_mem_wdata),
        .dm_rdata_o(ram_dm_rdata_o),
        .pc_re_i(pc_re_o),
        .pc_raddr_i(pc_pc_o),
        .pc_rdata_o(ram_pc_rdata_o),
        .ex_re_i(id_sram_re_o),
        .ex_raddr_i(ex_sram_raddr_o),
        .ex_rdata_o(ram_ex_rdata_o),
        .we_o(ram_we_o),
        .rdata_i(timer_rdata_o)
    );

    pc_reg u_pc_reg(
        .clk(clk),
        .rst(rst),
        .pc_o(pc_pc_o),
        .re_o(pc_re_o),
        .hold_flag_ex_i(ex_hold_flag_o),
        .hold_addr_ex_i(ex_hold_addr_o),
        .int_flag_ex_i(ex_int_flag_o),
        .int_addr_ex_i(ex_int_addr_o),
        .dm_halt_req_i(jtag_halt_req),
        .dm_reset_req_i(jtag_reset_req),
        .jump_flag_ex_i(ex_jump_flag_o),
        .jump_addr_ex_i(ex_jump_addr_o)
    );

    regs u_regs(
        .clk(clk),
        .rst(rst),
        .we(ex_reg_we_o),
        .waddr(ex_reg_waddr_o),
        .wdata(ex_reg_wdata_o),
        .re1(id_reg1_re_o),
        .raddr1(id_reg1_raddr_o),
        .rdata1(regs_rdata1_o),
        .re2(id_reg2_re_o),
        .raddr2(id_reg2_raddr_o),
        .rdata2(regs_rdata2_o)
    );

    if_id u_if_id(
        .clk(clk),
        .rst(rst),
        .inst_i(ram_pc_rdata_o),
        .inst_addr_i(pc_pc_o),
        .inst_o(if_inst_o),
        .inst_addr_o(if_inst_addr_o),
        .jump_flag_ex_i(ex_jump_flag_o),
        .hold_flag_ex_i(ex_hold_flag_o),
        .int_flag_ex_i(ex_int_flag_o),
        .dm_halt_req_i(jtag_halt_req)
    );

    id u_id(
        .clk(clk),
        .rst(rst),
        .inst_i(if_inst_o),
        .inst_addr_o(id_inst_addr_o),
        .inst_addr_i(if_inst_addr_o),
        .jump_flag_ex_i(ex_jump_flag_o),
        .hold_flag_ex_i(ex_hold_flag_o),
        .int_flag_ex_i(ex_int_flag_o),
        .halt_flag_dm_i(jtag_halt_req),
        .reg1_re_o(id_reg1_re_o),
        .reg1_raddr_o(id_reg1_raddr_o),
        .reg2_re_o(id_reg2_re_o),
        .reg2_raddr_o(id_reg2_raddr_o),
        .inst_o(id_inst_o),
        .inst_valid_o(id_inst_valid_o),
        .reg_we_o(id_reg_we_o),
        .reg_waddr_o(id_reg_waddr_o),
        .sram_re_o(id_sram_re_o),
        .sram_we_o(id_sram_we_o)
    );

    ex u_ex(
        .clk(clk),
        .rst(rst),
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),
        .inst_valid_i(id_inst_valid_o),
        .reg_we_i(id_reg_we_o),
        .reg_waddr_i(id_reg_waddr_o),
        .reg1_rdata_i(regs_rdata1_o),
        .reg2_rdata_i(regs_rdata2_o),
        .reg_wdata_o(ex_reg_wdata_o),
        .reg_we_o(ex_reg_we_o),
        .reg_waddr_o(ex_reg_waddr_o),
        .sram_rdata_i(ram_ex_rdata_o),
        .sram_wdata_o(ex_sram_wdata_o),
        .sram_raddr_o(ex_sram_raddr_o),
        .sram_waddr_o(ex_sram_waddr_o),
        .div_dividend_o(ex_div_dividend_o),
        .div_divisor_o(ex_div_divisor_o),
        .div_ready_i(div_ready_o),
        .div_result_i(div_result_o),
        .div_start_o(ex_div_start_o),
        .hold_flag_o(ex_hold_flag_o),
        .hold_addr_o(ex_hold_addr_o),
        .jump_flag_o(ex_jump_flag_o),
        .jump_addr_o(ex_jump_addr_o),
        .int_sig_i(timer_int_o),
        .int_flag_o(ex_int_flag_o),
        .int_addr_o(ex_int_addr_o)
    );

    div u_div(
        .clk(clk),
        .rst(rst),
        .dividend_i(ex_div_dividend_o),
        .divisor_i(ex_div_divisor_o),
        .start_i(ex_div_start_o),
        .result_o(div_result_o),
        .ready_o(div_ready_o)
    );

    jtag_top u_jtag_top(
        .jtag_rst_n(jtag_rst),
        .jtag_pin_TCK(jtag_TCK),
        .jtag_pin_TMS(jtag_TMS),
        .jtag_pin_TDI(jtag_TDI),
        .jtag_pin_TDO(jtag_TDO),
        .reg_we(),
        .reg_addr(),
        .reg_wdata(),
        .reg_rdata(),
        .mem_we(jtag_mem_we),
        .mem_addr(jtag_mem_addr),
        .mem_wdata(jtag_mem_wdata),
        .mem_rdata(ram_dm_rdata_o),
        .halt_req(jtag_halt_req),
        .reset_req(jtag_reset_req)
    );

    timer u_timer(
        .clk(clk),
        .rst(rst),
        .wdata(ex_sram_wdata_o),
        .waddr(ex_sram_waddr_o),
        .raddr(ex_sram_raddr_o),
        .rdata(timer_rdata_o),
        .we(ram_we_o),
        .int_sig(timer_int_o)
    );

endmodule
