# get the directory where this script resides
set script_root [file dirname [info script]]

# set root directory
set root_dir $script_root/..

# open project
open_project $root_dir/project/riscv_cpu.xpr

# implement & write bitstream
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# close project
close_project

# touch a file so that make utility will know it's done
exec touch .compile.done