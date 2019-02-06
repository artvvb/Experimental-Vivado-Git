set repo_path [file normalize [file dirname [info script]]/../..]

# check if project is open, if not, open the project in the repo
if {[llength [get_projects]] == 0} {
	set xpr_paths [glob -nocomplain $repo_path/vivado/_workspace/*.xpr]
	if {[llength $xpr_paths] == 1} {
		open_project [lindex $xpr_paths 0]
	} elseif {[llength $xpr_paths] > 1} {
		puts "ERROR: more than one project found in $repo_path/vivado/_workspace"
		# TODO quit
	} else {
		puts "ERROR: no projects checked out cannot check in a non-existent project"
		# TODO quit
	}
}

# check if runs are complete
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!" \
	|| [get_property NEEDS_REFRESH [get_runs impl_1]] != 0                 \
} {
	puts "ERROR: write_bitsream not complete" 
	# TODO quit
}

set impl_dir [file normalize "$repo_path/vivado/_workspace/[current_project].runs/impl_1"]
set source_file_name [glob -nocomplain -tails -path $impl_dir/ *.sysdef]
if {[llength $source_file_name] != 1} {
	puts "ERROR: multiple or no sysdef files found"
	# TODO quit
}
set source_file [file normalize $repo_path/vivado/_workspace/[current_project].runs/impl_1/$source_file_name]
set target_file [file normalize $repo_path/sdk/handoff/[file rootname $source_file_name].hdf]

file copy -force $source_file $target_file

