
// obi总线交叉互联矩阵，支持一对多、多对一、多对多
// master之间采用优先级总裁方式，LSB优先级最高，MSB优先级最低
module obi_interconnect #(
    parameter  int  MASTERS            = 3,  // number of masters
    parameter  int  SLAVES             = 5,  // number of slaves
    parameter MASTER_BITS = MASTERS == 1 ? 1 : $clog2(MASTERS),
    parameter SLAVE_BITS  = SLAVES  == 1 ? 1 : $clog2(SLAVES)
    )(
    input logic         clk_i,
    input logic         rst_ni,

    input logic         master_req_i      [MASTERS],
    output logic        master_gnt_o      [MASTERS],
    output logic        master_rvalid_o   [MASTERS],
    input logic         master_we_i       [MASTERS],
    input logic  [ 3:0] master_be_i       [MASTERS],
    input logic  [31:0] master_addr_i     [MASTERS],
    input logic  [31:0] master_wdata_i    [MASTERS],
    output logic [31:0] master_rdata_o    [MASTERS],

    input logic  [31:0] slave_addr_mask_i [SLAVES],
    input logic  [31:0] slave_addr_base_i [SLAVES],

    output logic        slave_req_o       [SLAVES],
    input logic         slave_gnt_i       [SLAVES],
    input logic         slave_rvalid_i    [SLAVES],
    output logic        slave_we_o        [SLAVES],
    output logic [ 3:0] slave_be_o        [SLAVES],
    output logic [31:0] slave_addr_o      [SLAVES],
    output logic [31:0] slave_wdata_o     [SLAVES],
    input logic  [31:0] slave_rdata_i     [SLAVES]
    );

    genvar m, s;

    logic [MASTER_BITS-1:0]     master_sel_int[SLAVES];
    logic [MASTERS-1:0]         master_sel_vec[SLAVES];
    logic                       granted_master[SLAVES];

    // 为每个slave选择一个master
    generate
        for (s = 0; s < SLAVES; s = s + 1) begin: master_sel
            obi_interconnect_master_sel #(
                .MASTERS(MASTERS)
            ) master_sel (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .master_req_i(master_req_i),
                .master_addr_i(master_addr_i),
                .slave_addr_mask_i(slave_addr_mask_i[s]),
                .slave_addr_base_i(slave_addr_base_i[s]),
                .master_sel_int_o(master_sel_int[s]),
                .master_sel_vec_o(master_sel_vec[s]),
                .granted_master_o(granted_master[s])
            );
        end
    endgenerate

    logic [SLAVE_BITS-1:0]     slave_sel_int[MASTERS];

    // 为每个master选择一个slave
    generate
        for (m = 0; m < MASTERS; m = m + 1) begin: slave_sel
            obi_interconnect_slave_sel #(
                .SLAVES(SLAVES)
            ) slave_sel (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .master_req_i(master_req_i[m]),
                .master_addr_i(master_addr_i[m]),
                .slave_addr_mask_i(slave_addr_mask_i),
                .slave_addr_base_i(slave_addr_base_i),
                .slave_sel_int_o(slave_sel_int[m])
            );
        end
    endgenerate

    // slave信号赋值
    generate
        for (s = 0; s < SLAVES; s = s + 1) begin: slave_signal
            assign slave_req_o[s]   = master_req_i[master_sel_int[s]];
            assign slave_we_o[s]    = master_we_i[master_sel_int[s]];
            assign slave_be_o[s]    = master_be_i[master_sel_int[s]];
            assign slave_addr_o[s]  = master_addr_i[master_sel_int[s]];
            assign slave_wdata_o[s] = master_wdata_i[master_sel_int[s]];
        end
    endgenerate

    logic [MASTERS-1:0]         master_sel_or;

    always_comb begin
        master_sel_or = 'b0;
        for (integer i = 0; i < SLAVES; i = i + 1) begin: gen_master_sel_or_vec
            master_sel_or = master_sel_or | master_sel_vec[i];
        end
    end

    // master信号赋值
    generate
        for (m = 0; m < MASTERS; m = m + 1) begin: master_gnt_rdata
            assign master_gnt_o[m]   = master_sel_or[m];
            assign master_rdata_o[m] = slave_rdata_i[slave_sel_int[m]];
        end
    endgenerate

    // master信号赋值
    generate
        for (m = 0; m < MASTERS; m = m + 1) begin: master_rvalid
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    master_rvalid_o[m] <= 'b0;
                end else begin
                    master_rvalid_o[m] <= master_sel_or[m];
                end
            end
        end
    endgenerate

endmodule
