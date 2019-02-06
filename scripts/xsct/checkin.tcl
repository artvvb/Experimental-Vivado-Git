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

set repo_dir [file normalize [file dirname [info script]]/../..]
set source_dir $repo_dir/sdk/_workspace
set target_dir $repo_dir/sdk/projects

#check if workspace open, if not, open it
if {[getws] == ""} {setws $source_dir}

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