// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Top level wrapper for a verilator RI5CY testbench
// Contributor: Robert Balas <balasr@student.ethz.ch>


module tb_top_verilator #(

    ) (
       input   clk_i,
       input   rst_ni,
       input   fetch_enable_i
    );





    initial begin: load_prog
        automatic logic [1023:0] firmware;

        if($value$plusargs("firmware=%s", firmware)) begin
            //if($test$plusargs("verbose"))
                $display("[TESTBENCH] %t: loading firmware %0s ...",
                         $time, firmware);
            $readmemh (firmware, u_tinyriscv_soc_top.u_rom.u_gen_ram.ram);
            //$display("mem[0x80]=0x%x", u_ram.ram.mem[32]);
            //$display("mem[0x84]=0x%x", u_ram.ram.mem[33]);
        end else begin
            $display("No firmware specified");
        end
    end


    tinyriscv_soc_top u_tinyriscv_soc_top(
        .clk(clk_i),
        .rst_ext_i(rst_ni)
    );

endmodule // tb_top_verilator
