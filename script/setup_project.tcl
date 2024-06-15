# get the directory where this script resides
set script_root [file dirname [info script]]

# set root directory
set root_dir $script_root/..

# set root directories
set src_root $root_dir/source
set constr_root $root_dir/constraint
set sim_root $root_dir/simulation
set mem_init_file_root $root_dir/program/binary

# create project
create_project -force riscv_cpu $root_dir/project -part xc7k325tffg676-2L

# set project properties
set project [get_projects riscv_cpu]
set_property -dict {"target_language" "Verilog" "simulator_language" "Mixed"} $project

# add files
add_files $src_root
add_files -fileset constrs_1 $constr_root
add_files -fileset sim_1 $sim_root
# vivado has trouble adding mem files, therefore we do it manually
add_files [glob $mem_init_file_root/*.mem]

# set top
set_property top soc [current_fileset]
set_property top cpu_sim [get_filesets sim_1]

# close project
close_project

# touch a file so that make utility will know it's done
exec touch .setup.done