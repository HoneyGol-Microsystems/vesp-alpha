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

## Compilation of user programs
User programs can be written in C or using assembly (with `.S` suffix, not `.s`). Executables of these programs can be generated in two ways:
1. compiling program as **standalone** - the final executable will not contain any platform specific code (startup or firmware libraries),
2. compiling program as **firmware** - startup code and VESP firmware library will be linked together with the user program.

The user programs have to fulfill a certain structure - for more information on this, see [Writing programs for available targets](#writing-programs-for-available-targets). These programs can be compiled using the [main Makefile](software/Makefile), where `standalone` and `firmware` targets are implemented - see [Using the Makefile](#using-the-makefile) on how to use it.

### Writing programs for available targets
#### Standalone
Using assembly for writing standalone programs is recommended over C. Prerequisite for running C program is an initialized stack pointer, which is usually done by the startup code. Thus, for writing C programs, the `firmware` target is recommended.

The assembly program should define symbol `_start` as shown below:
```asm
.global _start
_start:
   # insert your code here
```

#### Firmware
Using C for writing firmware programs is recommended, but assembly can also be used.

The assembly program shouldn't define symbol `_start`, because it is already defined in the startup code. However, `main` symbol has to be defined and used as shown below:
```asm
.global main
main:
   # insert your code here
```
Similarly, the C program should contain the `main()` function, where all the code is put:
```c
int main ( void )
{
   // insert your code here
   return 0;
}
```
If any functionalities are needed from the VESP firmware library, just include it with:
```c
#include <vesp.h>
```
The `vesp.h` header includes all of the headers from the VESP library, so that other headers don't have to be manually included.

### Using the Makefile
Input programs are compiled using the RISC-V GCC and linked according to the [mem.ld](software/common/mem.ld) linker script, which creates `.text` and `.data` sections, both starting at address 0 and thus prepared for the Harvard memory architecture.

Executable can be created with these steps:
1. switch to `software/` directory, where the `Makefile` is located,
2. specify one of the **targets** (`standalone` or `firmware`) and supply a **path to the top level user program** through the command line argument:
   ```sh
   make <chosen-target-name> SRC=<path-to-the-user-program>
   ```
The final executable can be found in the current directory and is called either `standalone.elf` or `firmware.elf`, depending on the chosen target. A memory map file called `memory.map` is also created in the current directory for debugging purposes.

To remove all of the files created along the way, simply run:
   ```sh
   make clean
   ```

## Creating `.hex` files from the executable
Compiled executables can be transformed into `.hex` files using the [elftohex.py](scripts/elftohex.py) script. The dependencies are listed below:
- Python version >=3.10,
- RISC-V toolchain,
- `pax-utils` package.

To create the `.hex` file(s), run the script and supply three arguments - **location of executable(s)**, **destination location for the** `.hex` **file(s)** and **memory architecture** - `von-neumann` or `harvard`:
   ```sh
   python3.12 ./scripts/elftohex.py -s <path-to-executables> -d <dest-path-for-hex> -m <memory-architecture>
   ```
If `von-neumann` architecture is specified, corresponding `*.hex` file will be created with the same name as the executable has and if `harvard` architecture is specified, `*_text.hex` and `*_data.hex` will be created. For more information about the script, run it with `-h` or `--help`.

## Deploying on FPGA
The created `.hex` files can be loaded straight to the FPGA. To do that, open [top.v](rtl/components/top.v) and supply a **path of the** `*_text.hex` **and** `*_data.hex` **files** to the parameters `MEM_FILE` of the **instruction** and the **data** memory module instances:
```verilog
instructionMemory #(
   .WORD_CNT(`INSTR_MEM_WORD_CNT),
   .MEM_FILE("*_text.hex")
) instrMemInst (
   .a(iAddr),
   .d(iRead)
);

dataMemory #(
   .WORD_CNT(`DATA_MEM_WORD_CNT),
   .MEM_FILE("*_data.hex")
) dataMemInst (
   .clk(clk),
   .we(dWE),
   .mask(dMask),
   .a(dAddr),
   .di(dWrite),
   .do(dRead)
);
```
If needed, the `INSTR_MEM_WORD_CNT` and `DATA_MEM_WORD_CNT` values can be changed in the [constants.vh](rtl/constants.vh) file.

Now, the module top.v, including the CPU and instruction/data memories, is ready for deploying on the FPGA with the specified `.hex` files.

### Importing to Vivado Design Suite
1. Create a new project
2. Add directory src (do not forget to tick "include subdirectories")
3. Add root directory as Verilog include path:
  - In Vivado GUI: `Tools > Settings > General > Verilog options > Verilog Include Files Search Paths`
  - See [help article](https://support.xilinx.com/s/article/54006?language=en_US)