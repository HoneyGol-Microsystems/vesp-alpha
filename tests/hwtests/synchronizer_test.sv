module module_synchronizer_test();

    logic       clk;
    logic       en;
    logic [1:0] data_in;
    logic [1:0] data_out;
    logic [1:0] rise;
    logic [1:0] fall;

    logic [1:0] calculated_rise;
    logic [1:0] calculated_fall;

    task write_and_test_task(
        integer value_to_write
    );
        data_in = value_to_write;
        calculated_rise = ~data_out & data_in;
        calculated_fall = data_out & ~data_in;

        #4;
        assert(rise === calculated_rise)    else $fatal("Wrong rise value.");
        assert(fall === calculated_fall)    else $fatal("Wrong fall value.");
        assert(data_out === value_to_write)  else $fatal("Wrong output value.");
    endtask

    module_synchronizer #(
        .LEN(2),
        .STAGES(2)
    ) synchronizer (
        .en(en),
        .clk(clk),
        .data_in(data_in),
        .data_out(data_out),
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
        data_in = 0;
        #4;
        assert(data_out === 0) else $fatal("Wrong output value.");

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