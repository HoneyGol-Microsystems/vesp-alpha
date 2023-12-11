module synchronizerTest();

    reg clk;
    reg [1:0] dataIn;
    wire [1:0] dataOut;
    
    synchronizer # (
        .LEN(2),
        .STAGES(2)
    ) synchronizerInst(
        .clk(clk),
        .dataIn(dataIn),
        .dataOut(dataOut)
    );
   
    initial begin

        $display("Synchronizer test begin");
        clk = 0; 
        #2;

        $display("- Testing two stage synchronizer");
        // Shifting init values.
        dataIn = 3;
        #4;
        assert(dataOut === 3) else $fatal("Wrong output value.");

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