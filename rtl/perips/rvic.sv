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

`include "../core/defines.sv"

// RISC-V中断控制器
// 支持32个中断源，每个中断源支持256级优先级
module rvic #(

    )(

    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] src_i,
    output logic        irq_o,      // 中断请求信号
    output logic [7:0]  irq_id_o,   // 中断号

    input  logic [31:0] addr_i,
    input  logic [31:0] data_i,
    input  logic [3:0]  be_i,
    input  logic        we_i,
	output logic [31:0] data_o

    );

    // 寄存器地址偏移
    parameter logic [7:0] IE_OFFSET    = 8'h0;
    parameter logic [7:0] IP_OFFSET    = 8'h4;
    parameter logic [7:0] PRIO0_OFFSET = 8'h8;
    parameter logic [7:0] PRIO1_OFFSET = 8'hc;
    parameter logic [7:0] PRIO2_OFFSET = 8'h10;
    parameter logic [7:0] PRIO3_OFFSET = 8'h14;
    parameter logic [7:0] PRIO4_OFFSET = 8'h18;
    parameter logic [7:0] PRIO5_OFFSET = 8'h1c;
    parameter logic [7:0] PRIO6_OFFSET = 8'h20;
    parameter logic [7:0] PRIO7_OFFSET = 8'h24;
    parameter logic [7:0] ID_OFFSET    = 8'h28;

    logic ie_we;
    logic ip_we;
    logic [7:0] prio_we;

    logic [31:0] prio_q[8];
    logic [31:0] ie_q;
    logic [31:0] ip_q;
    logic [31:0] id_q;

    logic [10:0] addr_hit;
    logic [7:0] reg_addr = addr_i[7:0];

    always_comb begin
        addr_hit     = 11'h0;
        addr_hit[ 0] = (reg_addr == IE_OFFSET);
        addr_hit[ 1] = (reg_addr == IP_OFFSET);
        addr_hit[ 2] = (reg_addr == PRIO0_OFFSET);
        addr_hit[ 3] = (reg_addr == PRIO1_OFFSET);
        addr_hit[ 4] = (reg_addr == PRIO2_OFFSET);
        addr_hit[ 5] = (reg_addr == PRIO3_OFFSET);
        addr_hit[ 6] = (reg_addr == PRIO4_OFFSET);
        addr_hit[ 7] = (reg_addr == PRIO5_OFFSET);
        addr_hit[ 8] = (reg_addr == PRIO6_OFFSET);
        addr_hit[ 9] = (reg_addr == PRIO7_OFFSET);
        addr_hit[10] = (reg_addr == ID_OFFSET);
    end

    assign ie_we = we_i & addr_hit[0];
    assign ip_we = we_i & addr_hit[1];
    for (genvar p = 0; p < 8; p = p + 1) begin
        assign prio_we[p] = we_i & addr_hit[p + 2];
    end

    // 写寄存器
    logic [31:0] reg_wdata;

    always_comb begin
        reg_wdata = 32'h0;

        // IP寄存器是写1清零的，因此要区别对待
        if (ip_we) begin
            reg_wdata = ip_q;
            if (be_i[0])
                reg_wdata[7:0]   = ip_q[7:0]   & (~data_i[7:0]);
            if (be_i[1])
                reg_wdata[15:8]  = ip_q[15:8]  & (~data_i[15:8]);
            if (be_i[2])
                reg_wdata[23:16] = ip_q[23:16] & (~data_i[23:16]);
            if (be_i[3])
                reg_wdata[31:24] = ip_q[31:24] & (~data_i[31:24]);
        end else begin
            if (ie_we) begin
                reg_wdata = ie_q;
            end
            for (int j = 0; j < 8; j = j + 1) begin
                if (prio_we[j]) begin
                    reg_wdata = prio_q[j];
                end
            end
            if (be_i[0])
                reg_wdata[7:0]   = data_i[7:0];
            if (be_i[1])
                reg_wdata[15:8]  = data_i[15:8];
            if (be_i[2])
                reg_wdata[23:16] = data_i[23:16];
            if (be_i[3])
                reg_wdata[31:24] = data_i[31:24];
        end
    end

    gen_en_dff #(32) ie_ff(clk_i, rst_ni, ie_we, reg_wdata, ie_q);

    logic [31:0] ip_wdata;

    assign ip_wdata = ip_we ? reg_wdata : (ip_q | src_i);
    gen_en_dff #(32) ip_ff(clk_i, rst_ni, 1'b1, ip_wdata, ip_q);

    for (genvar m = 0; m < 8; m = m + 1) begin
        gen_en_dff #(32) prio_ff(clk_i, rst_ni, prio_we[m], reg_wdata, prio_q[m]);
    end

    // 读寄存器
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= 32'h0;
        end else begin
            case (addr_i[7:0])
                IE_OFFSET:    data_o <= ie_q;
                IP_OFFSET:    data_o <= ip_q;
                PRIO0_OFFSET: data_o <= prio_q[0];
                PRIO1_OFFSET: data_o <= prio_q[1];
                PRIO2_OFFSET: data_o <= prio_q[2];
                PRIO3_OFFSET: data_o <= prio_q[3];
                PRIO4_OFFSET: data_o <= prio_q[4];
                PRIO5_OFFSET: data_o <= prio_q[5];
                PRIO6_OFFSET: data_o <= prio_q[6];
                PRIO7_OFFSET: data_o <= prio_q[7];
                ID_OFFSET:    data_o <= id_q;
                default:      data_o <= 32'h0;
            endcase
        end
    end

    // 找出优先级最高(优先级值最大)的中断源
    // 二分法查找

    logic [7:0] each_prio[32];

    for (genvar i = 0; i < 8; i = i + 1) begin
        for (genvar j = 0; j < 4; j = j + 1) begin
            assign each_prio[i*4+j] = prio_q[i][8*j+7:8*j] & {8{ie_q[i*4+j]}};
        end
    end

    typedef struct packed {
        logic [7:0]  id;
        logic [7:0]  prio;
    } int_info_t;

    int_info_t l1_max[16];
    always_comb begin
        for (int i = 0; i < 16; i = i + 1) begin
            if (each_prio[2*i+1] > each_prio[2*i]) begin
                l1_max[i].id   = 2*i+1;
                l1_max[i].prio = each_prio[2*i+1];
            end else begin
                l1_max[i].id   = 2*i;
                l1_max[i].prio = each_prio[2*i];
            end
        end
    end

    int_info_t l2_max[8];
    always_comb begin
        for (int i = 0; i < 8; i = i + 1) begin
            if (l1_max[2*i+1].prio > l1_max[2*i].prio) begin
                l2_max[i].id   = l1_max[2*i+1].id;
                l2_max[i].prio = l1_max[2*i+1].prio;
            end else begin
                l2_max[i].id   = l1_max[2*i].id;
                l2_max[i].prio = l1_max[2*i].prio;
            end
        end
    end

    int_info_t l3_max[4];
    always_comb begin
        for (int i = 0; i < 4; i = i + 1) begin
            if (l2_max[2*i+1].prio > l2_max[2*i].prio) begin
                l3_max[i].id   = l2_max[2*i+1].id;
                l3_max[i].prio = l2_max[2*i+1].prio;
            end else begin
                l3_max[i].id   = l2_max[2*i].id;
                l3_max[i].prio = l2_max[2*i].prio;
            end
        end
    end

    int_info_t l4_max[2];
    always_comb begin
        for (int i = 0; i < 2; i = i + 1) begin
            if (l3_max[2*i+1].prio > l3_max[2*i].prio) begin
                l4_max[i].id   = l3_max[2*i+1].id;
                l4_max[i].prio = l3_max[2*i+1].prio;
            end else begin
                l4_max[i].id   = l3_max[2*i].id;
                l4_max[i].prio = l3_max[2*i].prio;
            end
        end
    end

    logic [7:0] irq_id;

    assign irq_id = (l4_max[1].prio > l4_max[0].prio) ? l4_max[1].id : l4_max[0].id;

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            irq_id_o <= 8'h0;
            irq_o <= 1'b0;
        end else begin
            irq_id_o <= irq_id;
            irq_o <= |((src_i | ip_q) & ie_q);
        end
    end

    assign id_q = {24'h0, irq_id};

endmodule
