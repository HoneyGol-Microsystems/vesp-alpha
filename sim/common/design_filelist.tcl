###################################
# Design file list
# #################################
# List of all files of the design. This is universally usable for both simulation and synthesis.
read_verilog [ glob "./rtl/components/*.v" ]
read_verilog [ glob "./rtl/primitives/*.v" ]
read_verilog "./rtl/constants.vh"
set_property is_global_include true [ get_files constants.vh ]