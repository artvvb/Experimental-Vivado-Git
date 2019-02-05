Build and Release From an Existing Repo:
	git bash:
		git clone --recursive (repo url)
	vivado tcl console:
		source (repo)/scripts/vivado/checkout.tcl
		DO STUFF IN VIVADO
		source (repo)/scripts/vivado/build.tcl
		source (repo)/scripts/vivado/checkin.tcl
		source (repo)/scripts/vivado/sdk_checkout.tcl
		DO STUFF IN SDK
		source (repo)/scripts/vivado/sdk_checkin.tcl
		source (repo)/scripts/vivado/release.tcl
	file explorer:
		merge and upload the zips in each tool's _release directory (python???)
	
Build SW From an Existing Repo
	git bash:
		git clone --recursive (repo url)
		(xsct) (repo)/scripts/xsct/checkout.tcl
	sdk:
		launch with workspace = (repo)/sdk/_workspace
		DO STUFF IN SDK
	git bash:
		(xsct) (repo)/scripts/xsct/checkin.tcl
		
Build and Program From a Release:
	file explorer:
		extract release.zip into (release)
	vivado:
		open (release)/vivado/(project).xpr
		source (release)/scripts/sdk_checkout.tcl
	sdk:
		launch sdk with workspace = (release)/sdk/_workspace
		build
		program fpga
		run app
	
Build a Repo from a Local Project:
	git bash:
		mkdir (repo)
		cd (repo)
		git init
		git submodule add (scripts url)
	vivado:
		set repo_path (path)/(project).xpr
		if HW has not yet been built:
			source (repo)/scripts/vivado_build.tcl
		source (repo)/scripts/vivado_checkin.tcl
		set sdk_workspace (workspace)
		source (repo)/scripts/sdk_checkin.tcl
	git bash:
		git add .
		git commit -m (message)
		git remote add origin (url)
		git push origin master
	vivado:
		source (repo)/scripts/release.tcl
	in file explorer:
		merge and upload the zips in each tool's _release directory (python???)
		
File Structure:
	(repo)/
		README.md
		scripts/
			SUBMODULE
			vivado/
				vivado tcl scripts
			xsct/
				xsct (sdk scripting interface) tcl scripts
		vivado/
			_workspace/
				NOT VERSIONED!
				cache/
				*.xpr
				etc.
			_release/
				NOT VERSIONED!
				release.zip
			repo/
				local/
					hls handoff files?
					local ip, if, etc.
				submodule libraries
			src/
				constraints/
					*.xdc
				hdl/
					*.vhd
					*.v
				ip/
					*/*.xci
				bd/
					*.tcl
				others/
		sdk/
			_workspace/
				SDK workspace, projects are copied into here on checkout
				NOT VERSIONED!
			_release:
				temp folder containing sdk release materials
				NOT VERSIONED!
				TODO
			hw_handoff/
				*.hdf
			projects/
				app/
					.project
					.cproject
					src/*
					NO DEBUG!
				bsp/
					.project
					.cproject
					.sdkproject
					Makefile
					system.mss
					NO SOURCE SUBFOLDERS!
		hls/
			TODO: discuss how/whether to include these materials in this file struture
		petalinux/
			TODO: discuss how/whether to include these materials in this file struture

Notes:
	require build before checkin and release
	as yet designed to only support sdk and vivado - hls ought to be an easy addition
	all scripts can potentially be supported with custom command gui elements in vivado
		likely would require a "master" copy of the scripts to be installed on the computer, would not play well with submodules
	all scripts should be able to be used from both within tool context (sdk, vivado) or from the vommand line, by sourcing the particular tool
		typically, the workspace/project returned by getws or current_project will be used
		if there is no open project, the project found in the particular tool's _workspace directory will be used
	
To Do List:
	sdk release
	double check repo 'init' process
	consider structure when HW design is handed off to SW devs 
