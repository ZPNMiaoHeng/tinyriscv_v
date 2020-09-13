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

`define DM_RESP_VALID     1'b1
`define DM_RESP_INVALID   1'b0
`define DTM_REQ_VALID     1'b1
`define DTM_REQ_INVALID   1'b0

`define DTM_OP_NOP        2'b00
`define DTM_OP_READ       2'b01
`define DTM_OP_WRITE      2'b10


module jtag_dm #(
    parameter DMI_ADDR_BITS = 6,
    parameter DMI_DATA_BITS = 32,
    parameter DMI_OP_BITS = 2)(

    clk,
    rst_n,
    dtm_req_valid_i,
    dtm_req_data_i,

    dm_is_busy_o,
    dm_resp_data_o,
    dm_resp_ready_i,

    dm_reg_we_o,
    dm_reg_addr_o,
    dm_reg_wdata_o,
    dm_reg_rdata_i,
    dm_mem_we_o,
    dm_mem_addr_o,
    dm_mem_wdata_o,
    dm_mem_rdata_i,
    dm_op_req_o,

    dm_halt_req_o,
    dm_reset_req_o

    );

    parameter DM_RESP_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    parameter DTM_REQ_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    parameter SHIFT_REG_BITS = DTM_REQ_BITS;

    // 输入输出信号
    input wire clk;
    input wire rst_n;
    input wire dtm_req_valid_i;
    input wire[DTM_REQ_BITS-1:0] dtm_req_data_i;
    output wire dm_is_busy_o;
    output wire[DM_RESP_BITS-1:0] dm_resp_data_o;
    output wire dm_reg_we_o;
    output wire[4:0] dm_reg_addr_o;
    output wire[31:0] dm_reg_wdata_o;
    input wire[31:0] dm_reg_rdata_i;
    output wire dm_mem_we_o;
    output wire[31:0] dm_mem_addr_o;
    output wire[31:0] dm_mem_wdata_o;
    input wire[31:0] dm_mem_rdata_i;
    output wire dm_op_req_o;
    output wire dm_halt_req_o;
    output wire dm_reset_req_o;
    input wire dm_resp_ready_i;

    localparam STATE_IDLE  = 3'b001;
    localparam STATE_EXE   = 3'b010;
    localparam STATE_RESP  = 3'b100;

    reg[2:0] state;
    reg[2:0] state_next;

    // DM模块寄存器
    reg[31:0] dcsr;
    reg[31:0] dmstatus;
    reg[31:0] dmcontrol;
    reg[31:0] hartinfo;
    reg[31:0] abstractcs;
    reg[31:0] data0;
    reg[31:0] sbcs;
    reg[31:0] sbaddress0;
    reg[31:0] sbdata0;
    reg[31:0] command;

    // DM模块寄存器地址
    localparam DCSR = 16'h7b0;
    localparam DMSTATUS = 6'h11;
    localparam DMCONTROL = 6'h10;
    localparam HARTINFO = 6'h12;
    localparam ABSTRACTCS = 6'h16;
    localparam DATA0 = 6'h04;
    localparam SBCS = 6'h38;
    localparam SBADDRESS0 = 6'h39;
    localparam SBDATA0 = 6'h3C;
    localparam COMMAND = 6'h17;
    localparam DPC = 16'h7b1;

    localparam OP_SUCC = 2'b00;

    // 当前状态切换
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
        end else begin
            state <= state_next;
        end
    end

    // 下一个状态切换
    always @ (*) begin
        case (state)
            STATE_IDLE: begin
                if (dtm_req_valid_i == `DTM_REQ_VALID) begin
                    state_next = STATE_EXE;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_EXE: begin
                if (access_core) begin
                    state_next = STATE_RESP;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_RESP: begin
                if (dm_resp_ready_i == 1'b1) begin
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_RESP;
                end
            end
        endcase
    end

    reg[31:0] mem_rdata;
    reg[31:0] reg_rdata;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_rdata <= 32'h0;
            reg_rdata <= 32'h0;
        end else begin
            if (state == STATE_RESP && dm_resp_ready_i == 1'b1) begin
                mem_rdata <= dm_mem_rdata_i;
                reg_rdata <= dm_reg_rdata_i;
            end
        end
    end

    reg[DTM_REQ_BITS-1:0] dtm_req_data;

    // 锁存jtag_dirver模块传过来的数据
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dtm_req_data <= {DTM_REQ_BITS{1'b0}};
        end else begin
            if ((state == STATE_IDLE) && (dtm_req_valid_i == `DTM_REQ_VALID)) begin
                dtm_req_data <= dtm_req_data_i;
            end
        end
    end

    wire[DMI_OP_BITS-1:0] op = dtm_req_data[DMI_OP_BITS-1:0];
    wire[DMI_DATA_BITS-1:0] data = dtm_req_data[DMI_DATA_BITS+DMI_OP_BITS-1:DMI_OP_BITS];
    wire[DMI_ADDR_BITS-1:0] address = dtm_req_data[DTM_REQ_BITS-1:DMI_DATA_BITS+DMI_OP_BITS];

    wire op_write = (op == `DTM_OP_WRITE);
    wire op_read = (op == `DTM_OP_READ);
    wire op_nop = (op == `DTM_OP_NOP);
    wire access_dmstatus = (address == DMSTATUS);
    wire access_dmcontrol = (address == DMCONTROL);
    wire access_hartinfo = (address == HARTINFO);
    wire access_abstractcs = (address == ABSTRACTCS);
    wire access_data0 = (address == DATA0);
    wire access_sbcs = (address == SBCS);
    wire access_sbaddress0 = (address == SBADDRESS0);
    wire access_sbdata0 = (address == SBDATA0);
    wire access_command = (address == COMMAND);

    wire access_core = (~op_nop) & (~access_dmcontrol) & (~access_dmstatus) & (~access_hartinfo);

    reg dm_op_req;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dm_op_req <= 1'b0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (access_core) begin
                        dm_op_req <= 1'b1;
                    end
                end
                STATE_IDLE: begin
                    dm_op_req <= 1'b0;
                end
            endcase
        end
    end

    assign dm_op_req_o = dm_op_req;

    reg[31:0] rdata;
    // 返回数据给jtag driver模块
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 32'h0;
        end else begin
            case (state)
                STATE_EXE: begin
                    case (op)
                        `DTM_OP_READ: begin
                            case (address)
                                DMSTATUS: begin
                                    rdata <= dmstatus;
                                end
                                DMCONTROL: begin
                                    rdata <= dmcontrol;
                                end
                                HARTINFO: begin
                                    rdata <= 32'h0;
                                end
                                SBCS: begin
                                    rdata <= sbcs;
                                end
                                ABSTRACTCS: begin
                                    rdata <= abstractcs;
                                end
                                DATA0: begin
                                    if (is_read_reg == 1'b1) begin
                                        rdata <= reg_rdata;
                                    end else begin
                                        rdata <= data0;
                                    end
                                end
                                SBDATA0: begin
                                    rdata <= mem_rdata;
                                end
                                default: begin
                                    rdata <= 32'h0;
                                end
                            endcase
                        end
                        default: begin
                            rdata <= 32'h0;
                        end
                    endcase
                end
            endcase
        end
    end

    assign dm_resp_data_o = {address, rdata, OP_SUCC};

    wire dm_reset = (state == STATE_EXE) & op_write & (access_dmcontrol) & (data[0] == 1'b0);

    // dmcontrol
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmcontrol <= 32'h0;
        end else if (dm_reset) begin
            dmcontrol <= data;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_dmcontrol) begin
                        dmcontrol <= (data & ~(32'h3fffc0)) | 32'h10000;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    // dmstatus
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            dmstatus <= 32'h430c82;  // not halted, all running
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_dmcontrol) begin
                        // halt
                        if (data[31] == 1'b1) begin
                            // clear ALLRUNNING ANYRUNNING and set ALLHALTED
                            dmstatus <= {dmstatus[31:12], 4'h3, dmstatus[7:0]};
                        // resume
                        end else if (dm_halt_req == 1'b1 && data[30] == 1'b1) begin
                            // set ALLRUNNING ANYRUNNING and clear ALLHALTED
                            dmstatus <= {dmstatus[31:12], 4'hc, dmstatus[7:0]};
                        end
                    end else if (core_reset) begin
                        // set ALLRUNNING ANYRUNNING and clear ALLHALTED
                        dmstatus <= {dmstatus[31:12], 4'hc, dmstatus[7:0]};
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    wire access_reg = (data[31:24] == 8'h0);

    // command
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            abstractcs <= 32'h1000003;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_command & access_reg) begin
                        if (data[22:20] > 3'h2) begin
                            abstractcs <= abstractcs | 32'h200;
                        end else begin
                            abstractcs <= abstractcs & (~(3'h7 << 8));
                        end
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    // data0
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            data0 <= 32'h0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_data0) begin
                        data0 <= data;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    // sbcs
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            sbcs <= 32'h20040404;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_sbcs) begin
                        sbcs <= data;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    // sbaddress0
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            sbaddress0 <= 32'h0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_sbaddress0) begin
                        sbaddress0 <= data;
                    end
                    if ((op_write | op_read) & access_sbdata0 & (sbcs[16] == 1'b1)) begin
                        sbaddress0 <= sbaddress0 + 4;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    // sbdata0
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            sbdata0 <= 32'h0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_sbdata0) begin
                        sbdata0 <= data;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    reg dm_halt_req;

    // dm_halt_req
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            dm_halt_req <= 1'b0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_dmcontrol) begin
                        // halt
                        if (data[31] == 1'b1) begin
                            dm_halt_req <= 1'b1;
                        // resume
                        end else if ((dm_halt_req == 1'b1) && (data[30] == 1'b1)) begin
                            dm_halt_req <= 1'b0;
                        end
                    end else if (core_reset) begin
                        dm_halt_req <= 1'b0;
                    end
                end
                default: begin
                    
                end
            endcase
        end
    end

    assign dm_halt_req_o = dm_halt_req;

    wire core_reset = (state == STATE_EXE) & op_write & access_command & access_reg & (data[22:20] <= 3'h2) &
                      (data[18] == 1'b0) & (data[16] == 1'b1) & (data[15:0] == DPC);

    assign dm_reset_req_o = core_reset;

    reg[31:0] dm_mem_addr;
    reg[31:0] dm_mem_wdata;
    reg dm_mem_we;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            dm_mem_addr <= 32'h0;
            dm_mem_wdata <= 32'h0;
            dm_mem_we <= 1'b0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write) begin
                        case (address)
                            SBDATA0: begin
                                dm_mem_addr <= sbaddress0;
                                dm_mem_wdata <= data;
                                dm_mem_we <= 1'b1;
                            end
                            SBADDRESS0: begin
                                if (sbcs[20] == 1'b1) begin
                                    dm_mem_addr <= data;
                                end
                            end
                        endcase
                    end else if (op_read) begin
                        if (access_sbdata0 & (sbcs[15] == 1'b1)) begin
                            dm_mem_addr <= sbaddress0 + 4;
                        end
                    end
                end
                STATE_IDLE: begin
                    dm_mem_we <= 1'b0;
                end
            endcase
        end
    end

    assign dm_mem_addr_o = dm_mem_addr;
    assign dm_mem_wdata_o = dm_mem_wdata;
    assign dm_mem_we_o = dm_mem_we;

    reg dm_reg_we;
    reg[4:0] dm_reg_addr;
    reg[31:0] dm_reg_wdata;
    reg is_read_reg;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n | dm_reset) begin
            dm_reg_we <= 1'b0;
            dm_reg_addr <= 5'h0;
            dm_reg_wdata <= 32'h0;
            is_read_reg <= 1'b0;
        end else begin
            case (state)
                STATE_EXE: begin
                    if (op_write & access_command) begin
                        // 访问寄存器
                        if (access_reg & (data[22:20] <= 3'h2)) begin
                            // 读或写, 目前只支持通用寄存器读写
                            if ((data[18] == 1'b0) & (data[15:0] < 16'h1020) & (data[15:0] != DPC)) begin
                                dm_reg_addr <= data[15:0] - 16'h1000;
                                // 读
                                if (data[16] == 1'b0) begin
                                    is_read_reg <= 1'b1;
                                // 写
                                end else begin
                                    dm_reg_we <= 1'b1;
                                    dm_reg_wdata <= data0;
                                end
                            end
                        end
                    end else if (op_read & access_data0) begin
                        is_read_reg <= 1'b0;
                    end
                end
                STATE_IDLE: begin
                    dm_reg_we <= 1'b0;
                end
            endcase
        end
    end

    assign dm_reg_we_o = dm_reg_we;
    assign dm_reg_addr_o = dm_reg_addr;
    assign dm_reg_wdata_o = dm_reg_wdata;

    assign dm_is_busy_o = (state != STATE_IDLE);

endmodule
