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



module jtag_mem #(
    )(

    input wire                      clk,
    input wire                      rst_n,

    output wire                     halted_o,
    output wire                     resumeack_o,
    output wire                     cmdbusy_o,
    input  wire                     clear_resumeack_i,
    input  wire                     resumereq_i,
    input  wire                     haltreq_i,

    input  wire                     req_i,
    input  wire                     we_i,
    input  wire [31:0]              addr_i,
    input  wire [3:0]               be_i,
    input  wire [31:0]              wdata_i,
    output wire [31:0]              rdata_o

    );

    // 16KB
    localparam DbgAddressBits       = 12;
    // x10/a0
    localparam LoadBaseAddr         = 5'd10;

    localparam DataBaseAddr         = `DataAddr;
    localparam DataEndAddr          = (`DataAddr + 4 * `DataCount - 1);
    localparam ProgBufBaseAddr      = (`DataAddr - 4 * `ProgBufSize);
    localparam ProgBufEndAddr       = (`DataAddr - 1);
    localparam AbstractCmdBaseAddr  = (ProgBufBaseAddr - 4 * 10);
    localparam AbstractCmdEndAddr   = (ProgBufBaseAddr - 1);

    localparam WhereToAddr          = 12'h300;
    localparam FlagsBaseAddr        = 12'h400;
    localparam FlagsEndAddr         = 12'h7FF;

    localparam HaltedAddr           = 12'h100;
    localparam GoingAddr            = 12'h104;
    localparam ResumingAddr         = 12'h108;
    localparam ExceptionAddr        = 12'h10C;

    localparam S_IDLE               = 4'b0001;
    localparam S_RESUME             = 4'b0010;
    localparam S_GO                 = 4'b0100;
    localparam S_CMD_EXECUTING      = 4'b1000;

    reg[3:0] state_d, state_q;

    reg[31:0] rdata_d, rdata_q;
    reg halted_d, halted_q;
    reg resuming_d, resuming_q;
    reg resume, go, going;
    reg fwd_rom_q;
    reg word_enable32_q;
    wire fwd_rom_d;
    wire[63:0] rom_rdata;



    // word mux for 32bit and 64bit buses
    wire [63:0] word_mux;
    assign word_mux = fwd_rom_q ? rom_rdata : rdata_q;
    assign rdata_o = (word_enable32_q) ? word_mux[32 +: 32] : word_mux[0 +: 32];

    assign halted_o = halted_q;
    assign resumeack_o = resuming_q;
    assign cmdbusy_o = 1'b0;


    always @ (*) begin
        state_d = state_q;
        resume = 1'b0;
        go = 1'b0;

        case (state_q)
            S_IDLE: begin
                if (resumereq_i && (!resuming_q) &&
                    halted_q && (!haltreq_i)) begin
                    state_d = S_RESUME;
                end
            end

            S_RESUME: begin
                resume = 1'b1;
                if (resuming_q) begin
                    state_d = S_IDLE;
                end
            end

            default:;
        endcase
    end

    always @ (*) begin
        rdata_d = rdata_q;
        halted_d = halted_q;
        resuming_d = resuming_q;

        if (clear_resumeack_i) begin
            resuming_d = 1'b0;
        end

        // write
        if (we_i) begin
            case (addr_i[DbgAddressBits-1:0])
                HaltedAddr: begin
                    halted_d = 1'b1;
                end

                GoingAddr: begin

                end

                ResumingAddr: begin
                    halted_d = 1'b0;
                    resuming_d = 1'b1;
                end

                ExceptionAddr: begin

                end

                default:;
            endcase
        // read
        end else begin
            case (addr_i[DbgAddressBits-1:0])
                // harts are polling for flags here
                FlagsBaseAddr: begin
                    rdata_d = {30'b0, resume, go};
                end

                default:;
            endcase
        end
    end

    wire[63:0] rom_addr;
    assign rom_addr = {32'h0, addr_i};

    assign fwd_rom_d = addr_i[DbgAddressBits-1:0] >= `HaltAddress;

    debug_rom u_debug_rom (
        .clk_i   ( clk       ),
        .req_i   ( 1'b1      ),
        .addr_i  ( rom_addr  ),
        .rdata_o ( rom_rdata )
    );

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_q <= 32'h0;
            fwd_rom_q <= 1'b0;
            word_enable32_q <= 1'b0;
            halted_q <= 1'b0;
            resuming_q <= 1'b0;
        end else begin
            rdata_q <= rdata_d;
            fwd_rom_q <= fwd_rom_d;
            word_enable32_q <= addr_i[2];
            halted_q <= halted_d;
            resuming_q <= resuming_d;
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

endmodule
