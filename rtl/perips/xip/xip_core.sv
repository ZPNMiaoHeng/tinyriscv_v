 /*                                                                      
 Copyright 2023 Blue Liang, liangkangnan@163.com
                                                                         
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

module xip_core #(
    parameter int unsigned TX_FIFO_DEPTH = 8,
    parameter int unsigned RX_FIFO_DEPTH = 8
    )(
    input  logic        clk_i,
    input  logic        rst_ni,

    // SPI引脚信号
    input  logic        spi_clk_i,
    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
    input  logic        spi_ss_i,
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

    localparam OP_READ         = 2'b00;
    localparam OP_WRITE        = 2'b01;
    localparam OP_SECTOR_ERASE = 2'b10;

    localparam S_IDLE  = 2'b01;
    localparam S_WAIT  = 2'b10;

    logic[1:0] state_d, state_q;
    logic valid_d, valid_q;
    logic[31:0] rdata_d, rdata_q;
    logic[31:0] addr;
    logic[1:0] op;
    logic[31:0] rdata;
    logic valid;

    // 去掉基地址
    assign addr  = {9'h0, addr_i[22:0]};
    // addr_i[23], 1: 表示擦除扇区; 0: 表示编程数据
    assign op = (!we_i) ? OP_READ : addr_i[23] ? OP_SECTOR_ERASE : OP_WRITE;

    assign gnt_o    = (req_i & (state_q == S_IDLE));
    assign rvalid_o = valid_q;
    assign data_o   = rdata_q;

    always_comb begin
        state_d = state_q;
        valid_d = valid_q;
        rdata_d = rdata_q;

        case (state_q)
            S_IDLE: begin
                valid_d = 1'b0;
                if (req_i) begin
                    state_d = S_WAIT;
                end
            end

            S_WAIT: begin
                if (valid) begin
                    state_d = S_IDLE;
                    valid_d = 1'b1;
                    rdata_d = rdata;
                end
            end

            default: ;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            valid_q <= '0;
            rdata_q <= '0;
        end else begin
            state_q <= state_d;
            valid_q <= valid_d;
            rdata_q <= rdata_d;
        end
    end

    xip_w25q64_ctrl u_flash(
        .clk_i,
        .rst_ni,
        .req_i,
        .op_i   (op),
        .addr_i (addr),
        .wdata_i(data_i),
        .valid_o(valid),
        .rdata_o(rdata),
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

endmodule
