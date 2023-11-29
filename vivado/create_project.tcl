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

# Creating a project.
create_project -force $project_name $project_path -part xc7a35tcpg236-1

# Setting up design sources.
# List of all files of the design. This is universally usable for both simulation and synthesis.
add_files -fileset sources_1 [ glob "./rtl/components/*.v" ]
add_files -fileset sources_1 [ glob "./rtl/primitives/*.v" ]
add_files -fileset sources_1 [ glob "./rtl/top/*.v" ]
add_files -fileset sources_1 "./rtl/constants.vh"
set_property is_global_include true [ get_files constants.vh ]

# Setting up constraints.
add_files -fileset constrs_1 "./synth/basys3/constraints.xdc"

# Setting up testbench/simulation sources.
add_files -fileset sim_1 "./tests/testConstants.vh"
set_property is_global_include true [ get_files testConstants.vh ]

# Update to set top and file compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Configure include directories.
set_property include_dirs "./" [get_fileset sources_1]