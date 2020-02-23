`timescale 1 ns / 1 ps

`include "defines.v"

// testbench module
module tinyriscv_core_tb;

    reg clk;
    reg rst;

    always #10 clk = ~clk;     // 50MHz

    wire[`RegBus] x3 = u_tinyriscv_core.u_regs.regs[3];
    wire[`RegBus] x26 = u_tinyriscv_core.u_regs.regs[26];
    wire[`RegBus] x27 = u_tinyriscv_core.u_regs.regs[27];

    integer r;
    initial begin
        clk = 0;
        rst = `RstEnable;
        $display("test running...");
        #40
        rst = `RstDisable;
        #100
        wait(x26 == 32'b1)   // wait sim end, when x26 == 1
        #100
        if (x27 == 32'b1) begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        end else begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("fail testnum = %2d", x3);
            for (r = 0; r < 32; r++)
                $display("x%2d = 0x%x", r, u_tinyriscv_core.u_regs.regs[r]);
        end
        $finish;
    end

    // sim timeout
    initial begin
        #5000000
        $display("Time Out.");
        $finish;
    end

    // read mem data
    initial begin
        $readmemh ("inst.data", u_tinyriscv_core.u_sim_ram.ram);
    end

    // generate wave file, used by gtkwave
    initial begin
        $dumpfile("tinyriscv_core_tb.vcd");
        $dumpvars(0, tinyriscv_core_tb);
    end

    tinyriscv_core u_tinyriscv_core (
        .clk(clk),
        .rst(rst)
    );

endmodule
