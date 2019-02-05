# TODO check if project open

if {[llength [get_projects]] == 0} {
	set repo_path [file dirname [file dirname [file dirname [info script]]]]
	set xpr_paths [glob -nocomplain ${repo_path}/vivado/_workspace/*.xpr]
	if {[llength $xpr_paths] == 1} {
		open_project [lindex $xpr_paths 0]
	} elseif {[llength $xpr_paths] > 1} {
		puts "ERROR: more than one project found in ${repo_path}/vivado/_workspace"
		# TODO quit
	} else {
		puts "ERROR: no projects checked out, please source ${repo_path}/scripts/vivado/checkout.tcl"
		# TODO quit
	}
}
# else use current_project

# check if runs are complete
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!" \
	|| [get_property NEEDS_REFRESH [get_runs impl_1]] != 0                 \
} {
	launch_runs impl_1 -to_step write_bitstream -jobs 12
	wait_on_runs
	puts "INFO: write_bitstream complete"
} else {
	puts "INFO: write_bitsream already complete" 
}

