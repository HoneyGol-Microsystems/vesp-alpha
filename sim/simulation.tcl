# ########################## 
# Vivado simulation script
# ##########################
# Using non-project mode.
#

# Defining default value for parameters.
set output_directory ./build/vivado

# Preparing environment.
file mkdir $output_directory

# Setting up sources.
read_verilog [ glob "./rtl/components/*.v" ]
read_verilog [ glob "./rtl/primitives/*.v" ]
read_verilog "./rtl/constants.vh"
read_verilog "./tests/hwtests/fifoTest.v"
read_verilog "./tests/testConstants.vh"

save_project_as -force sim_proj build/vivado
set_property is_global_include true [ get_files constants.vh ]
set_property is_global_include true [ get_files testConstants.vh ]
set_property top fifoTest [get_fileset sim_1]
set_property include_dirs "./" [get_fileset sim_1]
# launch_simulation -simset sim_1 -mode behavioral
open_vcd sim.vcd
log_vcd -level 0 [ get_objects /fifoTest/* ]
log_vcd -level 0 [ get_objects /fifoTest/fifoInst/* ]
# run
flush_vcd
close_vcd
quit


# This command can be used to check whether is the constants.vh correctly set as global include.
# report_property [ get_files constants.vh ]

# Running simulation.
