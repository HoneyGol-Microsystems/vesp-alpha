# ########################## 
# Vivado simulation script
# ##########################
# Using non-project mode.
#

# Defining default value for parameters.
set output_directory ./build/vivado
set test_file [lindex $argv 0]

# Preparing environment.
file mkdir $output_directory

# Setting up sources.
source ./sim/common/design_filelist.tcl
read_verilog $test_file
read_verilog "./tests/testConstants.vh"

save_project_as -force sim_proj build/vivado
set_property is_global_include true [ get_files testConstants.vh ]
set_property top fifoTest [get_fileset sim_1]
set_property include_dirs "./" [get_fileset sim_1]
launch_simulation -simset sim_1 -mode behavioral
restart
open_vcd sim.vcd
log_vcd -level 0 [ get_scopes /fifoTest ]
run
flush_vcd
close_vcd
quit


# This command can be used to check whether is the constants.vh correctly set as global include.
# report_property [ get_files constants.vh ]
# Or we can simple open the GUI.