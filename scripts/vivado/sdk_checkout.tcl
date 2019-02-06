### Vivado TCL script to check out SDK sources and initialize a workspace.

set xsct_path [file normalize "$env(Xilinx_SDK)/bin/xsct"]
set script_path [file normalize "[file dirname [info script]]/xsct_checkout.tcl"]

exec $xsct_path $script_path