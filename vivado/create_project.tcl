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

# Try to open an existing project.
if { [ catch { open_project "${project_path}/${project_name}.xpr" } error_str ]  } {

    puts $error_str
    # No project found - creating a project.
    puts "No project found, creating a new one..."
    create_project $project_name $project_path -part xc7a35tcpg236-1

    # Setting up design sources.
    # List of all files of the design. This is universally usable for both simulation and synthesis.
    # This command will recursively search through rtl folder and all its subdirectories.
    add_files -fileset sources_1 "./rtl"
    set_property is_global_include true [ get_files constants.vh ]

    # Setting up constraints.
    add_files -fileset constrs_1 "./synth/basys3/constraints.xdc"

    # Setting up testbench/simulation sources.
    add_files -fileset sim_1 "./tests/test_constants.vh"
    set_property is_global_include true [ get_files test_constants.vh ]
} else {
    # All good.
    puts "An existing project found."
}

# Update to set top and file compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Configure include directories.
set_property include_dirs "./" [get_fileset sources_1]