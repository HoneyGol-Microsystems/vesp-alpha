`include "rtl/components/csr.v"
`include "tests/testConstants.vh"

module csrTest();

    reg reset;
    reg clk;
    reg we;
    reg [11:0] a;
    reg [31:0] di;
    wire [31:0] do;

    wire [31:0] mepcDo, mtvecDo, mcauseDo;
    reg mepcWe, mcauseWe;
    reg [31:0] mepcDi, mcauseDi;

    csr csrInst(
        .reset(reset),
        .clk(clk),
        .we(we),
        .a(a),
        .di(di),
        .do(do),
        .mepcDo(mepcDo),
        .mtvecDo(mtvecDo),
        .mcauseDo(mcauseDo),
        .mepcWe(mepcWe),
        .mcauseWe(mcauseWe),
        .mepcDi(mepcDi),
        .mcauseDi(mcauseDi)
    );
   
    initial begin
		$dumpfile("test");
		$dumpvars;

        $display("CRS test begin");
        clk = 0;
        #2;

        $display("- Testing default values");
        reset = 1;
        #2;

        `ASSERT(mtvecDo === 0 && mepcDo === 0 && mcauseDo === 0, "Error!");

        reset = 0;
        @(posedge clk);

        $display("- Main I/O reads");
        a = 'h301;
        #0;
        `ASSERT(do === 'b01000000000000000000000100000000, "0x301 read error!")

        a = 'h305;
        #0;
        `ASSERT(do === 0, "0x305 read error!")

        a = 'h341;
        #0;
        `ASSERT(do === 0, "0x341 read error!")

        // Waiting for CLK to fall to disable writes.
        @(negedge clk);

        $display("- Main I/O reads + writes");
        a  = 'h301;
        we = 0;
        di = 420;
        #2;
        `ASSERT(do === 'b01000000000000000000000100000000, "0x301 unexpected write!");
        
        we = 1;
        #2;
        `ASSERT(do === 'b01000000000000000000000100000000, "0x301 unexpected write!");
        
        a  = 'h305;
        we = 0;
        di = 'b1111_1100;
        #2;
        `ASSERT(do === 0, "0x305 unexpected write!");

        we = 1;
        #2;
        `ASSERT(do === 'b1111_1100, "0x305 write error");

        di = 'b1111_1111;
        #2;
        `ASSERT(do === 'b1111_1100, "0x305 unexpected write!");

        di = 'b1111_1110;
        #2;
        `ASSERT(do === 'b1111_1100, "0x305 unexpected write!");

        di = 'b1111_1101;
        #2;
        `ASSERT(do === 'b1111_1101, "0x305 write error!");

        a = 'h340;
        we = 0;
        #2;
        `ASSERT(do === 0, "0x340 unexpected write!");
        
        we = 1;
        di = 45446848;
        #2
        `ASSERT(do === 45446848, "0x340 write error!");

        a = 'h341;
        we = 0;
        #2;
        `ASSERT(do === 0, "0x341 unexpected write!");
        we = 1;
        di = 86492168;
        #2;
        `ASSERT(do === 86492168, "0x341 write error!");

        a = 'h342;
        we = 1;
        di = 508943;
        #2;
        `ASSERT(do === 0, "0x342 unexpected write!");

        mepcWe = 1;
        mepcDi = 80;
        #2;
        `ASSERT(mepcDo === 80, "mempcDo write error!");

        mepcWe = 0;
        mepcDi = 0;
        #2;
        `ASSERT(mepcDo === 80, "mempcDo unexpected write!");

        mcauseWe = 1;
        mcauseDi = 986;
        #2;
        `ASSERT(mcauseDo === 986, "mcauseDi write error!");

        mcauseWe = 0;
        mcauseDi = 20;
        #2;
        `ASSERT(mcauseDo === 986, "mcauseDi unexpected write!")

        $display(`ASSERT_SUCCESS);
		#1; $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

endmodule