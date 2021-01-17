# Add here board sources 
global board_sources

global myProject 
set myProject msgpu

global myScript 
set myScript build

#==========================#
#=         SOURCES        =#
#==========================#
set board_sources {
    top.v 
    elbertv2.ucf
    pll.v 
}
#<=======  SOURCES  ======># 

proc open_project {} {
    global myProject
    project open $myProject
}

proc configure_device {} {
    create_project
    open_project 
 
    project set family "Spartan3A and Spartan3AN"
    project set device "xc3s50an"
    project set package "tqg144"
    project set speed "-5"
    project set top_level_module_type "HDL"
    project set synthesis_tool "XST (VHDL/Verilog)"
    project set simulator "Modelsim-PE Verilog"
    project set "Preferred Language" "Verilog"
    project set "Enable Message Filtering" "false"
}

proc build {} {
    process run "Synthesize"
    process run "Translate"
    process run "Map"
    process run "Place & Route"
    process run "Generate Programming File"
    project close
}

proc rebuild_project {} {

   global myScript
   global myProject

   project close
   ## put out a 'heartbeat' - so we know something's happening.
   puts "\n$myScript: Rebuilding ($myProject)...\n"

   set proj_exts [ list ise xise gise ]
   foreach ext $proj_exts {
      set proj_name "${myProject}.$ext"
      if { [ file exists $proj_name ] } { 
         file delete $proj_name
      }
   }

   project new $myProject
   set_project_props
   add_source_files
   create_libraries
   puts "$myScript: project rebuild completed."

   run_process

}

proc create_project {} {
    global myProject
    project close 
    puts "\nCreating project: $myProject" 
    
    set project_extensions [ list ise xise gise ]
    foreach extension $project_extensions {
        set project_name ${myProject}.$extension 
        if { [ file exists $project_name ] } {
            file delete $project_name
        }
    }

    project new $myProject 
}

proc run_task { task } {

   # helper proc for run_process

   puts "Running '$task'"
   set result [ process run "$task" ]
   #
   # check process status (and result)
   set status [ process get $task status ]
   if { ( ( $status != "up_to_date" ) && \
            ( $status != "warnings" ) ) || \
         ! $result } {
      return false
   }
   return true
}

# 
# show_help: print information to help users understand the options available when
#            running this script.
# 
proc show_help {} {

   global myScript

   puts ""
   puts "usage: xtclsh $myScript <options>"
   puts "       or you can run xtclsh and then enter 'source $myScript'."
   puts ""
   puts "options:"
   puts "   run_process       - set properties and run processes."
   puts "   rebuild_project   - rebuild the project from scratch and run processes."
   puts "   set_project_props - set project properties (device, speed, etc.)"
   puts "   add_source_files  - add source files"
   puts "   create_libraries  - create vhdl libraries"
   puts "   set_process_props - set process property values"
   puts "   show_help         - print this message"
   puts ""
}

proc get_board_sources {board_path} {
    global board_sources  
    set sources_list {} 
    foreach s $board_sources {
        lappend sources_list [ list $board_path/$s ]
    }
    return $sources_list
}


# 
# add_source_files
# 
# This procedure add the source files that were known to the project at the
# time this script was generated.
# 
proc add_source_files {} {

   #global myScript

   #if { ! [ open_project ] } {
   #}

   #puts "$myScript: Adding sources to project..."

   #xfile add "./elbertv2.ucf"
   #xfile add "./top.v"

   ## Set the Top Module as well...
   #project set top "gpu"

   #puts "$myScript: project sources reloaded."

} ; # end add_source_files

proc set_sources {project_sources board_path} {
    open_project 
    foreach s $project_sources {
        puts "file $s"
        xfile add $s
    }

    set board_sources [ get_board_sources $board_path ] 
    foreach s $board_sources {
        xfile add $s
    }
}

proc set_options {} {
    global myScript

    open_project 
    puts "$myScript: setting process properties..."

    project set "Compiled Library Directory" "\$XILINX/<language>/<simulator>"
    project set "Multiplier Style" "Auto" -process "Synthesize - XST"
    project set "Configuration Rate" "25" -process "Generate Programming File"
    project set "Number of Clock Buffers" "24" -process "Synthesize - XST"
    project set "Max Fanout" "100000" -process "Synthesize - XST"
    project set "Regenerate Core" "Under Current Project Setting" -process "Regenerate Core"
    project set "Filter Files From Compile Order" "true"
    project set "Last Applied Goal" "Balanced"
    project set "Last Applied Strategy" "Xilinx Default (unlocked)"
    project set "Last Unlock Status" "false"
    project set "Manual Compile Order" "false"
    project set "Report Fastest Path(s) in Each Constraint" "true" -process "Generate Post-Place & Route Static Timing"
    project set "Generate Datasheet Section" "true" -process "Generate Post-Place & Route Static Timing"
    project set "Generate Timegroups Section" "false" -process "Generate Post-Place & Route Static Timing"
    project set "Report Fastest Path(s) in Each Constraint" "true" -process "Generate Post-Map Static Timing"
    project set "Generate Datasheet Section" "true" -process "Generate Post-Map Static Timing"
    project set "Generate Timegroups Section" "false" -process "Generate Post-Map Static Timing"
    project set "Project Description" ""
    project set "Property Specification in Project File" "Store all values"
    project set "Case Implementation Style" "None" -process "Synthesize - XST"
    project set "Decoder Extraction" "true" -process "Synthesize - XST"
    project set "Priority Encoder Extraction" "Yes" -process "Synthesize - XST"
    project set "Mux Extraction" "Yes" -process "Synthesize - XST"
    project set "RAM Extraction" "true" -process "Synthesize - XST"
    project set "ROM Extraction" "true" -process "Synthesize - XST"
    project set "FSM Encoding Algorithm" "Auto" -process "Synthesize - XST"
    project set "Logical Shifter Extraction" "true" -process "Synthesize - XST"
    project set "Optimization Goal" "Speed" -process "Synthesize - XST"
    project set "Optimization Effort" "Normal" -process "Synthesize - XST"
    project set "Resource Sharing" "true" -process "Synthesize - XST"
    project set "Shift Register Extraction" "true" -process "Synthesize - XST"
    project set "XOR Collapsing" "true" -process "Synthesize - XST"
    project set "User Browsed Strategy Files" ""
    project set "VHDL Source Analysis Standard" "VHDL-200X"
    project set "Input TCL Command Script" "" -process "Generate Text Power Report"
    project set "Load Physical Constraints File" "Default" -process "Analyze Power Distribution (XPower Analyzer)"
    project set "Load Physical Constraints File" "Default" -process "Generate Text Power Report"
    project set "Load Simulation File" "Default" -process "Analyze Power Distribution (XPower Analyzer)"
    project set "Load Simulation File" "Default" -process "Generate Text Power Report"
    project set "Load Setting File" "" -process "Analyze Power Distribution (XPower Analyzer)"
    project set "Load Setting File" "" -process "Generate Text Power Report"
    project set "Setting Output File" "" -process "Generate Text Power Report"
    project set "Produce Verbose Report" "false" -process "Generate Text Power Report"
    project set "Other XPWR Command Line Options" "" -process "Generate Text Power Report"
    project set "Other Bitgen Command Line Options" "" -process "Generate Programming File"
    project set "Maximum Signal Name Length" "20" -process "Generate IBIS Model"
    project set "Show All Models" "false" -process "Generate IBIS Model"
    project set "Launch SDK after Export" "true" -process "Export Hardware Design To SDK with Bitstream"
    project set "Launch SDK after Export" "true" -process "Export Hardware Design To SDK without Bitstream"
    project set "Target UCF File Name" "" -process "Back-annotate Pin Locations"
    project set "Ignore User Timing Constraints" "false" -process "Map"
    project set "Use RLOC Constraints" "Yes" -process "Map"
    project set "Other Map Command Line Options" "" -process "Map"
    project set "Use LOC Constraints" "true" -process "Translate"
    project set "Other Ngdbuild Command Line Options" "" -process "Translate"
    project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "Floorplan Area/IO/Logic (PlanAhead)"
    project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "I/O Pin Planning (PlanAhead) - Pre-Synthesis"
    project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "I/O Pin Planning (PlanAhead) - Post-Synthesis"
    project set "Ignore User Timing Constraints" "false" -process "Place & Route"
    project set "Other Place & Route Command Line Options" "" -process "Place & Route"
    project set "UserID Code (8 Digit Hexadecimal)" "0xFFFFFFFF" -process "Generate Programming File"
    project set "Configuration Pin Done" "Pull Up" -process "Generate Programming File"
    project set "Create ASCII Configuration File" "false" -process "Generate Programming File"
    project set "Create Bit File" "true" -process "Generate Programming File"
    project set "Enable BitStream Compression" "false" -process "Generate Programming File"
    project set "Run Design Rules Checker (DRC)" "true" -process "Generate Programming File"
    project set "Enable Cyclic Redundancy Checking (CRC)" "true" -process "Generate Programming File"
    project set "Create IEEE 1532 Configuration File" "false" -process "Generate Programming File"
    project set "Configuration Pin Program" "Pull Up" -process "Generate Programming File"
    project set "Place MultiBoot Settings into Bitstream" "false" -process "Generate Programming File"
    project set "JTAG Pin TCK" "Pull Up" -process "Generate Programming File"
    project set "JTAG Pin TDI" "Pull Up" -process "Generate Programming File"
    project set "JTAG Pin TDO" "Pull Up" -process "Generate Programming File"
    project set "JTAG Pin TMS" "Pull Up" -process "Generate Programming File"
    project set "Unused IOB Pins" "Pull Down" -process "Generate Programming File"
    project set "Security" "Enable Readback and Reconfiguration" -process "Generate Programming File"
    project set "FPGA Start-Up Clock" "CCLK" -process "Generate Programming File"
    project set "Done (Output Events)" "Default (4)" -process "Generate Programming File"
    project set "Drive Done Pin High" "false" -process "Generate Programming File"
    project set "Enable Outputs (Output Events)" "Default (5)" -process "Generate Programming File"
    project set "Wait for DLL Lock (Output Events)" "Default (NoWait)" -process "Generate Programming File"
    project set "Release Write Enable (Output Events)" "Default (6)" -process "Generate Programming File"
    project set "Enable Internal Done Pipe" "true" -process "Generate Programming File"
    project set "Drive Awake Pin During Suspend/Wake Sequence" "false" -process "Generate Programming File"
    project set "Enable Suspend/Wake Global Set/Reset" "false" -process "Generate Programming File"
    project set "Enable Power-On Reset Detection" "true" -process "Generate Programming File"
    project set "GTS Cycle During Suspend/Wakeup Sequence" "4" -process "Generate Programming File"
    project set "GWE Cycle During Suspend/Wakeup Sequence" "5" -process "Generate Programming File"
    project set "Wakeup Clock" "Startup Clock" -process "Generate Programming File"
    project set "Allow Logic Optimization Across Hierarchy" "false" -process "Map"
    project set "Optimization Strategy (Cover Mode)" "Area" -process "Map"
    project set "Pack I/O Registers/Latches into IOBs" "Off" -process "Map"
    project set "Generate Detailed MAP Report" "false" -process "Map"
    project set "Map Slice Logic into Unused Block RAMs" "false" -process "Map"
    project set "Perform Timing-Driven Packing and Placement" "false" -process "Map"
    project set "Trim Unconnected Signals" "true" -process "Map"
    project set "Create I/O Pads from Ports" "false" -process "Translate"
    project set "Macro Search Path" "" -process "Translate"
    project set "Netlist Translation Type" "Timestamp" -process "Translate"
    project set "User Rules File for Netlister Launcher" "" -process "Translate"
    project set "Allow Unexpanded Blocks" "false" -process "Translate"
    project set "Allow Unmatched LOC Constraints" "false" -process "Translate"
    project set "Allow Unmatched Timing Group Constraints" "false" -process "Translate"
    project set "Placer Effort Level (Overrides Overall Level)" "None" -process "Place & Route"
    project set "Router Effort Level (Overrides Overall Level)" "None" -process "Place & Route"
    project set "Place And Route Mode" "Normal Place and Route" -process "Place & Route"
    project set "Perform Advanced Analysis" "false" -process "Generate Post-Place & Route Static Timing"
    project set "Report Paths by Endpoint" "3" -process "Generate Post-Place & Route Static Timing"
    project set "Report Type" "Verbose Report" -process "Generate Post-Place & Route Static Timing"
    project set "Number of Paths in Error/Verbose Report" "3" -process "Generate Post-Place & Route Static Timing"
    project set "Stamp Timing Model Filename" "" -process "Generate Post-Place & Route Static Timing"
    project set "Report Unconstrained Paths" "" -process "Generate Post-Place & Route Static Timing"
    project set "Perform Advanced Analysis" "false" -process "Generate Post-Map Static Timing"
    project set "Report Paths by Endpoint" "3" -process "Generate Post-Map Static Timing"
    project set "Report Type" "Verbose Report" -process "Generate Post-Map Static Timing"
    project set "Number of Paths in Error/Verbose Report" "3" -process "Generate Post-Map Static Timing"
    project set "Report Unconstrained Paths" "" -process "Generate Post-Map Static Timing"
    project set "Add I/O Buffers" "true" -process "Synthesize - XST"
    project set "Global Optimization Goal" "AllClockNets" -process "Synthesize - XST"
    project set "Keep Hierarchy" "No" -process "Synthesize - XST"
    project set "Register Balancing" "No" -process "Synthesize - XST"
    project set "Register Duplication" "true" -process "Synthesize - XST"
    project set "Asynchronous To Synchronous" "false" -process "Synthesize - XST"
    project set "Automatic BRAM Packing" "false" -process "Synthesize - XST"
    project set "BRAM Utilization Ratio" "100" -process "Synthesize - XST"
    project set "Bus Delimiter" "<>" -process "Synthesize - XST"
    project set "Case" "Maintain" -process "Synthesize - XST"
    project set "Cores Search Directories" "" -process "Synthesize - XST"
    project set "Cross Clock Analysis" "false" -process "Synthesize - XST"
    project set "Equivalent Register Removal" "true" -process "Synthesize - XST"
    project set "FSM Style" "LUT" -process "Synthesize - XST"
    project set "Generate RTL Schematic" "Yes" -process "Synthesize - XST"
    project set "Generics, Parameters" "" -process "Synthesize - XST"
    project set "Hierarchy Separator" "/" -process "Synthesize - XST"
    project set "HDL INI File" "" -process "Synthesize - XST"
    project set "Library Search Order" "" -process "Synthesize - XST"
    project set "Netlist Hierarchy" "As Optimized" -process "Synthesize - XST"
    project set "Optimize Instantiated Primitives" "false" -process "Synthesize - XST"
    project set "Pack I/O Registers into IOBs" "Auto" -process "Synthesize - XST"
    project set "Read Cores" "true" -process "Synthesize - XST"
    project set "Slice Packing" "true" -process "Synthesize - XST"
    project set "Slice Utilization Ratio" "100" -process "Synthesize - XST"
    project set "Use Clock Enable" "Yes" -process "Synthesize - XST"
    project set "Use Synchronous Reset" "Yes" -process "Synthesize - XST"
    project set "Use Synchronous Set" "Yes" -process "Synthesize - XST"
    project set "Use Synthesis Constraints File" "true" -process "Synthesize - XST"
    project set "Verilog Include Directories" "" -process "Synthesize - XST"
    project set "Verilog 2001" "true" -process "Synthesize - XST"
    project set "Verilog Macros" "" -process "Synthesize - XST"
    project set "Work Directory" "/home/mateusz/opt/xilinx/14.7/ISE_DS/test/xst" -process "Synthesize - XST"
    project set "Write Timing Constraints" "false" -process "Synthesize - XST"
    project set "Other XST Command Line Options" "" -process "Synthesize - XST"
    project set "Auto Implementation Compile Order" "true"
    project set "Map Effort Level" "High" -process "Map"
    project set "Combinatorial Logic Optimization" "false" -process "Map"
    project set "Starting Placer Cost Table (1-100)" "1" -process "Map"
    project set "Power Reduction" "false" -process "Map"
    project set "Register Duplication" "Off" -process "Map"
    project set "Generate Constraints Interaction Report" "false" -process "Generate Post-Map Static Timing"
    project set "Synthesis Constraints File" "" -process "Synthesize - XST"
    project set "Mux Style" "Auto" -process "Synthesize - XST"
    project set "RAM Style" "Auto" -process "Synthesize - XST"
    project set "Maximum Number of Lines in Report" "1000" -process "Generate Text Power Report"
    project set "Output File Name" "led" -process "Generate IBIS Model"
    project set "Timing Mode" "Non Timing Driven" -process "Map"
    project set "Generate Asynchronous Delay Report" "false" -process "Place & Route"
    project set "Generate Clock Region Report" "false" -process "Place & Route"
    project set "Generate Post-Place & Route Power Report" "false" -process "Place & Route"
    project set "Generate Post-Place & Route Simulation Model" "false" -process "Place & Route"
    project set "Power Reduction" "false" -process "Place & Route"
    project set "Timing Mode" "Performance Evaluation" -process "Place & Route"
    project set "Create Binary Configuration File" "true" -process "Generate Programming File"
    project set "Enable Debugging of Serial Mode BitStream" "false" -process "Generate Programming File"
    project set "Retry Configuration if CRC Error Occurs" "false" -process "Generate Programming File"
    project set "MultiBoot: Starting Address for Next Configuration" "0x00000000" -process "Generate Programming File"
    project set "MultiBoot: Use New Mode for Next Configuration" "true" -process "Generate Programming File"
    project set "Enable Filter on Suspend Input" "Please use the ENABLE_SUSPEND implementation constraint." -process "Generate Programming File"
    project set "CLB Pack Factor Percentage" "100" -process "Map"
    project set "Place & Route Effort Level (Overall)" "High" -process "Place & Route"
    project set "Generate Constraints Interaction Report" "false" -process "Generate Post-Place & Route Static Timing"
    project set "Move First Flip-Flop Stage" "true" -process "Synthesize - XST"
    project set "Move Last Flip-Flop Stage" "true" -process "Synthesize - XST"
    project set "ROM Style" "Auto" -process "Synthesize - XST"
    project set "Safe Implementation" "No" -process "Synthesize - XST"
    project set "Extra Effort" "None" -process "Map"
    project set "Power Activity File" "" -process "Map"
    project set "Power Activity File" "" -process "Place & Route"
    project set "MultiBoot: Next Configuration Mode" "001" -process "Generate Programming File"
    project set "Extra Effort (Highest PAR level only)" "None" -process "Place & Route"
    project set "Starting Placer Cost Table (1-100)" "1" -process "Place & Route"
    project set "Functional Model Target Language" "Verilog" -process "View HDL Source"
    project set "Change Device Speed To" "-5" -process "Generate Post-Place & Route Static Timing"
    project set "Change Device Speed To" "-5" -process "Generate Post-Map Static Timing"
    project set "Working Directory" build
    puts "$myScript: project property values set."

} ; # end set_process_props

