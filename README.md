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