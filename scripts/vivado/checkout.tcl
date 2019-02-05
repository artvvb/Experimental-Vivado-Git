set repo_path [file dirname [file dirname [file dirname [info script]]]]
set proj_name [file tail $repo_path]
set xpr_path "$repo_path/vivado/_workspace/$proj_name.xpr"
set vivado_version [version -short]
set vivado_year [lindex [split $vivado_version .] 0]

puts "repo_path = $repo_path"
puts "proj_name = $proj_name"
puts "xpr_path = $xpr_path"
puts "vivado_version = $vivado_version"
puts "vivado_year = $vivado_year"

if {[file exists $xpr_path] != 0} {
	puts "ERROR: project already checked out"
	# TODO quit
}

if {[file exists [file dirname $xpr_path]] == 0} {
	file mkdir [file dirname $xpr_path]
}

create_project $proj_name [file dirname $xpr_path]

# Capture board information for the project
puts "INFO: Capturing board information from $repo_path/project_info.tcl"
source -notrace $repo_path/vivado/project_info.tcl
set_digilent_project_properties $proj_name
set obj [get_projects $proj_name]
set part_name [get_property "part" $obj]

# Uncomment the following 3 lines to greatly increase build speed while working with IP cores (and/or block diagrams)
puts "INFO: Configuring project IP handling properties"
set_property "corecontainer.enable" "0" $obj
set_property "ip_cache_permissions" "read write" $obj
set_property "ip_output_repo" "[file normalize "$repo_path/vivado/_workspace/cache"]" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
	puts "INFO: Creating sources_1 fileset"
    create_fileset -srcset sources_1
}

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
	puts "INFO: Creating constrs_1 fileset"
    create_fileset -constrset constrs_1
}

# Set IP repository paths
puts "INFO: Setting IP repository paths"
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize $repo_path/vivado/repo]" $obj

# Refresh IP Repositories
puts "INFO: Refreshing IP repositories"
update_ip_catalog -rebuild

# Add hardware description language sources
puts "INFO: Adding HDL sources"
add_files -quiet -norecurse $repo_path/vivado/src/hdl

# Add IPs
# TODO: handle IP core-container files
puts "INFO: Adding XCI IP sources"
add_files -quiet [glob -nocomplain $repo_path/vivado/src/ip/*/*.xci]

# Add constraints
puts "INFO: Adding constraints"
add_files -quiet -norecurse -fileset constrs_1 $repo_path/vivado/src/constraints

# Recreate block design
# TODO: handle multiple block designs
set ipi_tcl_files [glob -nocomplain "$repo_path/vivado/src/bd/*.tcl"]
if {[llength $ipi_tcl_files] > 1} {
	# TODO: quit and log the error
	puts "ERROR: This script cannot handle projects containing more than one block design!"
} elseif {[llength $ipi_tcl_files] == 1} {
	# Use TCL script to rebuild block design
	puts "INFO: Rebuilding block design from script"
	# Create local source directory for bd
	if {[file exist "[file rootname $xpr_path].srcs"] == 0} {
		file mkdir "[file rootname $xpr_path].srcs"
	}
	if {[file exist "[file rootname $xpr_path].srcs/sources_1"] == 0} {
		file mkdir "[file rootname $xpr_path].srcs/sources_1"
	}
	if {[file exist "[file rootname $xpr_path].srcs/sources_1/bd"] == 0} {
		file mkdir "[file rootname $xpr_path].srcs/sources_1/bd"
	}
	# Force Non-Remote BD Flow
	set origin_dir [pwd]
	cd "[file rootname $xpr_path].srcs/sources_1"
	set run_remote_bd_flow 0
	source -notrace [lindex $ipi_tcl_files 0]
	cd $origin_dir
}

# Generate the wrapper
set bd_files [get_files -of_objects [get_filesets sources_1] -filter "NAME=~*.bd"]
if {[llength $bd_files] > 1} {
	puts "ERROR: This script cannot handle projects containing more than one block design!"
} elseif {[llength $bd_files] == 1} {
	set bd_name [get_bd_designs]
	set bd_file [get_files $bd_name.bd]
	set wrapper_file [make_wrapper -files $bd_file -top -force]
    import_files -quiet -force -norecurse $wrapper_file

    set obj [get_filesets sources_1]
    set_property "top" "${bd_name}_wrapper" $obj
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
	puts "INFO: Creating synth_1 run"
    create_run -name synth_1 -part $part_name -flow {Vivado Synthesis $vivado_year} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
    set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
    set_property flow "Vivado Synthesis $vivado_year" [get_runs synth_1]
}
puts "INFO: Configuring synth_1 run"
set obj [get_runs synth_1]
set_property "part" $part_name $obj
set_property "steps.synth_design.args.flatten_hierarchy" "none" $obj
set_property "steps.synth_design.args.directive" "RuntimeOptimized" $obj
set_property "steps.synth_design.args.fsm_extraction" "off" $obj

# Set the current synth run
puts "INFO: Setting current synthesis run"
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
	puts "INFO: Creating impl_1 run"
    create_run -name impl_1 -part $part_name -flow {Vivado Implementation $vivado_year} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
    set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
    set_property flow "Vivado Implementation $vivado_year" [get_runs impl_1]
}
puts "INFO: Configuring impl_1 run"
set obj [get_runs impl_1]
set_property "part" $part_name $obj
set_property "steps.opt_design.args.directive" "RuntimeOptimized" $obj
set_property "steps.place_design.args.directive" "RuntimeOptimized" $obj
set_property "steps.route_design.args.directive" "RuntimeOptimized" $obj

# Set the current impl run
puts "INFO: Setting current implementation run"
current_run -implementation [get_runs impl_1]

puts "INFO: Project created: [file tail $proj_name]"
puts "INFO: Exiting Vivado"

### TODO: HOOK INTO XSCT CHECKOUT