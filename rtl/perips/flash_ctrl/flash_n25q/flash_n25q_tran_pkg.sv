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

package flash_n25q_tran_pkg;

    // 操作方式
    typedef enum logic [1:0] {
        OP_NOP   = 2'h0,
        OP_READ  = 2'h1,
        OP_WRITE = 2'h2
    } tran_op_e;

    // 请求数据
    typedef struct packed {
        logic start;
        logic [1:0] spi_mode;
        logic [7:0] cmd;
        struct packed {
            logic [31:0] d;
            logic [ 3:0] be;
        } addr;
        struct packed {
            logic [7:0] d;
            logic [3:0] cnt;
        } dummy;
        struct packed {
            logic [31:0] d;
            logic [ 3:0] be;
        } data;
        tran_op_e op;
    } flash_n25q_tran_req_t;

    // 响应数据
    typedef struct packed {
        logic ready;
        logic [31:0] data;
    } flash_n25q_tran_resp_t;

endpackage
