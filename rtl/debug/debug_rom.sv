/* Copyright 2018 ETH Zurich and University of Bologna.
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * File: $filename.v
 *
 * Description: Auto-generated bootrom
 */

// Auto-generated code
module debug_rom (
  input  wire         clk_i,
  input  wire         req_i,
  input  wire [63:0]  addr_i,
  output wire [63:0]  rdata_o
);

  localparam RomSize = 19;

  wire [RomSize-1:0][63:0] mem;

  assign mem = {
    64'h00000000_7b200073,
    64'h7b202473_7b302573,
    64'h10852423_f1402473,
    64'ha85ff06f_7b202473,
    64'h7b302573_10052223,
    64'h00100073_7b202473,
    64'h7b302573_10052623,
    64'h00c51513_00c55513,
    64'h00000517_fd5ff06f,
    64'hfa041ce3_00247413,
    64'h40044403_00a40433,
    64'hf1402473_02041c63,
    64'h00147413_40044403,
    64'h00a40433_10852023,
    64'hf1402473_00c51513,
    64'h00c55513_00000517,
    64'h7b351073_7b241073,
    64'h0ff0000f_04c0006f,
    64'h07c0006f_00c0006f
  };

  reg [4:0] addr_q;

  always @ (posedge clk_i) begin
    if (req_i) begin
      addr_q <= addr_i[7:3];
    end
  end

  reg[63:0]  rdata;

  // this prevents spurious Xes from propagating into
  // the speculative fetch stage of the core
  always @ (*) begin
    rdata = 64'h0;
    if (addr_q < 5'd19) begin
        rdata = mem[addr_q];
    end
  end

  assign rdata_o = rdata;

endmodule
