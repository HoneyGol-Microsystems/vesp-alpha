`include "rtl/components/top.v"
`include "rtl/constants.vh"

module topTestStrlen();
    reg clk, reset;                // declaring two variables: clk and reset
    top dut (                      // creating an instance of module top (see Figure 3)
        .clk(clk),                 // port mapping: connect variable clk to input port clk
        .reset(reset)              // port mapping: connect variable reset to input port reset
    );
    initial begin                  // begining of "initial block"
        $dumpfile("test.vcd");     // create a file test.vcd to store simulation results
        $dumpvars;                 // dump everything into test.vcd 
        $readmemh("tests/strlen-test-hex/instr_mem.hex", dut.instrMem.ram, 0, 9-1);
        $readmemh("tests/strlen-test-hex/data_mem.hex", dut.dataMem.ram, 0, 9-1);
        reset <= 1; #1; reset <= 0; #99;  // set stimulus for reset as it evolves in time
        $finish;                          // finish the simulation
    end
    always begin                          // begining of "always block"
        clk <= 1; #1; clk <= 0; #1;       // set stimulus for clk as it evolves in time
    end
endmodule