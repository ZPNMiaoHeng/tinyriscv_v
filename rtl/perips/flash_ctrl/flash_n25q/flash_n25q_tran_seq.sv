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

module flash_n25q_tran_seq #(
    parameter logic [7:0] SS_DELAY_CNT  = 8'd10,
    parameter logic [2:0] CLK_DIV       = 3'd5,
    parameter logic [1:0] CP_MODE       = 2'd0,
    parameter bit         MSB_FIRST     = 1'b1
    )(
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        program_init_i, // 编程中
    output logic        idle_o,         // 空闲

    input  flash_n25q_tran_pkg::flash_n25q_tran_req_t tran_req_i,
    output flash_n25q_tran_pkg::flash_n25q_tran_resp_t tran_resp_o,

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
    output logic        spi_dq3_oe_o
    );

    import flash_n25q_tran_pkg::*;

    // 状态
    localparam S_IDLE       = 8'h1;
    localparam S_SS_LOW     = 8'h2;
    localparam S_CMD        = 8'h4;
    localparam S_DATA       = 8'h8;
    localparam S_WAIT_DATA  = 8'h10;
    localparam S_ADDR       = 8'h20;
    localparam S_DUMMY      = 8'h40;
    localparam S_SS_HIGH    = 8'h80;

    logic [7:0] state_d, state_q, state_prev_q;
    logic spi_ss_level_d, spi_ss_level_q;
    logic [7:0] spi_data_in_d, spi_data_in_q;
    logic spi_read_d, spi_read_q;
    logic spi_start_d, spi_start_q;
    logic [3:0] seq_counter_d, seq_counter_q;
    logic [31:0] spi_rdata_d, spi_rdata_q;

    logic [7:0] spi_data_out;
    logic spi_data_valid;

    logic [7:0] spi_ss_delay_count;
    logic spi_ss_delay_counter_clear;
    logic spi_ss_delay_counter_enable_d, spi_ss_delay_counter_enable_q;


    always_comb begin
        state_d = state_q;
        spi_ss_delay_counter_enable_d = spi_ss_delay_counter_enable_q;
        spi_ss_delay_counter_clear = '0;
        spi_ss_level_d = spi_ss_level_q;
        spi_data_in_d = spi_data_in_q;
        spi_read_d = spi_read_q;
        spi_start_d = 1'b0;
        seq_counter_d = seq_counter_q;
        spi_rdata_d = spi_rdata_q;

        // 每传输完一个字节就将计数加1
        if (spi_data_valid) begin
            seq_counter_d = seq_counter_q + 1'b1;
        end

        case (state_q)
            S_IDLE: begin
                // SS引脚默认输出高电平
                spi_ss_level_d = 1'b1;
                if (tran_req_i.start && (tran_req_i.op != OP_NOP)) begin
                    state_d = S_SS_LOW;
                end
            end

            // 拉低SS引脚
            S_SS_LOW: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    // 清零计数器
                    spi_ss_delay_counter_clear = 1'b1;
                    // 开始计时
                    spi_ss_delay_counter_enable_d = 1'b1;
                end
                // 2倍计时时间到
                if (spi_ss_delay_count == (SS_DELAY_CNT * 2)) begin
                    spi_ss_level_d = 1'b0;
                end
                // 3倍计时时间到
                if (spi_ss_delay_count == (SS_DELAY_CNT * 3)) begin
                    spi_ss_delay_counter_clear = 1'b1;
                    spi_ss_delay_counter_enable_d = 1'b0;
                    state_d = S_CMD;
                end
            end

            // 发送command
            S_CMD: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    spi_data_in_d = tran_req_i.cmd;
                    spi_read_d = 1'b0;
                    spi_start_d = 1'b1;
                end
                if (spi_data_valid) begin
                    // 发送地址
                    if (tran_req_i.addr.be != 4'h0) begin
                        state_d = S_ADDR;
                    // 发送数据
                    end else if (tran_req_i.data.be != 4'h0) begin
                        state_d = S_DATA;
                    end else begin
                        state_d = S_SS_HIGH;
                    end
                end
            end

            // 发送地址(3个bytes)
            S_ADDR: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    seq_counter_d = '0;
                    spi_data_in_d = tran_req_i.addr.d[23:16];
                    spi_read_d = 1'b0;
                    spi_start_d = 1'b1;
                end
                if (spi_data_valid) begin
                    if (seq_counter_q == 4'd0) begin
                        spi_data_in_d = tran_req_i.addr.d[15:8];
                        spi_read_d = 1'b0;
                        spi_start_d = 1'b1;
                    end else if (seq_counter_q == 4'd1) begin
                        spi_data_in_d = tran_req_i.addr.d[7:0];
                        spi_read_d = 1'b0;
                        spi_start_d = 1'b1;
                    end else begin
                        // 需要发送dummy
                        if (tran_req_i.dummy.cnt != 4'h0) begin
                            state_d = S_DUMMY;
                        // 需要发送数据
                        end else if (tran_req_i.data.be != 4'h0) begin
                            state_d = S_DATA;
                        end else begin
                            state_d = S_SS_HIGH;
                        end
                    end
                end
            end

            // 发送dummy
            S_DUMMY: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    seq_counter_d = '0;
                    spi_data_in_d = '0;
                    // 注意: 这里设置为读方式
                    spi_read_d = 1'b1;
                    spi_start_d = 1'b1;
                end
                if (spi_data_valid) begin
                    // 发完dummy
                    if (seq_counter_q == (tran_req_i.dummy.cnt - 1)) begin
                        // 需要发送数据
                        if (tran_req_i.data.be != 4'h0) begin
                            state_d = S_DATA;
                        end else begin
                            state_d = S_SS_HIGH;
                        end
                    end else begin
                        spi_data_in_d = '0;
                        spi_read_d = 1'b1;
                        spi_start_d = 1'b1;
                    end
                end
            end

            // 等待编程数据
            S_WAIT_DATA: begin
                if (program_init_i) begin
                    if (tran_req_i.start && (tran_req_i.op == OP_WRITE)) begin
                        state_d = S_DATA;
                    end
                end else begin
                    state_d = S_SS_HIGH;
                end
            end

            // 发送或者接收数据
            S_DATA: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    seq_counter_d = '0;
                    // 读数据
                    if (tran_req_i.op == OP_READ) begin
                        spi_data_in_d = '0;
                        spi_read_d = 1'b1;
                    // 发数据
                    end else begin
                        spi_data_in_d = tran_req_i.data.d[7:0];
                        spi_read_d = 1'b0;
                    end
                    spi_start_d = 1'b1;
                end
                if (spi_data_valid) begin
                    if (spi_read_q) begin
                        // 保存接收到的数据
                        spi_rdata_d = {spi_data_out, spi_rdata_q[31:8]};
                    end
                    spi_start_d = 1'b1;
                    if (seq_counter_q == 4'd0) begin
                        if (tran_req_i.data.be[3]) begin
                            spi_data_in_d = tran_req_i.data.d[15:8];
                        end else begin
                            spi_start_d = 1'b0;
                            state_d = S_SS_HIGH;
                        end
                    end else if (seq_counter_q == 4'd1) begin
                        spi_data_in_d = tran_req_i.data.d[23:16];
                    end else if (seq_counter_q == 4'd2) begin
                        spi_data_in_d = tran_req_i.data.d[31:24];
                    end else begin
                        spi_start_d = 1'b0;
                        if (program_init_i) begin
                            state_d = S_WAIT_DATA;
                        end else begin
                            state_d = S_SS_HIGH;
                        end
                    end
                end
            end

            // 拉高SS引脚
            S_SS_HIGH: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    spi_ss_delay_counter_clear = 1'b1;
                    spi_ss_delay_counter_enable_d = 1'b1;
                end
                if (spi_ss_delay_count == SS_DELAY_CNT) begin
                    spi_ss_level_d = 1'b1;
                    spi_ss_delay_counter_clear = 1'b1;
                    spi_ss_delay_counter_enable_d = 1'b0;
                    state_d = S_IDLE;
                end
            end

            default: ;
        endcase
    end

    assign tran_resp_o.ready = ((state_q == S_IDLE) && (state_prev_q == S_SS_HIGH)) ||
                               ((state_q == S_WAIT_DATA) && (state_prev_q == S_DATA));
    assign tran_resp_o.data  = spi_rdata_q;
    assign idle_o            = (state_q == S_IDLE);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            state_prev_q <= S_IDLE;
            spi_ss_delay_counter_enable_q <= '0;
            spi_ss_level_q <= 1'b1;
            spi_data_in_q <= '0;
            spi_read_q <= '0;
            spi_start_q <= '0;
            seq_counter_q <= '0;
            spi_rdata_q <= '0;
        end else begin
            state_q <= state_d;
            state_prev_q <= state_q;
            spi_ss_delay_counter_enable_q <= spi_ss_delay_counter_enable_d;
            spi_ss_level_q <= spi_ss_level_d;
            spi_data_in_q <= spi_data_in_d;
            spi_read_q <= spi_read_d;
            spi_start_q <= spi_start_d;
            seq_counter_q <= seq_counter_d;
            spi_rdata_q <= spi_rdata_d;
        end
    end

    up_counter #(
        .WIDTH(8)
    ) spi_ss_delay_counter (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .clear_i    (spi_ss_delay_counter_clear),
        .en_i       (spi_ss_delay_counter_enable_q),
        .q_o        (spi_ss_delay_count),
        .overflow_o ()
    );

    // 以byte为单位进行传输
    spi_master u_spi_master (
        .clk_i,
        .rst_ni,
        .start_i        (spi_start_q),
        .read_i         (spi_read_q),
        .data_i         (spi_data_in_q),
        .spi_mode_i     (tran_req_i.spi_mode),
        .cp_mode_i      (CP_MODE),
        .div_ratio_i    (CLK_DIV),
        .msb_first_i    (MSB_FIRST),
        .ss_delay_cnt_i (4'd5),
        .ss_sw_ctrl_i   (1'b1),
        .ss_level_i     (spi_ss_level_q),
        .data_o         (spi_data_out),
        .ready_o        (),
        .data_valid_o   (spi_data_valid),
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
