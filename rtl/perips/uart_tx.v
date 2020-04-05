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


module uart_tx(

	input wire clk,
	input wire rst,

    input wire we_i,
    input wire req_i,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,

    output reg[31:0] data_o,
    output reg ack_o,
	output wire tx_pin

    );


    localparam BAUD_115200 = 32'h1B3;

    localparam S_IDLE       = 4'b0001;
    localparam S_START      = 4'b0010;
    localparam S_SEND_BYTE  = 4'b0100;
    localparam S_STOP       = 4'b1000;

    reg[31:0] fifo_data[31:0];
    reg tx_data_valid;
    reg tx_data_ready;
    reg[8:0] fifo_index;
    reg[8:0] fifo_count;

    reg[3:0] state;
    reg[3:0] next_state;
    reg[15:0] cycle_cnt;
    reg[2:0] bit_cnt;
    reg[7:0] tx_data;
    reg tx_reg;

    localparam UART_CTRL = 4'h0;
    localparam UART_STATUS = 4'h4;
    localparam UART_BAUD = 4'h8;
    localparam UART_TXDATA = 4'hc;

    reg[31:0] uart_ctrl;
    reg[31:0] uart_status;
    reg[31:0] uart_baud;


    assign tx_pin = tx_reg;


    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            uart_ctrl <= 32'h0;
            uart_status <= 32'h0;
            fifo_count <= 8'h0;
            fifo_index <= 8'h0;
            uart_baud <= BAUD_115200;
        end else begin
            if (we_i == 1'b1) begin
                case (addr_i[3:0])
                    UART_CTRL: begin
                        uart_ctrl <= data_i;
                        if (data_i[1] == 1'b1) begin
                            fifo_count <= 8'h0;
                        end
                        if (uart_ctrl[0] == 1'b0 && data_i[0] == 1'b1) begin
                            if (fifo_count > 8'h0) begin
                                tx_data_valid <= 1'b1;
                                fifo_index <= 8'h0;
                                uart_status <= 32'h1;
                            end
                        end
                    end
                    UART_BAUD: begin
                        uart_baud <= data_i;
                    end
                    UART_TXDATA: begin
                        if (fifo_count <= 8'd31) begin
                            fifo_data[fifo_count] <= data_i;
                            fifo_count <= fifo_count + 1'b1;
                        end
                    end
                endcase
            end else begin
                if (tx_data_ready == 1'b1 && tx_data_valid == 1'b1) begin
                    fifo_count <= 8'h0;
                    tx_data_valid <= 1'b0;
                    fifo_index <= 8'h0;
                    uart_status <= 32'h0;
                    uart_ctrl[0] <= 1'b0;
                end else if (cycle_cnt == uart_baud[15:0] && bit_cnt == 3'd7) begin
                    fifo_index <= fifo_index + 1'b1;
                end
            end
        end
    end

    always @ (*) begin
        if (rst == 1'b0) begin
            data_o <= 32'h0;
        end else begin
            case (addr_i[3:0])
                UART_CTRL: begin
                    data_o <= uart_ctrl;
                end
                UART_STATUS: begin
                    data_o <= uart_status;
                end
                UART_BAUD: begin
                    data_o <= uart_baud;
                end
                default: begin
                    data_o <= 32'h0;
                end
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @ (*) begin
        case (state)
            S_IDLE: begin
                if (tx_data_valid == 1'b1) begin
                    next_state <= S_START;
                end else begin
                    next_state <= S_IDLE;
                end
            end
            S_START: begin
                if (cycle_cnt == uart_baud[15:0]) begin
                    next_state <= S_SEND_BYTE;
                end else begin
                    next_state <= S_START;
                end
            end
            S_SEND_BYTE: begin
                if (cycle_cnt == uart_baud[15:0] && bit_cnt == 3'd7) begin
                    next_state <= S_STOP;
                end else begin
                    next_state <= S_SEND_BYTE;
                end
            end
            S_STOP: begin
                if (cycle_cnt == uart_baud[15:0]) begin
                    next_state <= S_IDLE;
                end else begin
                    next_state <= S_STOP;
                end
            end
            default: begin
                next_state <= S_IDLE;
            end
        endcase
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            tx_data_ready <= 1'b0;
        end else if (state == S_STOP && cycle_cnt == uart_baud[15:0]) begin
            if (fifo_index == (fifo_count - 1'b1)) begin
                tx_data_ready <= 1'b1;
            end
        end else begin
            tx_data_ready <= 1'b0;
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            tx_data <= 8'd0;
        end else if (state == S_IDLE && tx_data_valid == 1'b1) begin
            tx_data <= fifo_data[fifo_index];
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            bit_cnt <= 3'd0;
        end else if (state == S_SEND_BYTE) begin
            if (cycle_cnt == uart_baud[15:0]) begin
                bit_cnt <= bit_cnt + 3'd1;
            end else begin
                bit_cnt <= bit_cnt;
            end
        end else begin
            bit_cnt <= 3'd0;
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            cycle_cnt <= 16'd0;
        end else if ((state == S_SEND_BYTE && cycle_cnt == uart_baud[15:0]) || next_state != state) begin
            cycle_cnt <= 16'd0;
        end else begin
            cycle_cnt <= cycle_cnt + 16'd1;
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            tx_reg <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_reg <= 1'b1;
                end
                S_START: begin
                    tx_reg <= 1'b0;
                end
                S_SEND_BYTE: begin
                    tx_reg <= tx_data[bit_cnt];
                end
                S_STOP: begin
                    tx_reg <= 1'b1;
                end
                default: begin
                    tx_reg <= 1'b1;
                end
            endcase
        end
    end

endmodule
