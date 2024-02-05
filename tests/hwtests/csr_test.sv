`include "rtl/components/csr.sv"
`include "tests/test_constants.vh"

module module_csr_test();

    logic reset, clk, we, mepc_we, mcause_we;
    logic [11:0] a;
    logic [31:0] din, dout, mepc_dout, mtvec_dout, mcause_dout, mepc_din, mcause_din;

    module_csr csr (
        .reset(reset),
        .clk(clk),
        .we(we),
        .a(a),
        .din(din),
        .dout(dout),
        .mepc_dout(mepc_dout),
        .mtvec_dout(mtvec_dout),
        .mcause_dout(mcause_dout),
        .mepc_we(mepc_we),
        .mcause_we(mcause_we),
        .mepc_din(mepc_din),
        .mcause_din(mcause_din)
    );
   
    initial begin

        $display("CRS test begin");
        clk = 0;
        #2;

        $display("- Testing default values");
        reset = 1;
        #2;

        `ASSERT(mtvec_dout === 0 && mepc_dout === 0 && mcause_dout === 0, "Error!");

        reset = 0;
        @(posedge clk);

        $display("- Main I/O reads");
        a = 'h301;
        #0;
        `ASSERT(dout === 'b01000000000000000000000100000000, "0x301 read error!")

        a = 'h305;
        #0;
        `ASSERT(dout === 0, "0x305 read error!")

        a = 'h341;
        #0;
        `ASSERT(dout === 0, "0x341 read error!")

        // Waiting for CLK to fall to disable writes.
        @(negedge clk);

        $display("- Main I/O reads + writes");
        a  = 'h301;
        we = 0;
        din = 420;
        #2;
        `ASSERT(dout === 'b01000000000000000000000100000000, "0x301 unexpected write!");
        
        we = 1;
        #2;
        `ASSERT(dout === 'b01000000000000000000000100000000, "0x301 unexpected write!");
        
        a  = 'h305;
        we = 0;
        din = 'b1111_1100;
        #2;
        `ASSERT(dout === 0, "0x305 unexpected write!");

        we = 1;
        #2;
        `ASSERT(dout === 'b1111_1100, "0x305 write error");

        din = 'b1111_1111;
        #2;
        `ASSERT(dout === 'b1111_1100, "0x305 unexpected write!");

        din = 'b1111_1110;
        #2;
        `ASSERT(dout === 'b1111_1100, "0x305 unexpected write!");

        din = 'b1111_1101;
        #2;
        `ASSERT(dout === 'b1111_1101, "0x305 write error!");

        a = 'h340;
        we = 0;
        #2;
        `ASSERT(dout === 0, "0x340 unexpected write!");
        
        we = 1;
        din = 45446848;
        #2
        `ASSERT(dout === 45446848, "0x340 write error!");

        a = 'h341;
        we = 0;
        #2;
        `ASSERT(dout === 0, "0x341 unexpected write!");
        we = 1;
        din = 86492168;
        #2;
        `ASSERT(dout === 86492168, "0x341 write error!");

        a = 'h342;
        we = 1;
        din = 508943;
        #2;
        `ASSERT(dout === 0, "0x342 unexpected write!");

        mepc_we = 1;
        mepc_din = 80;
        #2;
        `ASSERT(mepc_dout === 80, "mempcDo write error!");

        mepc_we = 0;
        mepc_din = 0;
        #2;
        `ASSERT(mepc_dout === 80, "mempcDo unexpected write!");

        mcause_we = 1;
        mcause_din = 986;
        #2;
        `ASSERT(mcause_dout === 986, "mcause_din write error!");

        mcause_we = 0;
        mcause_din = 20;
        #2;
        `ASSERT(mcause_dout === 986, "mcause_din unexpected write!")

        $display(`ASSERT_SUCCESS);
		#1; $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

endmodule