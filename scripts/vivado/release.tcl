set repo_path [file normalize [file dirname [info script]]/../..]

# check if project is open
if {[llength [get_projects]] == 0} {
	set xpr_paths [glob -nocomplain ${repo_path}/vivado/_workspace/*.xpr]
	if {[llength $xpr_paths] == 1} {
		open_project [lindex $xpr_paths 0]
	} elseif {[llength $xpr_paths] > 1} {
		puts "ERROR: more than one project found in ${repo_path}/vivado/_workspace"
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

set repo_dir [file dirname [file dirname [info script]]]
if {[file exists $repo_dir/_release] == 0} {
	file mkdir $repo_dir/_release
}

set idx 0
while {[file exists ${repo_dir}/_release/vivado_${idx}] != 0} {incr idx}
set release_dir ${repo_dir}/_release/vivado_${idx}

set zip_path ${release_dir}/vivado_project.zip
#TODO decide whether to auto clean up temp directory
set temp_path ${release_dir}/temp

archive_project $zip_path -temp_dir $temp_path -force -include_local_ip_cache