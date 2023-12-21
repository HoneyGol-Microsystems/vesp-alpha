# VESP Development
Here are described some development related things not covered by main README.

## VS Code syntax highlighting and linting
To support these things, you need to install [Verilog-HDL/SystemVerilog/Bluespec SystemVerilog](https://marketplace.visualstudio.com/items?itemName=mshr-h.VerilogHDL) addon.

Syntax highlighting will be enabled automatically. To support real-time linting, you have to pick a linter in the addon's settings (check its manual). We recommend using xvlog, which is a Vivado linter. The xvlog is larger and slower than iverilog, but supports more precise error reporting and SystemVerilog. Icarus Verilog (iverilog) is not a suitable choice for newest version of the project mainly because the lack of SystemVerilog support. Other linters were not tested.
