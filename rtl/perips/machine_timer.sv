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

module machine_timer(

    input wire clk,
    input wire rst_n,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    input wire[3:0] sel_i,
    input wire we_i,
	output wire[31:0] data_o,
    output wire irq_o

    );

    localparam mtime_ctrl_reg   = 4'h0;
    localparam mtime_cmp_reg    = 4'h4;
    localparam mtime_count_reg  = 4'h8;

    localparam start            = 0;
    localparam irq_pending      = 1;

    reg[31:0] mtime_ctrl_d, mtime_ctrl_q;
    reg[31:0] mtime_cmp_d, mtime_cmp_q;
    reg[31:0] mtime_count_q;
    reg data_q;

    wire[3:0] rw_addr = addr_i[3:0];
    wire w0 = we_i & sel_i[0];
    wire w1 = we_i & sel_i[1];
    wire w2 = we_i & sel_i[2];
    wire w3 = we_i & sel_i[3];

    // write
    always @ (*) begin
        mtime_cmp_d = mtime_cmp_q;
        mtime_ctrl_d = mtime_ctrl_q;

        case (rw_addr)
            mtime_ctrl_reg: begin
                if (w0) begin
                    mtime_ctrl_d[0] = data_i[0];
                    mtime_ctrl_d[irq_pending] = mtime_ctrl_q & (~data_i[irq_pending]);
                end
            end

            mtime_cmp_reg: begin
                if (w0) mtime_cmp_d[7:0]    = data_i[7:0];
                if (w1) mtime_cmp_d[15:8]   = data_i[15:8];
                if (w2) mtime_cmp_d[23:16]  = data_i[23:16];
                if (w3) mtime_cmp_d[31:24]  = data_i[31:24];
            end

            default:;
        endcase

        if (mtime_count_q == mtime_cmp_q) begin
            mtime_ctrl_d[irq_pending] = 1'b1;
        end
    end

    assign irq_o = mtime_ctrl_q[irq_pending] & mtime_ctrl_q[start];

    // read
    always @ (*) begin
        data_q = 32'h0;

        case (rw_addr)
            mtime_ctrl_reg:     data_q = mtime_ctrl_q;
            mtime_cmp_reg:      data_q = mtime_cmp_q;
            mtime_count_reg:    data_q = mtime_count_q;
            default:;
        endcase
    end

    assign data_o = data_q;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime_ctrl_q <= 32'h0;
            mtime_cmp_q <= 32'h0;
        end else begin
            mtime_ctrl_q <= mtime_ctrl_d;
            mtime_cmp_q <= mtime_cmp_d;
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime_count_q <= 32'h0;
        end else begin
            if (mtime_ctrl_q[start]) begin
                mtime_count_q <= mtime_count_q + 1'b1;
                if (mtime_count_q == mtime_cmp_q) begin
                    mtime_count_q <= 32'h0;
                end
            end else begin
                mtime_count_q <= 32'h0;
            end
        end
    end

endmodule
