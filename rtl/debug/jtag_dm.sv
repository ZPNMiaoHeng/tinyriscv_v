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

`include "jtag_def.sv"

module jtag_dm #(
    parameter DMI_ADDR_BITS  = 6,
    parameter DMI_DATA_BITS  = 32,
    parameter DMI_OP_BITS    = 2,
    localparam DMI_REQ_BITS  = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS,
    localparam DMI_RESP_BITS = DMI_REQ_BITS
    )(

    input wire                      clk,
    input wire                      rst_n,

    // from DMI
    input  wire [DMI_REQ_BITS-1:0]  dmi_data_i,
    input  wire                     dmi_valid_i,
    output wire                     dm_ready_o,

    // to DMI
    output wire [DMI_RESP_BITS-1:0] dm_data_o,
    output wire                     dm_valid_o,
    input  wire                     dmi_ready_i,

    output wire                     debug_req_o,
    output wire                     ndmreset_o,

    // jtag access mem devices(DM as master)
    output wire                     master_req_o,
    input  wire                     master_gnt_i,
    input  wire                     master_rvalid_i,
    output wire                     master_we_o,
    output wire [3:0]               master_be_o,
    output wire [31:0]              master_addr_o,
    output wire [31:0]              master_wdata_o,
    input  wire [31:0]              master_rdata_i,
    input  wire                     master_err_i,

    // core fetch instr or mem(DM as slave)
    input  wire                     slave_req_i,
    input  wire                     slave_we_i,
    input  wire [31:0]              slave_addr_i,
    input  wire [3:0]               slave_be_i,
    input  wire [31:0]              slave_wdata_i,
    output wire [31:0]              slave_rdata_o

    );

    localparam HARTINFO = {8'h0, 4'h2, 3'b0, 1'b1, `DataCount, `DataAddr};

    wire halted;
    wire resumeack;
    wire sbbusy;
    wire[2:0] sberror;
    wire[DMI_OP_BITS-1:0] dm_op;
    wire[DMI_ADDR_BITS-1:0] dm_op_addr;
    wire[DMI_DATA_BITS-1:0] dm_op_data;

    reg havereset_d, havereset_q;
    reg clear_resumeack;
    reg sbaddress_write_valid;
    reg sbdata_write_valid;
    reg sbdata_read_valid;
    reg[31:0] sbcs;
    reg[31:0] dm_resp_data_d, dm_resp_data_q;
    wire[31:0] sba_sbaddress;
    wire[31:0] dm_sbaddress;
    wire resumereq;
    wire cmdbusy;
    wire sbdata_valid;
    wire[31:0] sbdata;
    wire[19:0] hartsel;

    // DM regs
    reg[31:0] dmstatus;
    reg[31:0] dmcontrol_d, dmcontrol_q;
    reg[31:0] abstractcs;
    reg[31:0] sbcs_d, sbcs_q;
    reg[31:0] sbdata0_d, sbdata0_q;
    reg[31:0] sbaddress0_d, sbaddress0_q;
    reg[31:0] command_d, command_q;
    reg[31:0] data0_d, data0_q;
    reg[2:0] cmderr_d, cmderr_q;

    assign dm_sbaddress = sbaddress0_q;

    assign hartsel = {dmcontrol_q[`Hartselhi], dmcontrol_q[`Hartsello]};

    assign dm_op      = dmi_data_i[DMI_OP_BITS-1:0];
    assign dm_op_addr = dmi_data_i[DMI_REQ_BITS-1:DMI_DATA_BITS+DMI_OP_BITS];
    assign dm_op_data = dmi_data_i[DMI_DATA_BITS+DMI_OP_BITS-1:DMI_OP_BITS];


    localparam S_REQ  = 2'b01;
    localparam S_RESP = 2'b10; 

    reg[2:0] req_state_d, req_state_q;
    reg dm_valid_d, dm_valid_q;

    // response FSM
    always @ (*) begin
        req_state_d = req_state_q;
        dm_valid_d = dm_valid_q;

        case (req_state_q)
            S_REQ: begin
                if (dmi_valid_i & dm_ready_o) begin
                    req_state_d = S_RESP;
                    dm_valid_d = 1'b1;
                end
            end

            S_RESP: begin
                if (dmi_ready_i) begin
                    dm_valid_d = 1'b0;
                    req_state_d = S_REQ;
                end
            end

            default:;
        endcase
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_state_q <= S_REQ;
            dm_valid_q <= 1'b0;
        end else begin
            req_state_q <= req_state_d;
            dm_valid_q <= dm_valid_d;
        end
    end

    // we always ready to receive dmi request
    assign dm_ready_o = 1'b1;
    assign dm_valid_o = dm_valid_q;
    assign dm_data_o  = {{DMI_ADDR_BITS{1'b0}}, dm_resp_data_q, 2'b00};  // response successfully


    // DMI read or write operation
    always @ (*) begin
        // dmstatus
        dmstatus = 32'h0;
        dmstatus[`Version]        = `DbgVersion013;
        dmstatus[`Authenticated]  = 1'b1;
        dmstatus[`Allresumeack]   = resumeack;
        dmstatus[`Anyresumeack]   = resumeack;
        dmstatus[`Allhavereset]   = havereset_q;
        dmstatus[`Anyhavereset]   = havereset_q;
        dmstatus[`Allhalted]      = halted;
        dmstatus[`Anyhalted]      = halted;
        dmstatus[`Allrunning]     = ~halted;
        dmstatus[`Anyrunning]     = ~halted;
        dmstatus[`Allnonexistent] = hartsel > 20'h0;
        dmstatus[`Anynonexistent] = hartsel > 20'h0;

        // abstractcs
        cmderr_d = cmderr_q;
        abstractcs = 32'h0;
        abstractcs[`Datacount]   = `DataCount;
        abstractcs[`Progbufsize] = `ProgBufSize;
        abstractcs[`Busy]        = cmdbusy;
        abstractcs[`Cmderr]      = cmderr_q;

        havereset_d = havereset_q;
        sbaddress0_d = sba_sbaddress;
        dmcontrol_d = dmcontrol_q;
        clear_resumeack = 1'b0;
        sbaddress_write_valid = 1'b0;
        sbdata_write_valid = 1'b0;
        sbdata_read_valid = 1'b0;
        sbcs = 32'h0;

        data0_d = data0_q;
        sbcs_d = sbcs_q;
        sbdata0_d = sbdata0_q;
        dm_resp_data_d = dm_resp_data_q;

        if (dmi_valid_i & dm_ready_o) begin
            // read
            if (dm_op == `DMI_OP_READ) begin
                case (dm_op_addr)
                    `DMStatus  :dm_resp_data_d = dmstatus;
                    `DMControl :dm_resp_data_d = dmcontrol_q;
                    `Hartinfo  :dm_resp_data_d = HARTINFO;
                    `SBCS      :dm_resp_data_d = sbcs_q;
                    `AbstractCS:dm_resp_data_d = abstractcs;
                    `SBAddress0:dm_resp_data_d = sbaddress0_q;
                    `SBData0   : begin
                        if (sbbusy || sbcs_q[`Sbbusyerror]) begin
                            sbcs_d[`Sbbusyerror] = 1'b1;
                        end else begin
                            sbdata_read_valid = (sbcs_q[`Sberror] == 3'b0);
                            dm_resp_data_d = sbdata0_q;
                        end
                    end
                    default:;
                endcase
            // write
            end else if (dm_op == `DMI_OP_WRITE) begin
                case (dm_op_addr)
                    `DMControl: begin
                        dmcontrol_d = dm_op_data;
                        if (dmcontrol_d[`Ackhavereset]) begin
                            havereset_d = 1'b0;
                        end
                    end

                    `Data0: begin
                        data0_d = dm_op_data;
                    end

                    `SBCS: begin
                        if (sbbusy) begin
                            sbcs_d[`Sbbusyerror] = 1'b1;
                        end else begin
                            sbcs = dm_op_data;
                            sbcs_d = dm_op_data;
                            // write 1 to clear
                            sbcs_d[`Sbbusyerror] = sbcs_q[`Sbbusyerror] & (~sbcs[`Sbbusyerror]);
                            sbcs_d[`Sberror]     = sbcs_q[`Sberror]     & (~sbcs[`Sberror]);
                        end
                    end

                    `SBAddress0: begin
                        if (sbbusy | sbcs_q[`Sbbusyerror]) begin
                            sbcs_d[`Sbbusyerror] = 1'b1;
                        end else begin
                            sbaddress0_d = dm_op_data;
                            sbaddress_write_valid = (sbcs_q[`Sberror] == 3'b0);
                        end
                    end

                    `SBData0: begin
                        if (sbbusy | sbcs_q[`Sbbusyerror]) begin
                            sbcs_d[`Sbbusyerror] = 1'b1;
                        end else begin
                            sbdata0_d = dm_op_data;
                            sbdata_write_valid = (sbcs_q[`Sberror] == 3'b0);
                        end
                    end

                    `AbstractCS: begin
                        
                    end

                    default:;
                endcase
            // nop
            end
        end

        // dmcontrol
        dmcontrol_d[`Hasel]           = 1'b0;
        dmcontrol_d[`Hartreset]       = 1'b0;
        dmcontrol_d[`Setresethaltreq] = 1'b0;
        dmcontrol_d[`Clrresethaltreq] = 1'b0;
        dmcontrol_d[`Ackhavereset]    = 1'b0;
        // 收到resume请求后清resume应答
        if (!dmcontrol_q[`Resumereq] && dmcontrol_d[`Resumereq]) begin
            clear_resumeack = 1'b1;
        end
        // 发出resume后并且收到应答
        if (dmcontrol_q[`Resumereq] && resumeack) begin
            // 清resume请求位
            dmcontrol_d[`Resumereq] = 1'b0;
        end

        // sbcs
        sbcs_d[`Sbversion]            = 3'd1;
        sbcs_d[`Sbbusy]               = sbbusy;
        sbcs_d[`Sberror]              = sberror;
        sbcs_d[`Sbasize]              = 7'd32;
        sbcs_d[`Sbaccess128]          = 1'b0;
        sbcs_d[`Sbaccess64]           = 1'b0;
        sbcs_d[`Sbaccess32]           = 1'b1;
        sbcs_d[`Sbaccess16]           = 1'b0;
        sbcs_d[`Sbaccess8]            = 1'b0;
        sbcs_d[`Sbaccess]             = 3'd2;

        if (sbdata_valid) begin
            sbdata0_d = sbdata;
        end

        // set the havereset flag when we did a ndmreset
        if (ndmreset_o) begin
            havereset_d = 1'b1;
        end
    end


    assign debug_req_o = dmcontrol_q[`Haltreq];
    assign ndmreset_o  = dmcontrol_q[`Ndmreset];
    assign resumereq   = dmcontrol_q[`Resumereq];


    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmcontrol_q <= 32'h0;
            havereset_q <= 1'b1;
            data0_q <= 32'h0;
            sbcs_q <= 32'h0;
            sbaddress0_q <= 32'h0;
            sbdata0_q <= 32'h0;
            dm_resp_data_q <= 32'h0;
            cmderr_q <= 3'h0;
        end else begin
            if (!dmcontrol_q[`Dmactive]) begin
                dmcontrol_q[`Haltreq] <= 1'b0;
                dmcontrol_q[`Resumereq] <= 1'b0;
                dmcontrol_q[`Hartreset] <= 1'b0;
                dmcontrol_q[`Ackhavereset] <= 1'b0;
                dmcontrol_q[`Hasel] <= 1'b0;
                dmcontrol_q[`Hartsello] <= 10'b0;
                dmcontrol_q[`Hartselhi] <= 10'b0;
                dmcontrol_q[`Setresethaltreq] <= 1'b0;
                dmcontrol_q[`Clrresethaltreq] <= 1'b0;
                dmcontrol_q[`Ndmreset] <= 1'b0;
                dmcontrol_q[`Dmactive] <= dmcontrol_d[`Dmactive];
                data0_q <= 32'h0;
                sbcs_q <= 32'h0;
                sbaddress0_q <= 32'h0;
                sbdata0_q <= 32'h0;
                dm_resp_data_q <= 32'h0;
                cmderr_q <= 3'h0;
            end else begin
                dmcontrol_q <= dmcontrol_d;
                data0_q <= data0_d;
                sbcs_q <= sbcs_d;
                sbaddress0_q <= sbaddress0_d;
                sbdata0_q <= sbdata0_d;
                dm_resp_data_q <= dm_resp_data_d;
                cmderr_q <= cmderr_d;
            end
            havereset_q <= havereset_d;
        end
    end

    jtag_mem #(

    ) u_jtag_mem (
        .clk(clk),
        .rst_n(rst_n),

        .halted_o(halted),
        .resumeack_o(resumeack),
        .clear_resumeack_i(clear_resumeack),
        .resumereq_i(resumereq),
        .haltreq_i(debug_req_o),
        .cmdbusy_o(cmdbusy),

        .req_i(slave_req_i),
        .we_i(slave_we_i),
        .addr_i(slave_addr_i),
        .be_i(slave_be_i),
        .wdata_i(slave_wdata_i),
        .rdata_o(slave_rdata_o)
    );

    jtag_sba #(

    ) u_jtag_sba (
        .clk(clk),
        .rst_n(rst_n),
        .sbaddress_i(sbaddress0_q),
        .sbaddress_write_valid_i(sbaddress_write_valid),
        .sbreadonaddr_i(sbcs_q[`Sbreadonaddr]),
        .sbaddress_o(sba_sbaddress),
        .sbautoincrement_i(sbcs_q[`Sbautoincrement]),
        .sbaccess_i(sbcs_q[`Sbaccess]),
        .sbreadondata_i(sbcs_q[`Sbreadondata]),
        .sbdata_i(sbdata0_q),
        .sbdata_read_valid_i(sbdata_read_valid),
        .sbdata_write_valid_i(sbdata_write_valid),
        .sbdata_o(sbdata),
        .sbdata_valid_o(sbdata_valid),
        .sbbusy_o(sbbusy),
        .sberror_o(sberror),

        .master_req_o(master_req_o),
        .master_gnt_i(master_gnt_i),
        .master_rvalid_i(master_rvalid_i),
        .master_we_o(master_we_o),
        .master_be_o(master_be_o),
        .master_addr_o(master_addr_o),
        .master_wdata_o(master_wdata_o),
        .master_rdata_i(master_rdata_i),
        .master_err_i(master_err_i)
    );

endmodule
