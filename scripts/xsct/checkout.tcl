#todo: if workspace already exists, error out?

set script_dir [file dirname [info script]]
set repo_dir [file dirname $script_dir]
set workspace_path [file normalize "${repo_dir}/sdk/_workspace"]
set handoff_path [file normalize "${repo_dir}/sdk/handoff"]
set projects_path [file normalize "${repo_dir}/sdk/projects"]

puts "Importing projects into $workspace_path:"

#check if workspace open, if not, open it
if {[getws] == ""} {setws $workspace_path}

#list project files
set project_files [glob -nocomplain ${projects_path}/*]
foreach obj $project_files {
	puts "    Importing project $obj"
}

#create hardware platform from handoff file
set hw_handoff_file [glob -nocomplain $handoff_path/*]
set hw_platform_name [file rootname ${hw_handoff_file}]_hw_platform_0
createhw -name $hw_platform_name -hwspec $hw_handoff_file

#import projects
importprojects $projects_path

#regenerate the bsp sources, targetting the new hardware platform
foreach bsp_project [getprojects -type bsp] {
	regenbsp -hw $hw_platform_name -bsp $bsp_project
}