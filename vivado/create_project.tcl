# ################################
# Vivado project generator script
# ################################
#
# Arguments
# argv[0]: path to project directory
# argv[1]: project name

# Parse arguments.
set project_path [lindex $argv 0]
set project_name [lindex $argv 1]

# Setting up design sources.
# List of all files of the design. This is universally usable for both simulation and synthesis.
read_verilog [ glob "./rtl/components/*.v" ]
read_verilog [ glob "./rtl/primitives/*.v" ]
read_verilog "./rtl/constants.vh"
set_property is_global_include true [ get_files constants.vh ]

# Settings up testbench/simulation sources.
read_verilog "./tests/testConstants.vh"
set_property is_global_include true [ get_files testConstants.vh ]

# Create a project.
save_project_as -force $project_name $project_path

# Configure include directories.
set_property include_dirs "./" [get_fileset sim_1]