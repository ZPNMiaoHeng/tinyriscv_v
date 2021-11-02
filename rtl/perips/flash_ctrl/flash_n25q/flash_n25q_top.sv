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

module flash_n25q_top (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        start_i,        // 开始操作
    input  logic        program_init_i, // 编程中
    input  logic [31:0] addr_i,         // 读或者编程地址
    input  logic [31:0] data_i,         // 编程数据
    input  logic [1:0]  op_mode_i,      // 哪一种操作
    output logic [31:0] data_o,         // 操作完成返回的数据
    output logic        ready_o,        // 操作完成
    output logic        idle_o,         // 空闲
    output logic        write_error_o,  // 空闲

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
    import flash_n25q_pkg::*;

    // 状态
    localparam S_IDLE                   = 14'h1;     // 主状态
    localparam S_READ                   = 14'h2;     // 主状态
    localparam S_PROGRAM                = 14'h4;     // 主状态
    localparam S_ERASE                  = 14'h8;     // 主状态
    localparam S_WRITE_ENABLE           = 14'h10;    // 子主状态
    localparam S_WRITE_DISABLE          = 14'h20;    // 子主状态
    localparam S_CHECK_BUSY             = 14'h40;    // 子主状态
    localparam S_QSPI_INIT              = 14'h80;    // 主状态
    localparam S_MULTIIO_READ_ID        = 14'h100;   // 子主状态
    localparam S_WRITE_DUMMY_REG        = 14'h200;   // 子主状态
    localparam S_WRITE_QSPI_REG         = 14'h400;   // 子主状态
    localparam S_WAIT_DATA              = 14'h800;   // 子主状态
    localparam S_READ_FLAG_STATUS_REG   = 14'h1000;  // 子主状态
    localparam S_CLEAR_FLAG_STATUS_REG  = 14'h2000;  // 子主状态

    logic [13:0] state_d, state_q, state_prev_q, return_state_d, return_state_q;
    logic [1:0] spi_mode_d, spi_mode_q;
    logic [31:0] rdata_d, rdata_q;
    logic write_error_d, write_error_q;

    logic tran_idle;

    flash_n25q_tran_pkg::flash_n25q_tran_req_t tran_req_d, tran_req_q;
    flash_n25q_tran_pkg::flash_n25q_tran_resp_t tran_resp;


    always_comb begin
        state_d = state_q;
        tran_req_d = tran_req_q;
        tran_req_d.start = 1'b0;
        return_state_d = return_state_q;
        spi_mode_d = spi_mode_q;
        rdata_d = rdata_q;
        write_error_d = write_error_q;

        case (state_q)
            S_IDLE: begin
                if (start_i) begin
                    if (op_mode_i == 2'b00) begin
                        state_d = S_READ;
                    end else if (op_mode_i == 2'b01) begin
                        state_d = S_PROGRAM;
                    end else if (op_mode_i == 2'b10) begin
                        state_d = S_ERASE;
                    end else begin
                        // 当前不为QSPI模式时才初始化
                        if (spi_mode_q != MODE_QUAD_SPI) begin
                            state_d = S_QSPI_INIT;
                        end
                    end
                end
            end

            // 读数据
            S_READ: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    if (spi_mode_q == MODE_QUAD_SPI) begin
                        tran_req_d.cmd = CMD_FAST_READ;
                    end else begin
                        tran_req_d.cmd = CMD_READ;
                    end
                    tran_req_d.addr.d = addr_i;
                    tran_req_d.addr.be = 4'b0111;
                    tran_req_d.dummy.d = '0;
                    if (spi_mode_q == MODE_QUAD_SPI) begin
                        tran_req_d.dummy.cnt = {1'b0, DUMMY_CNT[3:1]};
                    end else begin
                        tran_req_d.dummy.cnt = '0;
                    end
                    tran_req_d.data.d = '0;
                    // 以word为单位，每次操作最多读一个word
                    tran_req_d.data.be = 4'b1111;
                    tran_req_d.op = OP_READ;
                // 读完成
                end else if (tran_resp.ready) begin
                    rdata_d = tran_resp.data;
                    state_d = S_IDLE;
                end
            end

            // 写使能(命令)
            S_WRITE_ENABLE: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_WRITE_ENABLE;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = 4'b0000;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0000;
                    tran_req_d.op = OP_WRITE;
                end else begin
                    if (tran_resp.ready) begin
                        state_d = return_state_q;
                    end
                end
            end

            // 写失能命令
            S_WRITE_DISABLE: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_WRITE_DISABLE;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = 4'b0000;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0000;
                    tran_req_d.op = OP_WRITE;
                end else begin
                    if (tran_resp.ready) begin
                        state_d = return_state_q;
                    end
                end
            end

            // 检查ready位，直到ready位为1才返回
            S_CHECK_BUSY: begin
                // 从其他状态进来，或者ready位为0
                if ((state_q ^ state_prev_q) ||
                    (tran_resp.ready && (~tran_resp.data[7]))) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_READ_FLAG_STATUS_REG;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = '0;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0001;
                    tran_req_d.op = OP_READ;
                end else begin
                    if (tran_resp.ready && (tran_resp.data[7])) begin
                        state_d = return_state_q;
                        write_error_d = tran_resp.data[5] | tran_resp.data[4];
                    end
                end
            end

            S_CLEAR_FLAG_STATUS_REG: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_CLEAR_FLAG_STATUS_REG;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = 4'b0000;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0000;
                    tran_req_d.op = OP_WRITE;
                end else begin
                    if (tran_resp.ready) begin
                        state_d = return_state_q;
                    end
                end
            end

            S_WAIT_DATA: begin
                if (program_init_i) begin
                    if (start_i && (op_mode_i == 2'b01)) begin
                        state_d = S_PROGRAM;
                    end
                end else begin
                    if (tran_idle) begin
                        state_d = S_CHECK_BUSY;
                        return_state_d = S_PROGRAM;
                    end
                end
            end

            // 编程
            S_PROGRAM: begin
                if (state_prev_q == S_IDLE) begin
                    state_d = S_WRITE_ENABLE;
                    return_state_d = S_PROGRAM;
                end else if ((state_prev_q == S_WRITE_ENABLE) ||
                             (state_prev_q == S_WAIT_DATA)) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_PAGE_PROG;
                    tran_req_d.addr.d = addr_i;
                    tran_req_d.addr.be = 4'b0111;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = data_i;
                    tran_req_d.data.be = 4'b1111;
                    tran_req_d.op = OP_WRITE;
                end else if (state_prev_q == S_PROGRAM) begin
                    if (tran_resp.ready) begin
                        if (program_init_i) begin
                            state_d = S_WAIT_DATA;
                            return_state_d = S_PROGRAM;
                        end else begin
                            state_d = S_CHECK_BUSY;
                            return_state_d = S_PROGRAM;
                        end
                    end
                end else if (state_prev_q == S_CHECK_BUSY) begin
                    if (write_error_q) begin
                        state_d = S_CLEAR_FLAG_STATUS_REG;
                        return_state_d = S_PROGRAM;
                    end else begin
                        state_d = S_IDLE;
                    end
                end else if (state_prev_q == S_CLEAR_FLAG_STATUS_REG) begin
                    state_d = S_IDLE;
                end
            end

            // 擦除(子扇区)
            S_ERASE: begin
                if (state_prev_q == S_IDLE) begin
                    state_d = S_WRITE_ENABLE;
                    return_state_d = S_ERASE;
                end else if (state_prev_q == S_WRITE_ENABLE) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = spi_mode_q;
                    tran_req_d.cmd = CMD_SUBSECTOR_ERASE;
                    tran_req_d.addr.d = addr_i;
                    tran_req_d.addr.be = 4'b0111;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0000;
                    tran_req_d.op = OP_WRITE;
                end else if (state_prev_q == S_ERASE) begin
                    if (tran_resp.ready) begin
                        state_d = S_CHECK_BUSY;
                        return_state_d = S_ERASE;
                    end
                end else if (state_prev_q == S_CHECK_BUSY) begin
                    if (write_error_q) begin
                        state_d = S_CLEAR_FLAG_STATUS_REG;
                        return_state_d = S_ERASE;
                    end else begin
                        state_d = S_IDLE;
                    end
                end else if (state_prev_q == S_CLEAR_FLAG_STATUS_REG) begin
                    state_d = S_IDLE;
                end
            end

            // QSPI模式读ID
            S_MULTIIO_READ_ID: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    // 用QSPI模式去try
                    tran_req_d.spi_mode = MODE_QUAD_SPI;
                    tran_req_d.cmd = CMD_MULTIO_READ_ID;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = '0;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = '0;
                    tran_req_d.data.be = 4'b0001;
                    tran_req_d.op = OP_READ;
                end else begin
                    if (tran_resp.ready) begin
                        // 读到的ID正确
                        if (tran_resp.data[7:0] == MANF_ID) begin
                            spi_mode_d = MODE_QUAD_SPI;
                            state_d = S_IDLE;
                        end else begin
                            state_d = return_state_q;
                        end
                    end
                end
            end

            // 设置dummy数
            S_WRITE_DUMMY_REG: begin
                // 从其他状态进来
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = MODE_STAND_SPI;
                    tran_req_d.cmd = CMD_WRITE_DUMMY_REG;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = 4'b0000;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = {24'h0, DUMMY_CNT, 4'b1011};
                    tran_req_d.data.be = 4'b0001;
                    tran_req_d.op = OP_WRITE;
                end else begin
                    if (tran_resp.ready) begin
                        state_d = return_state_q;
                    end
                end
            end

            // 设置为QSPI模式
            S_WRITE_QSPI_REG: begin
                if (state_q ^ state_prev_q) begin
                    tran_req_d.start = 1'b1;
                    tran_req_d.spi_mode = MODE_STAND_SPI;
                    tran_req_d.cmd = CMD_WRITE_QSPI_REG;
                    tran_req_d.addr.d = '0;
                    tran_req_d.addr.be = 4'b0000;
                    tran_req_d.dummy.d = '0;
                    tran_req_d.dummy.cnt = '0;
                    tran_req_d.data.d = {24'h0, 8'b01011111};
                    tran_req_d.data.be = 4'b0001;
                    tran_req_d.op = OP_WRITE;
                end else begin
                    if (tran_resp.ready) begin
                        state_d = return_state_q;
                    end
                end
            end

            // QSPI初始化
            S_QSPI_INIT: begin
                if (state_prev_q == S_IDLE) begin
                    state_d = S_MULTIIO_READ_ID;
                    return_state_d = S_QSPI_INIT;
                end else if (state_prev_q == S_MULTIIO_READ_ID) begin
                    state_d = S_WRITE_ENABLE;
                    return_state_d = S_QSPI_INIT;
                end else if (state_prev_q == S_WRITE_ENABLE) begin
                    //state_d = S_WRITE_DUMMY_REG;
                    state_d = S_WRITE_QSPI_REG;
                    return_state_d = S_QSPI_INIT;
                end else if (state_prev_q == S_WRITE_DUMMY_REG) begin
                    state_d = S_WRITE_QSPI_REG;
                    return_state_d = S_QSPI_INIT;
                end else if (state_prev_q == S_WRITE_QSPI_REG) begin
                    spi_mode_d = MODE_QUAD_SPI;
                    state_d = S_IDLE;
                end
            end

            default: ;
        endcase
    end

    assign ready_o = ((state_q == S_IDLE) && (state_prev_q != S_IDLE)) ||
                     ((state_q == S_WAIT_DATA) && (state_prev_q == S_PROGRAM));
    assign idle_o  = (state_q == S_IDLE) && tran_idle;
    assign data_o  = rdata_q;
    assign write_error_o = write_error_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            state_prev_q <= S_IDLE;
            tran_req_q <= '0;
            return_state_q <= S_IDLE;
            spi_mode_q <= MODE_STAND_SPI;
            rdata_q <= '0;
            write_error_q <= '0;
        end else begin
            state_q <= state_d;
            state_prev_q <= state_q;
            tran_req_q <= tran_req_d;
            return_state_q <= return_state_d;
            spi_mode_q <= spi_mode_d;
            rdata_q <= rdata_d;
            write_error_q <= write_error_d;
        end
    end

    flash_n25q_tran_seq #(
        .SS_DELAY_CNT(SS_DELAY_CNT),
`ifdef VERILATOR
        .CLK_DIV(3'd1),
`else
        .CLK_DIV(3'd5),
`endif
        .CP_MODE(CPOL_0_CPHA_0),
        .MSB_FIRST(1'b1)
    ) u_flash_n25q_tran_seq (
        .clk_i,
        .rst_ni,
        .program_init_i,
        .tran_req_i  (tran_req_q),
        .tran_resp_o (tran_resp),
        .idle_o      (tran_idle),
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
