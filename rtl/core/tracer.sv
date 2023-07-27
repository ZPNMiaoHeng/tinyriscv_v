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

module tracer(
    input logic clk,
    input logic rst_n,

    input logic[31:0] inst_i,
    input logic[31:0] pc_i,
    input logic inst_valid_i

    );


    typedef enum logic [6:0] {
      OPCODE_LOAD     = 7'h03,
      OPCODE_MISC_MEM = 7'h0f,
      OPCODE_OP_IMM   = 7'h13,
      OPCODE_AUIPC    = 7'h17,
      OPCODE_STORE    = 7'h23,
      OPCODE_OP       = 7'h33,
      OPCODE_LUI      = 7'h37,
      OPCODE_BRANCH   = 7'h63,
      OPCODE_JALR     = 7'h67,
      OPCODE_JAL      = 7'h6f,
      OPCODE_SYSTEM   = 7'h73
    } opcode_e;


    // instruction masks (for tracer)
    parameter logic [31:0] INSN_LUI     = { 25'h?,                           {OPCODE_LUI  } };
    parameter logic [31:0] INSN_AUIPC   = { 25'h?,                           {OPCODE_AUIPC} };
    parameter logic [31:0] INSN_JAL     = { 25'h?,                           {OPCODE_JAL  } };
    parameter logic [31:0] INSN_JALR    = { 17'h?,             3'b000, 5'h?, {OPCODE_JALR } };

    // BRANCH
    parameter logic [31:0] INSN_BEQ     = { 17'h?,             3'b000, 5'h?, {OPCODE_BRANCH} };
    parameter logic [31:0] INSN_BNE     = { 17'h?,             3'b001, 5'h?, {OPCODE_BRANCH} };
    parameter logic [31:0] INSN_BLT     = { 17'h?,             3'b100, 5'h?, {OPCODE_BRANCH} };
    parameter logic [31:0] INSN_BGE     = { 17'h?,             3'b101, 5'h?, {OPCODE_BRANCH} };
    parameter logic [31:0] INSN_BLTU    = { 17'h?,             3'b110, 5'h?, {OPCODE_BRANCH} };
    parameter logic [31:0] INSN_BGEU    = { 17'h?,             3'b111, 5'h?, {OPCODE_BRANCH} };

    // OPIMM
    parameter logic [31:0] INSN_ADDI    = { 17'h?,             3'b000, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_SLTI    = { 17'h?,             3'b010, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_SLTIU   = { 17'h?,             3'b011, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_XORI    = { 17'h?,             3'b100, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_ORI     = { 17'h?,             3'b110, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_ANDI    = { 17'h?,             3'b111, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_SLLI    = { 7'b0000000, 10'h?, 3'b001, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_SRLI    = { 7'b0000000, 10'h?, 3'b101, 5'h?, {OPCODE_OP_IMM} };
    parameter logic [31:0] INSN_SRAI    = { 7'b0100000, 10'h?, 3'b101, 5'h?, {OPCODE_OP_IMM} };

    // OP
    parameter logic [31:0] INSN_ADD     = { 7'b0000000, 10'h?, 3'b000, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SUB     = { 7'b0100000, 10'h?, 3'b000, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SLL     = { 7'b0000000, 10'h?, 3'b001, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SLT     = { 7'b0000000, 10'h?, 3'b010, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SLTU    = { 7'b0000000, 10'h?, 3'b011, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_XOR     = { 7'b0000000, 10'h?, 3'b100, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SRL     = { 7'b0000000, 10'h?, 3'b101, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_SRA     = { 7'b0100000, 10'h?, 3'b101, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_OR      = { 7'b0000000, 10'h?, 3'b110, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_AND     = { 7'b0000000, 10'h?, 3'b111, 5'h?, {OPCODE_OP} };

    // SYSTEM
    parameter logic [31:0] INSN_CSRRW   = { 17'h?,             3'b001, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_CSRRS   = { 17'h?,             3'b010, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_CSRRC   = { 17'h?,             3'b011, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_CSRRWI  = { 17'h?,             3'b101, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_CSRRSI  = { 17'h?,             3'b110, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_CSRRCI  = { 17'h?,             3'b111, 5'h?, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_ECALL   = { 12'b000000000000,         13'b0, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_EBREAK  = { 12'b000000000001,         13'b0, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_MRET    = { 12'b001100000010,         13'b0, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_DRET    = { 12'b011110110010,         13'b0, {OPCODE_SYSTEM} };
    parameter logic [31:0] INSN_WFI     = { 12'b000100000101,         13'b0, {OPCODE_SYSTEM} };

    // RV32M
    parameter logic [31:0] INSN_MUL     = { 7'b0000001, 10'h?, 3'b000, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_MULH    = { 7'b0000001, 10'h?, 3'b001, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_MULHSU  = { 7'b0000001, 10'h?, 3'b010, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_MULHU   = { 7'b0000001, 10'h?, 3'b011, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_DIV     = { 7'b0000001, 10'h?, 3'b100, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_DIVU    = { 7'b0000001, 10'h?, 3'b101, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_REM     = { 7'b0000001, 10'h?, 3'b110, 5'h?, {OPCODE_OP} };
    parameter logic [31:0] INSN_REMU    = { 7'b0000001, 10'h?, 3'b111, 5'h?, {OPCODE_OP} };

    // LOAD & STORE
    parameter logic [31:0] INSN_LOAD    = {25'h?,                            {OPCODE_LOAD } };
    parameter logic [31:0] INSN_STORE   = {25'h?,                            {OPCODE_STORE} };

    // MISC-MEM
    parameter logic [31:0] INSN_FENCE   = { 17'h?,             3'b000, 5'h?, {OPCODE_MISC_MEM} };
    parameter logic [31:0] INSN_FENCEI  = { 17'h0,             3'b001, 5'h0, {OPCODE_MISC_MEM} };

    // Get a CSR name for a CSR address.
    function automatic string get_csr_name(input logic [11:0] csr_addr);
        unique case (csr_addr)
            12'd0: return "ustatus";
            12'd4: return "uie";
            12'd5: return "utvec";
            12'd64: return "uscratch";
            12'd65: return "uepc";
            12'd66: return "ucause";
            12'd67: return "utval";
            12'd68: return "uip";
            12'd1: return "fflags";
            12'd2: return "frm";
            12'd3: return "fcsr";
            12'd3072: return "cycle";
            12'd3073: return "time";
            12'd3074: return "instret";
            12'd3075: return "hpmcounter3";
            12'd3076: return "hpmcounter4";
            12'd3077: return "hpmcounter5";
            12'd3078: return "hpmcounter6";
            12'd3079: return "hpmcounter7";
            12'd3080: return "hpmcounter8";
            12'd3081: return "hpmcounter9";
            12'd3082: return "hpmcounter10";
            12'd3083: return "hpmcounter11";
            12'd3084: return "hpmcounter12";
            12'd3085: return "hpmcounter13";
            12'd3086: return "hpmcounter14";
            12'd3087: return "hpmcounter15";
            12'd3088: return "hpmcounter16";
            12'd3089: return "hpmcounter17";
            12'd3090: return "hpmcounter18";
            12'd3091: return "hpmcounter19";
            12'd3092: return "hpmcounter20";
            12'd3093: return "hpmcounter21";
            12'd3094: return "hpmcounter22";
            12'd3095: return "hpmcounter23";
            12'd3096: return "hpmcounter24";
            12'd3097: return "hpmcounter25";
            12'd3098: return "hpmcounter26";
            12'd3099: return "hpmcounter27";
            12'd3100: return "hpmcounter28";
            12'd3101: return "hpmcounter29";
            12'd3102: return "hpmcounter30";
            12'd3103: return "hpmcounter31";
            12'd3200: return "cycleh";
            12'd3201: return "timeh";
            12'd3202: return "instreth";
            12'd3203: return "hpmcounter3h";
            12'd3204: return "hpmcounter4h";
            12'd3205: return "hpmcounter5h";
            12'd3206: return "hpmcounter6h";
            12'd3207: return "hpmcounter7h";
            12'd3208: return "hpmcounter8h";
            12'd3209: return "hpmcounter9h";
            12'd3210: return "hpmcounter10h";
            12'd3211: return "hpmcounter11h";
            12'd3212: return "hpmcounter12h";
            12'd3213: return "hpmcounter13h";
            12'd3214: return "hpmcounter14h";
            12'd3215: return "hpmcounter15h";
            12'd3216: return "hpmcounter16h";
            12'd3217: return "hpmcounter17h";
            12'd3218: return "hpmcounter18h";
            12'd3219: return "hpmcounter19h";
            12'd3220: return "hpmcounter20h";
            12'd3221: return "hpmcounter21h";
            12'd3222: return "hpmcounter22h";
            12'd3223: return "hpmcounter23h";
            12'd3224: return "hpmcounter24h";
            12'd3225: return "hpmcounter25h";
            12'd3226: return "hpmcounter26h";
            12'd3227: return "hpmcounter27h";
            12'd3228: return "hpmcounter28h";
            12'd3229: return "hpmcounter29h";
            12'd3230: return "hpmcounter30h";
            12'd3231: return "hpmcounter31h";
            12'd256: return "sstatus";
            12'd258: return "sedeleg";
            12'd259: return "sideleg";
            12'd260: return "sie";
            12'd261: return "stvec";
            12'd262: return "scounteren";
            12'd320: return "sscratch";
            12'd321: return "sepc";
            12'd322: return "scause";
            12'd323: return "stval";
            12'd324: return "sip";
            12'd384: return "satp";
            12'd3857: return "mvendorid";
            12'd3858: return "marchid";
            12'd3859: return "mimpid";
            12'd3860: return "mhartid";
            12'd768: return "mstatus";
            12'd769: return "misa";
            12'd770: return "medeleg";
            12'd771: return "mideleg";
            12'd772: return "mie";
            12'd773: return "mtvec";
            12'd774: return "mcounteren";
            12'd832: return "mscratch";
            12'd833: return "mepc";
            12'd834: return "mcause";
            12'd835: return "mtval";
            12'd836: return "mip";
            12'd928: return "pmpcfg0";
            12'd929: return "pmpcfg1";
            12'd930: return "pmpcfg2";
            12'd931: return "pmpcfg3";
            12'd944: return "pmpaddr0";
            12'd945: return "pmpaddr1";
            12'd946: return "pmpaddr2";
            12'd947: return "pmpaddr3";
            12'd948: return "pmpaddr4";
            12'd949: return "pmpaddr5";
            12'd950: return "pmpaddr6";
            12'd951: return "pmpaddr7";
            12'd952: return "pmpaddr8";
            12'd953: return "pmpaddr9";
            12'd954: return "pmpaddr10";
            12'd955: return "pmpaddr11";
            12'd956: return "pmpaddr12";
            12'd957: return "pmpaddr13";
            12'd958: return "pmpaddr14";
            12'd959: return "pmpaddr15";
            12'd2816: return "mcycle";
            12'd2818: return "minstret";
            12'd2819: return "mhpmcounter3";
            12'd2820: return "mhpmcounter4";
            12'd2821: return "mhpmcounter5";
            12'd2822: return "mhpmcounter6";
            12'd2823: return "mhpmcounter7";
            12'd2824: return "mhpmcounter8";
            12'd2825: return "mhpmcounter9";
            12'd2826: return "mhpmcounter10";
            12'd2827: return "mhpmcounter11";
            12'd2828: return "mhpmcounter12";
            12'd2829: return "mhpmcounter13";
            12'd2830: return "mhpmcounter14";
            12'd2831: return "mhpmcounter15";
            12'd2832: return "mhpmcounter16";
            12'd2833: return "mhpmcounter17";
            12'd2834: return "mhpmcounter18";
            12'd2835: return "mhpmcounter19";
            12'd2836: return "mhpmcounter20";
            12'd2837: return "mhpmcounter21";
            12'd2838: return "mhpmcounter22";
            12'd2839: return "mhpmcounter23";
            12'd2840: return "mhpmcounter24";
            12'd2841: return "mhpmcounter25";
            12'd2842: return "mhpmcounter26";
            12'd2843: return "mhpmcounter27";
            12'd2844: return "mhpmcounter28";
            12'd2845: return "mhpmcounter29";
            12'd2846: return "mhpmcounter30";
            12'd2847: return "mhpmcounter31";
            12'd2944: return "mcycleh";
            12'd2946: return "minstreth";
            12'd2947: return "mhpmcounter3h";
            12'd2948: return "mhpmcounter4h";
            12'd2949: return "mhpmcounter5h";
            12'd2950: return "mhpmcounter6h";
            12'd2951: return "mhpmcounter7h";
            12'd2952: return "mhpmcounter8h";
            12'd2953: return "mhpmcounter9h";
            12'd2954: return "mhpmcounter10h";
            12'd2955: return "mhpmcounter11h";
            12'd2956: return "mhpmcounter12h";
            12'd2957: return "mhpmcounter13h";
            12'd2958: return "mhpmcounter14h";
            12'd2959: return "mhpmcounter15h";
            12'd2960: return "mhpmcounter16h";
            12'd2961: return "mhpmcounter17h";
            12'd2962: return "mhpmcounter18h";
            12'd2963: return "mhpmcounter19h";
            12'd2964: return "mhpmcounter20h";
            12'd2965: return "mhpmcounter21h";
            12'd2966: return "mhpmcounter22h";
            12'd2967: return "mhpmcounter23h";
            12'd2968: return "mhpmcounter24h";
            12'd2969: return "mhpmcounter25h";
            12'd2970: return "mhpmcounter26h";
            12'd2971: return "mhpmcounter27h";
            12'd2972: return "mhpmcounter28h";
            12'd2973: return "mhpmcounter29h";
            12'd2974: return "mhpmcounter30h";
            12'd2975: return "mhpmcounter31h";
            12'd803: return "mhpmevent3";
            12'd804: return "mhpmevent4";
            12'd805: return "mhpmevent5";
            12'd806: return "mhpmevent6";
            12'd807: return "mhpmevent7";
            12'd808: return "mhpmevent8";
            12'd809: return "mhpmevent9";
            12'd810: return "mhpmevent10";
            12'd811: return "mhpmevent11";
            12'd812: return "mhpmevent12";
            12'd813: return "mhpmevent13";
            12'd814: return "mhpmevent14";
            12'd815: return "mhpmevent15";
            12'd816: return "mhpmevent16";
            12'd817: return "mhpmevent17";
            12'd818: return "mhpmevent18";
            12'd819: return "mhpmevent19";
            12'd820: return "mhpmevent20";
            12'd821: return "mhpmevent21";
            12'd822: return "mhpmevent22";
            12'd823: return "mhpmevent23";
            12'd824: return "mhpmevent24";
            12'd825: return "mhpmevent25";
            12'd826: return "mhpmevent26";
            12'd827: return "mhpmevent27";
            12'd828: return "mhpmevent28";
            12'd829: return "mhpmevent29";
            12'd830: return "mhpmevent30";
            12'd831: return "mhpmevent31";
            12'd1952: return "tselect";
            12'd1953: return "tdata1";
            12'd1954: return "tdata2";
            12'd1955: return "tdata3";
            12'd1968: return "dcsr";
            12'd1969: return "dpc";
            12'd1970: return "dscratch0";
            12'd1971: return "dscratch1";
            12'd512: return "hstatus";
            12'd514: return "hedeleg";
            12'd515: return "hideleg";
            12'd516: return "hie";
            12'd517: return "htvec";
            12'd576: return "hscratch";
            12'd577: return "hepc";
            12'd578: return "hcause";
            12'd579: return "hbadaddr";
            12'd580: return "hip";
            12'd896: return "mbase";
            12'd897: return "mbound";
            12'd898: return "mibase";
            12'd899: return "mibound";
            12'd900: return "mdbase";
            12'd901: return "mdbound";
            12'd800: return "mcountinhibit";
            default: return $sformatf("0x%x", csr_addr);
        endcase
    endfunction


    int unsigned  cycle;
    string        decoded_str;
    int           file_handle;
    string        file_name;

    logic[4:0] rd_addr = inst_i[11:7];
    logic[4:0] rs1_addr = inst_i[19:15];
    logic[4:0] rs2_addr = inst_i[24:20];


    function automatic void decode_u_insn(input string mnemonic);
        decoded_str = $sformatf("%s x%0d,0x%0x", mnemonic, rd_addr, {inst_i[31:12]});
    endfunction

    function automatic void decode_j_insn(input string mnemonic);
        decoded_str = $sformatf("%s x%0d,%0x", mnemonic, rd_addr, 
            {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0});
    endfunction

    function automatic void decode_i_jalr_insn(input string mnemonic);
        decoded_str = $sformatf("%s x%0d,%0d(x%0d)", mnemonic, rd_addr,
            $signed({{20 {inst_i[31]}}, inst_i[31:20]}), rs1_addr);
    endfunction

    function automatic void decode_b_insn(input string mnemonic);
        logic [31:0] branch_target;
        logic [31:0] imm;

        // We cannot use rvfi_pc_wdata for conditional jumps.
        imm = $signed({ {19 {inst_i[31]}}, inst_i[31], inst_i[7],
                 inst_i[30:25], inst_i[11:8], 1'b0 });
        branch_target = pc_i + imm;

        decoded_str = $sformatf("%s x%0d,x%0d,%0x", mnemonic, rs1_addr, rs2_addr, branch_target);
    endfunction

    function automatic void decode_i_insn(input string mnemonic);
        decoded_str = $sformatf("%s x%0d,x%0d,%0d", mnemonic, rd_addr, rs1_addr,
                        $signed({{20 {inst_i[31]}}, inst_i[31:20]}));
    endfunction

    function automatic void decode_i_shift_insn(input string mnemonic);
        logic [4:0] shamt;

        shamt = {inst_i[24:20]};
        decoded_str = $sformatf("%s x%0d,x%0d,0x%0x", mnemonic, rd_addr, rs1_addr, shamt);
    endfunction

    function automatic void decode_r_insn(input string mnemonic);
        decoded_str = $sformatf("%s x%0d,x%0d,x%0d", mnemonic, rd_addr, rs1_addr, rs2_addr);
    endfunction

    function automatic void decode_csr_insn(input string mnemonic);
        logic [11:0] csr;
        string csr_name;

        csr = inst_i[31:20];
        csr_name = get_csr_name(csr);

        if (!inst_i[14]) begin
            decoded_str = $sformatf("%s x%0d,%s,x%0d", mnemonic, rd_addr, csr_name, rs1_addr);
        end else begin
            decoded_str = $sformatf("%s x%0d,%s,%0d", mnemonic, rd_addr, csr_name, { 27'b0, inst_i[19:15]});
        end
    endfunction

    function automatic void decode_mnemonic(input string mnemonic);
        decoded_str = mnemonic;
    endfunction

    function automatic void decode_load_insn();
        string      mnemonic;

        logic [2:0] size;
        size = inst_i[14:12];
        if (size == 3'b000) begin
            mnemonic = "lb";
        end else if (size == 3'b001) begin
            mnemonic = "lh";
        end else if (size == 3'b010) begin
            mnemonic = "lw";
        end else if (size == 3'b100) begin
            mnemonic = "lbu";
        end else if (size == 3'b101) begin
            mnemonic = "lhu";
        end else begin
            decode_mnemonic("INVALID");
            return;
        end

        decoded_str = $sformatf("%s x%0d,%0d(x%0d)", mnemonic, rd_addr,
                    $signed({{20 {inst_i[31]}}, inst_i[31:20]}), rs1_addr);
    endfunction

    function automatic void decode_store_insn();
        string    mnemonic;

        if (inst_i[13:12] == 2'b00) begin
            mnemonic = "sb";
        end else if (inst_i[13:12] == 2'b01) begin
            mnemonic = "sh";
        end else if (inst_i[13:12] == 2'b10) begin
            mnemonic = "sw";
        end else begin
            decode_mnemonic("INVALID");
            return;
        end

        if (!inst_i[14]) begin
            decoded_str = $sformatf("%s x%0d,%0d(x%0d)", mnemonic, rs2_addr,
                        $signed({ {20 {inst_i[31]}}, inst_i[31:25], inst_i[11:7] }), rs1_addr);
        end else begin
            decode_mnemonic("INVALID");
        end
    endfunction

    function automatic string get_fence_description(logic [3:0] bits);
        string desc = "";

        if (bits[3]) begin
            desc = {desc, "i"};
        end
        if (bits[2]) begin
            desc = {desc, "o"};
        end
        if (bits[1]) begin
            desc = {desc, "r"};
        end
        if (bits[0]) begin
            desc = {desc, "w"};
        end
        return desc;
    endfunction

    function automatic void decode_fence();
        string predecessor;
        string successor;

        predecessor = get_fence_description(inst_i[27:24]);
        successor = get_fence_description(inst_i[23:20]);
        decoded_str = $sformatf("fence %s,%s", predecessor, successor);
    endfunction


    always_comb begin
        // decoded_str = "";

        unique casez (inst_i)
            INSN_LUI:        decode_u_insn("lui");
            INSN_AUIPC:      decode_u_insn("auipc");
            INSN_JAL:        decode_j_insn("jal");
            INSN_JALR:       decode_i_jalr_insn("jalr");
            // BRANCH
            INSN_BEQ:        decode_b_insn("beq");
            INSN_BNE:        decode_b_insn("bne");
            INSN_BLT:        decode_b_insn("blt");
            INSN_BGE:        decode_b_insn("bge");
            INSN_BLTU:       decode_b_insn("bltu");
            INSN_BGEU:       decode_b_insn("bgeu");
            // OPIMM
            INSN_ADDI: begin
                if (inst_i == 32'h00_00_00_13) begin
                    decode_mnemonic("nop");
                end else begin
                    decode_i_insn("addi");
                end
            end
            INSN_SLTI:       decode_i_insn("slti");
            INSN_SLTIU:      decode_i_insn("sltiu");
            INSN_XORI:       decode_i_insn("xori");
            INSN_ORI:        decode_i_insn("ori");
            INSN_ANDI:       decode_i_insn("andi");
            INSN_SLLI:       decode_i_shift_insn("slli");
            INSN_SRLI:       decode_i_shift_insn("srli");
            INSN_SRAI:       decode_i_shift_insn("srai");
            // OP
            INSN_ADD:        decode_r_insn("add");
            INSN_SUB:        decode_r_insn("sub");
            INSN_SLL:        decode_r_insn("sll");
            INSN_SLT:        decode_r_insn("slt");
            INSN_SLTU:       decode_r_insn("sltu");
            INSN_XOR:        decode_r_insn("xor");
            INSN_SRL:        decode_r_insn("srl");
            INSN_SRA:        decode_r_insn("sra");
            INSN_OR:         decode_r_insn("or");
            INSN_AND:        decode_r_insn("and");
            // SYSTEM (CSR manipulation)
            INSN_CSRRW:      decode_csr_insn("csrrw");
            INSN_CSRRS:      decode_csr_insn("csrrs");
            INSN_CSRRC:      decode_csr_insn("csrrc");
            INSN_CSRRWI:     decode_csr_insn("csrrwi");
            INSN_CSRRSI:     decode_csr_insn("csrrsi");
            INSN_CSRRCI:     decode_csr_insn("csrrci");
            // SYSTEM (others)
            INSN_ECALL:      decode_mnemonic("ecall");
            INSN_EBREAK:     decode_mnemonic("ebreak");
            INSN_MRET:       decode_mnemonic("mret");
            INSN_DRET:       decode_mnemonic("dret");
            INSN_WFI:        decode_mnemonic("wfi");
            // RV32M
            INSN_MUL:        decode_r_insn("mul");
            INSN_MULH:       decode_r_insn("mulh");
            INSN_MULHSU:     decode_r_insn("mulhsu");
            INSN_MULHU:      decode_r_insn("mulhu");
            INSN_DIV:        decode_r_insn("div");
            INSN_DIVU:       decode_r_insn("divu");
            INSN_REM:        decode_r_insn("rem");
            INSN_REMU:       decode_r_insn("remu");
            // LOAD & STORE
            INSN_LOAD:       decode_load_insn();
            INSN_STORE:      decode_store_insn();
            // MISC-MEM
            INSN_FENCE:      decode_fence();
            INSN_FENCEI:     decode_mnemonic("fence.i");
            default:         decode_mnemonic("INVALID");
        endcase
    end



    initial begin
        string file_name_base = "trace_core";
        $sformat(file_name, "%s.log", file_name_base);

        $display("Writing execution trace to %s", file_name);
        file_handle = $fopen(file_name, "w");
        $fwrite(file_handle, "\t\t\tTime\t\tCycle\tPC\t\t\tInsn\t\tDecoded instruction\n");
        $fflush(file_handle);
    end


    function automatic void printbuffer_dumpline();
        string insn_str = $sformatf("%h", inst_i);

        $fwrite(file_handle, "%15t\t%d\t\t%h\t%s\t%s", $time, cycle, pc_i, insn_str, decoded_str);
        $fwrite(file_handle, "\n");
        $fflush(file_handle);
    endfunction

    // log execution
    always @(posedge clk) begin
        if (inst_valid_i) begin
            printbuffer_dumpline();
        end
    end

    // cycle counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
        end
    end

endmodule
