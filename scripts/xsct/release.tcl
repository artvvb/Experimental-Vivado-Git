#TODO check if workspace open, if not, open it
#TODO copy required scripts and files from scripts and sdk/_workspace

# move sources from sdk/handoff/*.hdf -> _release/sdk/handoff/*.hdf
# move sources from sdk/_workspace/ to _release/projects

set sources [list]
set targets [list]

# do the same stuff as in checkin (move projects from repo/sdk/_workspace to repo/_release/sdk/projects
set scripts_dir [file dirname [info script]]
set repo_dir [file dirname $scripts_dir]
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
		if {[file exists $projects_dir/$project] == 0} {
			file mkdir $projects_dir/$project
		}
		foreach pattern $patterns {
			foreach file [glob -nocomplain -tails -path $workspace_dir/$project/ $pattern] {
				set source [file join $workspace_dir $project $file]
				if {[file isdir $source]} {
					puts "checking in directory $source to version control"
				} else {
					puts "checking in file $source to version control"
				}
				set file_name [file join $project $file]
				set source_path [split $workspace_dir /]
				set target_path [split $projects_dir /]
				set file_path [split $file_name /]
				# Ensure directory substructure is maintained
				while {[llength $file_path] > 1} {
					lappend source_path [lindex $file_path 0]
					lappend target_path [lindex $file_path 0]
					set file_path [lreplace $file_path 0 0]
					if {[file exists [join $target_path /]] == 0} {
						file mkdir [join $target_path /]
					}
				}
				file copy -force [file join $workspace_dir $file_name] [file join $projects_dir $file_name]
			}
		}
	}
}