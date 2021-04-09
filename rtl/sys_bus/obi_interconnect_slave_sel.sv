

// 从多个slave之间选择一个
module obi_interconnect_slave_sel #(
    parameter int unsigned SLAVES = 3,
    parameter SLAVE_BITS = SLAVES == 1 ? 1 : $clog2(SLAVES)
    )(
    input   logic                       clk_i,
    input   logic                       rst_ni,

    input   logic                       master_req_i,
    input   logic     [       31:0]     master_addr_i,
    input   logic     [       31:0]     slave_addr_mask_i[SLAVES],
    input   logic     [       31:0]     slave_addr_base_i[SLAVES],

    output  logic  [SLAVE_BITS-1:0]     slave_sel_int_o
    );

    function integer onehot2int;
        input [SLAVES-1:0] onehot;
        integer i;

        onehot2int = 0; // prevent latch behavior

        for (i = 1; i < SLAVES; i = i + 1) begin: gen_int
            if (onehot[i]) begin
                onehot2int = i;
            end
        end
    endfunction

    genvar s;

    logic [SLAVES-1:0] slave_sel_vec;

    generate
        for (s = 0; s < SLAVES; s = s + 1) begin: gen_slave_sel_vec
            assign slave_sel_vec[s] = master_req_i & ((master_addr_i & slave_addr_mask_i[s]) == slave_addr_base_i[s]);
        end
    endgenerate

    assign slave_sel_int_o = onehot2int(slave_sel_vec);

endmodule
