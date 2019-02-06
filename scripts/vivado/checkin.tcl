# if no project is open, check if there is a project in the repo and open it
if {[llength [get_projects]] == 0} {
	set repo_path [file dirname [file dirname [file dirname [info script]]]]
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

set proj_obj [current_project]
set proj_path [get_property DIRECTORY $proj_obj]
set proj_name [get_property NAME $proj_obj]
set repo_path [file normalize [file dirname [info script]]/../..]
set vivado_proj_file [file normalize "$proj_path/$proj_name.xpr"]
set vivado_srcs_dir [file normalize "$proj_path/$proj_name.srcs"]

puts "proj_path = $proj_path"
puts "proj_name = $proj_name"
puts "repo_path = $repo_path"
puts "vivado_proj_file = $vivado_proj_file"
puts "vivado_srcs_dir = $vivado_srcs_dir"

set required_dirs [list               \
	$repo_path/vivado                 \
	$repo_path/vivado/src             \
	$repo_path/vivado/src/bd          \
	$repo_path/vivado/src/constraints \
	$repo_path/vivado/src/ip          \
	$repo_path/vivado/src/hdl         \
	$repo_path/vivado/src/others      \
	$repo_path/vivado/repo            \
	$repo_path/vivado/repo/local      \
	$repo_path/sdk                    \
	$repo_path/sdk/projects           \
]

foreach dir $required_dirs {
	if {[file exists $dir] == 0} {
		file mkdir $dir
	}
}

if {[file exists $repo_path/.gitignore] == 0} {
	puts "INFO: No gitignore detected, creating one now"
	set source_file [file normalize ${repo_path}/scripts/template.gitignore]
	set target_file [file normalize ${repo_path}/.gitignore]
	file copy -force $source_file $target_file
}

set bd_files [get_files -of_objects [get_filesets sources_1] -filter "NAME=~*.bd"]
if {[llength $bd_files] > 1} {
	puts "ERROR: This script cannot handle projects containing more than one block design!"
} elseif {[llength $bd_files] == 1} {
	set bd_file [lindex $bd_files 0]
	open_bd_design $bd_file
	set bd_name [file tail [file rootname [get_property NAME $bd_file]]]
	set script_name "$repo_path/vivado/src/bd/${bd_name}.tcl"
	puts "INFO: Checking in ${script_name} to version control."
	write_bd_tcl -force -make_local $script_name
	
	set source_files [get_files -of_objects [get_filesets sources_1]] 
	# filter out all BD sources
	set non_bd_sources [lsearch -all -inline -nocase -not -glob $source_files $vivado_srcs_dir/sources_1/bd/*]
	# filter out BD wrapper file
	set bd_wrapper [get_files -filter "NAME=~*/[get_property NAME [get_bd_designs $bd_name]]_wrapper.*"]
	set non_bd_sources [lsearch -all -inline -nocase -not -glob $non_bd_sources $bd_wrapper]
	foreach origin $non_bd_sources {
		set skip 0
		if {[file extension $origin] == ".vhd"} {
			set subdir hdl
		} elseif {[file extension $origin] == ".v"} {
			set subdir hdl
		} elseif {[file extension $origin] != ".bd" && [file extension $origin] != ".xci"} {
			set subdir others
		} else {
			set skip 1
		}
		
		if {$skip == 0} {
			puts "INFO: Checking in [file tail $origin] to version control."
			set target "$repo_path/vivado/src/$subdir/[file tail $origin]"
			if {[file exists $target] == 0} {
				file copy -force $origin $target
			}
		}
	}
} else {
	foreach source_file [get_files -of_objects [get_filesets sources_1]] {
		set origin [get_property name $source_file]
		set skip 0
		if {[file extension $origin] == ".vhd"} {
			set subdir hdl
		} elseif {[file extension $origin] == ".v"} {
			set subdir hdl
		} elseif {[file extension $origin] != ".bd" && [file extension $origin] != ".xci"} {
			set subdir others
		} else {
			set skip 1
		}
		
		foreach ip [get_ips] {
			set ip_dir [get_property IP_DIR $ip]
			set source_length [string length $source_file]
			set dir_length [string length $ip_dir]
			if {$source_length >= $dir_length && [string range $source_file 0 $dir_length-1] == $ip_dir} {
				set skip 1
			}
		}
		
		if {$skip == 0} {
			puts "INFO: Checking in [file tail $origin] to version control."
			set target "$repo_path/vivado/src/$subdir/[file tail $origin]"
			if {[file exists $target] == 0} {
				file copy -force $origin $target
			}
		}
	}
	foreach ip [get_ips] {
		set origin [get_property ip_file $ip]
		set ipname [get_property name $ip]
		set dir "$repo_path/vivado/src/ip/$ipname"
		if {[file exists $dir] == 0} {
			file mkdir $dir
		}
		set target "$dir/[file tail $origin]"
		puts "INFO: Checking in [file tail $origin] to version control."
		if {[file exists $target] == 0} {
			file copy -force $origin $target
		}
	}
	# TODO: foreach file in /src/ip, if it wasn't just checked in, delete it
}
foreach constraint_file [get_files -of_objects [get_filesets constrs_1]] {
	set origin [get_property name $constraint_file]
	set target "$repo_path/vivado/src/constraints/[file tail $origin]"
	puts "INFO: Checking in [file tail $origin] to version control."
	if {[file exists $target] == 0} { # TODO: this may not be safe; remind users to make sure to delete any unused files from version control
		file copy -force $origin $target
	}
}

# Save project-specific settings into project_info.tcl
set board_part [current_board_part]
set part [get_property part $proj_obj]
set default_lib [get_property default_lib $proj_obj]
set simulator_language [get_property simulator_language $proj_obj]
set target_language [get_property target_language $proj_obj]
puts "INFO: Checking in project_info.tcl to version control."
set file_name "$repo_path/vivado/project_info.tcl"
set file_obj [open $file_name "w"]
puts $file_obj "# This is an automatically generated file used by digilent_vivado_checkout.tcl to set project options"
puts $file_obj "proc set_digilent_project_properties {proj_name} {"
puts $file_obj "    set project_obj \[get_projects \$proj_name\]"
puts $file_obj "	set_property \"part\" \"$part\" \$project_obj"
puts $file_obj "	set_property \"board_part\" \"$board_part\" \$project_obj"
puts $file_obj "	set_property \"default_lib\" \"$default_lib\" \$project_obj"
puts $file_obj "	set_property \"simulator_language\" \"$simulator_language\" \$project_obj"
puts $file_obj "	set_property \"target_language\" \"$target_language\" \$project_obj"
puts $file_obj "}"
close $file_obj

# TODO: Check the hardware handoff file into version control?
# source $repo_path/scripts/vivado/handoff.tcl

puts "INFO: Project $vivado_proj_file has been checked into version control"

### TODO: HOOK INTO XSCT CHECKIN