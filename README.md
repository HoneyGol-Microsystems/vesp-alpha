# RISC-V Student CPU
This repository contains summer student project: RISC-V compatible processor.

## Testing
Testing is done using Icarus Verilog and provided Python 3 script: `make.py`.

Run `python3 make.py test` to run all tests.

## Importing to Vivado Design Suite
1. Create a new project
2. Add directory src (do not forget to tick "include subdirectories")
3. Add root directory as Verilog include path:
  - In Vivado GUI: `Tools > Settings > General > Verilog options > Verilog Include Files Search Paths`
  - See [help article](https://support.xilinx.com/s/article/54006?language=en_US)

## Compiling assembly source code to hex format and deploying to FPGA
1. Create `.S` source file starting with `_start`:
   ```asm
   .global _start
   _start:
          # insert your code here
   ```
2. To compile your `.S` source file, run the script `asmtohex.sh` located in `scripts/` directory and supply two arguments - **location of `.S` files** and **dest location for the `.hex` files**:
   ```sh
   ./scripts/asmtohex.sh <path_to_asm> <dest_for_hex>
   ```
3. The created `.hex` files can be loaded straight to the FPGA. To do that, open the file `src/components/top.v` and supply the path of the `.hex` file to the parameter `MEM_FILE` inside the `ramInst` module instance:
   ```verilog
   ram #(
        .WORD_CNT(`RAM_WORD_CNT),
        .MEM_FILE("INSERT THE PATH HERE")
    ) ramInst (
        .a1(instrBusAddr),
        .do1(instrBusData),

        .a2(dataBusAddr),
        .di2(dataBusDataWrite),
        .do2(dataBusDataRead),
        .m2(writeMask),
        .we2(dataBusWE),
        .clk(sysClk)
    );
   ```
   Now, the module `src/components/top.v`, including the CPU and RAM is ready for deploying onto the FPGA with the specified `.S` program.