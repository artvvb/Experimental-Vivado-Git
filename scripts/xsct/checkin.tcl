### Translation:
###     Move required project sources from repo/sdk/_workspace to repo/sdk/projects, preserving structure
###     required files in structure for each app and bsp present:
###     (repo)/sdk/_workspace/(app)/src (and everything under it)
###     (repo)/sdk/_workspace/(app)/.cproject
###     (repo)/sdk/_workspace/(app)/.project
###     (repo)/sdk/_workspace/(bsp)/.cproject
###     (repo)/sdk/_workspace/(bsp)/.project
###     (repo)/sdk/_workspace/(bsp)/.sdkproject
###     (repo)/sdk/_workspace/(bsp)/Makefile
###     (repo)/sdk/_workspace/(bsp)/system.mss

set scripts_dir [file dirname [info script]]
set repo_dir [file dirname $scripts_dir]
set workspace_dir $repo_dir/sdk/_workspace
set projects_dir $repo_dir/sdk/projects

#check if workspace open, if not, open it
if {[getws] == ""} {setws $workspace_dir}

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