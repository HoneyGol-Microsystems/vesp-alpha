# VESP-α
This repository contains summer student project: RISC-V compatible processor.

## The main script (`make.py`)
This script is (for now) used mainly for launching tests.

### Setup
To use the script, install all required dependencies.

1. RISC-V toolchain
2. iverilog
3. Python version >=3.10 (older versions not officially supported)

### Usage

Launch this script directly:
```sh
./make.py
```

or using Python
```sh
python3 make.py
```

### Testing
All tests can be launched using
```sh
./make.py test
```
This command will run all tests (using all the *recipes* in the `recipes` directory) on current version of the CPU located in the repository.

Test routines are defined using a *recipe*, which is a custom YAML-based file describing all steps that should be performed and how are test results interpreted (how to recognize success or failure). A tutorial on creating a recipe is located in [docs/recipes.md](docs/recipes.md). 

To run specific recipe, use the `--recipe` switch. You can also pass custom sources to be used with the recipe instead default ones (which are specified in the recipe) using `--sources`. For example, if you want to run a single official RISC-V test, use the `rvtest.yaml` recipe and specify your desired hex file like this:
```sh
./make.py test --recipe recipes/rvtest.yaml --sources tests/riscv-tests-hex/rv32ui-p-add.hex
```

Of course, only files compatible with the selected recipe will work. Trying to run hex files using Hardware Test (hwtest.yaml) recipe will obviously not work. See list below for currently available recipes:
- `rvtest.yaml`: This recipe runs pre-compiled official RISC-V tests in simulation using iverilog.
- `hwtest.yaml`: This recipe runs custom Verilog-based tests mainly used to test separate components.

### Cleaning
You can remove all generated content using:
```sh
./make.py clean
```

## Official test suite - handling success/failure
*This section is mainly meant as a documentation of the official tests' inner workings for our future reference, because there is none in the official repository.*

Official test suite always at the end of the test executes `ecall` instruction. This causes an exception, so the execution is redirected to the `trap_vector`, from where it branches to the `write_tohost`. In this routine, test number and result is written to a special memory-mapped register `tohost` (used by the Spike).

This gets interistingly more complicated when the exceptions themselves are tested. `ebreak` test causes a jump to `trap_vector` but from there it jumps to `mtvec_handler` (for M-mode tests). Every test may define its own `mtvec_handler`. For example, the `ebreak` test checks for the exception code in the `mcause` register in this routine and then the `ecall` is executed, again causing a redirection to the `trap_vector` and `write_tohost`.

To sum up, here are visualizations:

Normal program flow:
```
_start => reset_vector => (the test routines) => trap_vector => write_tohost
```

This is a flow of tests which test exceptions:
```
_start => reset_vector => (the test routines) => trap_vector => mtvec_handler => trap_vector => write_tohost
```

### Our modifications
Because for now there are no memory-mapped peripherals in our implementation, we can't use the `tohost` mechanism to check the status of the tests. To overcome this limitation, we detect success and failure using officially unused opcodes:
- 0x0 for failure,
- 0x1 for success.

We effectively disable the `write_tohost` routine altogether, because it is only called in the `trap_vector` when the exception is caused by the `ecall`. 

Using special opcodes instead of the `tohost` mechanism is fine for all other tests but not for the test where the `ecall` instruction itself is tested (rv32mi-p-scall). To detect a success in this test we abuse the `write_tohost` routine to signalize the result using the aforementioned 0x1 opcode. This can be done, because as it was mentioned, `write_tohost` is not used anywhere else in our modification of the test result handling.

## Creating testbenches
Testbenches must not contain Verilog's `$dumpfile` and `$dumpvars`, otherwise no VCD will be created by Vivado!

## Importing to Vivado Design Suite
1. Create a new project
2. Add directory src (do not forget to tick "include subdirectories")
3. Add root directory as Verilog include path:
  - In Vivado GUI: `Tools > Settings > General > Verilog options > Verilog Include Files Search Paths`
  - See [help article](https://support.xilinx.com/s/article/54006?language=en_US)

## (IS NOT CURRENT - WILL BE REDONE) Compiling assembly source code to hex format and deploying to FPGA
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
        .a1(iAddr),
        .do1(iRead),

        .a2(dAddr),
        .di2(dWrite),
        .do2(dRead),
        .m2(dMask),
        .we2(dWE),
        .clk(clk)
    );
   ```
   Now, the module `src/components/top.v`, including the CPU and RAM is ready for deploying onto the FPGA with the specified `.S` program.
