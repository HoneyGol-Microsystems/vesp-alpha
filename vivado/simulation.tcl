# ########################## 
# Vivado simulation script
# ##########################
# Using project mode.
#
# Arguments
# argv[0]: path to test top
# argv[1]: test top name
# argv[2]: another file to add (e.g. hex executable)

# Defining default value for parameters.
set test_file [lindex $argv 0]
set test_top_name [lindex $argv 1]
set another_file [lindex $argv 2]

# Creating a temp project.
# Command line args have to be passed in this goofy way sadly.
set argc 2
set argv [list ./build/vivado sim_temp]
source ./vivado/create_project.tcl

# Setting up test-specific sources.
add_files $test_file

# Add another file if specified.
if { $another_file ne "" } {
    add_files -fileset sim_1 -norecurse $another_file
}

set_property top $test_top_name [get_fileset sim_1]
launch_simulation -simset sim_1 -mode behavioral
# Restart is needed to dump VCDs properly.
restart
open_vcd sim.vcd
# Log everything.
log_vcd -level 0 [ get_scopes /* ]
run -all
flush_vcd
close_vcd
close_project
quit

# This command can be used to check whether is the constants.vh correctly set as global include.
# report_property [ get_files constants.vh ]
# Or we can simple open the GUI.