(* dont_touch = "yes" *) module module_fifo #(
    parameter XLEN    = 32,
    parameter LENGTH  = 16
) (
    input  logic            clk,
    input  logic            reset,
    input  logic            we,
    input  logic            re,
    input  logic [XLEN-1:0] din,

    output logic            empty,
    output logic            full,
    output logic [XLEN-1:0] dout
);

    logic [$clog2(LENGTH) - 1:0] front_pointer, back_pointer,
                                 front_pointer_inc, back_pointer_inc;
    logic [XLEN-1:0] memory [LENGTH-1:0];

    always_ff @(posedge clk) begin : fifo_operations
        if (reset) begin
            front_pointer <= 0;
            back_pointer  <= 0;
            empty         <= 1;
            full          <= 0;
        end else begin        
            if (we && !full) begin
                memory[back_pointer] <= din;
                back_pointer         <= back_pointer_inc;
                empty                <= 0;

                if (!re) begin
                    full <= (front_pointer == back_pointer_inc) ? 1'b1 : 1'b0;
                end
            end

            if (re && !empty) begin
                front_pointer <= front_pointer_inc;

                if (!we) begin
                    empty <= (front_pointer_inc == back_pointer) ? 1'b1 : 1'b0;
                    full  <= 0;
                end
            end
        end
    end

    assign dout = memory[front_pointer];

    // Incrementation needs to be separated to keep correct width when comparing.
    assign front_pointer_inc = front_pointer + 1;
    assign back_pointer_inc  = back_pointer  + 1;

endmodule