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

package flash_n25q_pkg;

    parameter logic [7:0] MANF_ID               = 8'h20;
    parameter logic [7:0] DEV_ID                = 8'hBA;
    // dummy个数. bytes = dummy / 2
    parameter logic [3:0] DUMMY_CNT             = 4'd10;
    // SS引脚延时时钟数
    parameter logic [7:0] SS_DELAY_CNT          = 8'd30;

    // 命令
    parameter logic [7:0] CMD_READ_ID           = 8'h9F;
    parameter logic [7:0] CMD_MULTIO_READ_ID    = 8'hAF;
    parameter logic [7:0] CMD_READ_QSPI_REG     = 8'h65;
    parameter logic [7:0] CMD_WRITE_QSPI_REG    = 8'h61;
    parameter logic [7:0] CMD_READ              = 8'h03;
    parameter logic [7:0] CMD_READ_STATUS_REG   = 8'h05;
    parameter logic [7:0] CMD_READ_FLAG_STATUS_REG  = 8'h70;
    parameter logic [7:0] CMD_CLEAR_FLAG_STATUS_REG = 8'h50;
    parameter logic [7:0] CMD_FAST_READ         = 8'h0B;
    parameter logic [7:0] CMD_PAGE_PROG         = 8'h02;
    parameter logic [7:0] CMD_SUBSECTOR_ERASE   = 8'h20;
    parameter logic [7:0] CMD_WRITE_ENABLE      = 8'h06;
    parameter logic [7:0] CMD_WRITE_DISABLE     = 8'h04;
    parameter logic [7:0] CMD_READ_DUMMY_REG    = 8'h85;
    parameter logic [7:0] CMD_WRITE_DUMMY_REG   = 8'h81;

    // SPI CPOL/CPHL模式
    parameter logic [1:0] CPOL_0_CPHA_0         = 2'b00;
    parameter logic [1:0] CPOL_0_CPHA_1         = 2'b01;
    parameter logic [1:0] CPOL_1_CPHA_0         = 2'b10;
    parameter logic [1:0] CPOL_1_CPHA_1         = 2'b11;

    // SPI模式
    parameter logic [1:0] MODE_STAND_SPI        = 2'b00;
    parameter logic [1:0] MODE_DUAL_SPI         = 2'b01;
    parameter logic [1:0] MODE_QUAD_SPI         = 2'b10;

endpackage
