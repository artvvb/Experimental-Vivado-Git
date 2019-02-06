#TODO check if workspace open, if not, open it
#TODO copy required scripts and files from scripts and sdk/_workspace

# move sources from sdk/handoff/*.hdf -> _release/sdk/handoff/*.hdf
# move sources from sdk/_workspace/ to _release/projects

# do the same stuff as in checkin (move projects from repo/sdk/_workspace to repo/_release/sdk/projects
set repo_dir [file normalize [file dirname [info script]]/../..]
set scripts_dir $repo_dir/scripts
set workspace_dir $repo_dir/sdk/_workspace

if {[file exists $repo_dir/_release] == 0} {file mkdir $repo_dir/_release}

set idx 0
while {[file exists $repo_dir/_release/sdk_$idx] != 0]} {incr idx}
set release_dir $repo_dir/_release/sdk_${idx}
file mkdir $release_dir
file mkdir $release_dir/projects
file mkdir $release_dir/hw_handoff
file mkdir $release_dir/scripts
file mkdir $release_dir/scripts/vivado
file copy -force $scripts_dir/vivado/sdk_checkout.tcl $release_dir/scripts/vivado/sdk_checkout.tcl
file mkdir $release_dir/scripts/xsct
file copy -force $scripts_dir/xsct/checkout.tcl $release_dir/scripts/xsct/checkout.tcl
set handoff_file [glob -nocomplain $repo_dir/sdk/handoff/*.hdf]
if {[llength $handoff_file] != 1} {
	puts "ERROR: more than one handoff detected"
	#TODO quit
}
set handoff_file [lindex $handoff_file 0]
file copy -force $handoff_file $release_dir/handoff/[file tail $handoff_file]

#check if workspace open, if not, open it
if {[getws] == ""} {setws $workspace_dir}

#copy sources from sdk/_workspace to _release/sdk_#/projects
set projects_dir $release_dir/projects

set app_patterns [list	\
	.cproject			\
	.project 			\
	src					\
]
set bsp_patterns [list	\
	.cproject			\
	.project			\
	.sdkproject			\
	Makefile			\
	system.mss			\
]

foreach type [list app bsp] patterns [list $app_patterns $bsp_patterns] {
	foreach project [getprojects -type $type] {
		if {[file exists $target_dir/$project] == 0} {
			file mkdir $target_dir/$project
		}
		foreach pattern $patterns {
			foreach file [glob -nocomplain -tails -type {d f} -path $source_dir/$project/ $pattern] {
				set source $source_dir/$project/$file
				set target $target_dir/$project/$file

				puts "Checking $source into version control"
				# Delete existing directories that will be copied - an error will be generated otherwise
				if {[file isdir $source] != 0 && [file exists $target] != 0} {
					# TODO: document danger of running this script
					puts "WARNING: deleting directory $target"
					file delete -force $target
				}
				file copy -force $source $target
			}
		}
	}
}