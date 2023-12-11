module synchronizerTest();

    logic       clk;
    logic       en;
    logic [1:0] dataIn;
    logic [1:0] dataOut;
    logic [1:0] rise;
    logic [1:0] fall;

    logic [1:0] calculated_rise;
    logic [1:0] calculated_fall;

    task write_and_test_task(
        integer value_to_write
    );
        dataIn = value_to_write;
        calculated_rise = ~dataOut & dataIn;
        calculated_fall = dataOut & ~dataIn;

        #4;
        assert(rise === calculated_rise)    else $fatal("Wrong rise value.");
        assert(fall === calculated_fall)    else $fatal("Wrong fall value.");
        assert(dataOut === value_to_write)  else $fatal("Wrong output value.");
    endtask

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

        write_and_test_task(2);
        write_and_test_task(1);
        write_and_test_task(3);
        write_and_test_task(0);

        $display("ASSERT_SUCCESS");
		#1; $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

endmodule