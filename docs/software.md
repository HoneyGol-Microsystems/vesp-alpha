# Software
This document describes compiling and running user programs on the VESP.

## Compilation of user programs
User programs can be written in C or using assembly (with `.S` suffix, not `.s`). Executables of these programs can be generated in two ways:
1. compiling program as **standalone** - the final executable will not contain any platform specific code (startup or firmware libraries),
2. compiling program as **firmware** - startup code and VESP firmware library will be linked together with the user program.

The user programs have to fulfill a certain structure - for more information on this, see [Writing programs for available targets](#writing-programs-for-available-targets). These programs can be compiled using the [main Makefile](/software/Makefile), where `standalone` and `firmware` targets are implemented - see [Using the Makefile](#using-the-makefile) on how to use it.

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
Input programs are compiled using the RISC-V GCC and linked according to the [mem.ld](/software/common/mem.ld) linker script, which creates `.text` and `.data` sections, both starting at address 0 and thus prepared for the Harvard memory architecture.

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

## Creating `.mem` files from the executable
Compiled executables can be transformed into `.mem` files using the [elftohex.py](/scripts/elftohex.py) script. The dependencies are listed below:
- Python version >=3.10,
- RISC-V toolchain,
- `pax-utils` package.

To create the `.mem` file(s), run the script and supply three arguments - **location of executable(s)**, **destination location for the** `.mem` **file(s)** and **memory architecture** - `von-neumann` or `harvard`:
   ```sh
   python3.12 ./scripts/elftohex.py -s <path-to-executables> -d <dest-path-for-mem-file(s)> -m <memory-architecture>
   ```
If `von-neumann` architecture is specified, corresponding `*.mem` file will be created with the same name as the executable has and if `harvard` architecture is specified, `*_text.mem` and `*_data.mem` will be created. For more information about the script, run it with `-h` or `--help`.

## Deploying on FPGA
The created `.mem` files can be loaded straight to the FPGA. To do that, open [top.sv](/rtl/components/top.sv) and supply a **path to the** `*_text.mem` **and** `*_data.mem` **files** to the parameters `MEM_FILE` of the **instruction** and the **data** memory module instances:
```verilog
module_instruction_memory #(
   .WORD_CNT(`INSTR_MEM_WORD_CNT),
   .MEM_FILE("software/firmware_text.mem")
) instruction_memory (
   .a(i_addr),

   .d(i_read)
);

module_data_memory #(
   .WORD_CNT(`DATA_MEM_WORD_CNT),
   .MEM_FILE("software/firmware_data.mem")
) data_memory (
   .clk(clk),
   .we(d_we),
   .mask(d_mask),
   .a(d_addr),
   .din(d_write),

   .dout(data_mem_dout)
);
```
If needed, the `INSTR_MEM_WORD_CNT` and `DATA_MEM_WORD_CNT` values can be changed in the [constants.vh](/rtl/constants.vh) file.

Now, the global top module [vesp_top.sv](/rtl/top/vesp_top.sv), which connects `top.sv`, synchronises `reset` signal and divides clock frequency using this [PLL template](https://docs.xilinx.com/r/en-US/ug953-vivado-7series-libraries/PLLE2_BASE) is ready for bitstream generation. To create a Vivado project with this top module, see [Creating a Vivado project](/README.md#creating-a-vivado-project).
