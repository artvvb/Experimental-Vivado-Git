#TODO: if workspace already exists, error out?

set repo_dir [file normalize [file dirname [info script]]/../..]
set workspace_path [file normalize "$repo_dir/sdk/_workspace"]
set handoff_path [file normalize "$repo_dir/sdk/handoff"]
set projects_path [file normalize "$repo_dir/sdk/projects"]

puts "Importing projects into $workspace_path:"

#check if workspace open, if not, open it
if {[getws] == ""} {setws $workspace_path}

#list project files
set project_files [glob -nocomplain $projects_path/*]
foreach obj $project_files {
	puts "Importing project $obj"
}

#create hardware platform from handoff file
set hw_handoff_files [glob -nocomplain $handoff_path/*]
if {[llength $hw_handoff_files] != 1} {
	puts "ERROR: multiple or no hdf files detected; cannot create hardware platform"
	# TODO quit
} else {
	set hw_handoff_file [lindex $hw_handoff_files 0]
	set hw_platform_name [file rootname [file tail $hw_handoff_file]]_hw_platform_0
	puts "Creating hardware platform $hw_platform_name"
	puts "  from handoff $hw_handoff_file"
}
createhw -name "$hw_platform_name" -hwspec "$hw_handoff_file"

#import projects from version control into workspace
importprojects $projects_path

#regenerate the bsp sources, targetting the new hardware platform
foreach bsp_project [getprojects -type bsp] {
	regenbsp -hw $hw_platform_name -bsp $bsp_project
}