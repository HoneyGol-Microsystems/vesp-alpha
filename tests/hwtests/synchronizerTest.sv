module synchronizerTest();

    logic       clk;
    logic       en;
    logic [1:0] dataIn;
    logic [1:0] dataOut;
    logic [1:0] rise;
    logic [1:0] fall;
    
    synchronizer # (
        .LEN(2),
        .STAGES(2)
    ) synchronizerInst(
        .en(en),
        .clk(clk),
        .dataIn(dataIn),
        .dataOut(dataOut),
        .rise(rise),
        .fall(fall)
    );
   
    initial begin

        $display("Synchronizer test begin");
        clk = 0; 
        en  = 1;
        #2;

        $display("- Testing two stage synchronizer");
        $display("Pushing init value (0).");
        dataIn = 0;
        #4;
        assert(dataOut === 0) else $fatal("Wrong output value.");

        dataIn = 2;
        #4;
        assert(rise == 2'b10)  else $fatal("Wrong rise value.");
        assert(dataOut === 2) else $fatal("Wrong output value.");

        dataIn = 0;
        #4;
        assert(dataOut === 0) else $fatal("Wrong output value");

        $display("ASSERT_SUCCESS");
		#1; $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

endmodule