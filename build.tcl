global project_sources 
set project_sources {
    src/msgpu_new.v
    src/vga.v
    src/mcu_bus.v
}

proc print_greeting {} {
    puts "=========================================="
    puts "=            FPGA BUILDER                ="
    puts "=========================================="
}

proc get_script_path {} {
    return [ file dirname [ file normalize [ info script ] ] ]
}

proc get_common_sources {} {
    set script_path [ get_script_path ]
    global project_sources
    set sources_list {} 
    
    foreach s $project_sources {
        lappend sources_list [ list $script_path/$s ]
    }

    return $sources_list
}

proc show_help {} {
    puts ""
    puts "usage: <tcl_sh> build.tcl <options>"
    puts "" 
    puts "options:"
    puts "    --board <board_name>" 
    puts "    --list_boards"
}

proc get_board {i} {
    set board [lindex $::argv $i]
    puts "board: $board" 
    return $board
}

proc list_boards {} {
    puts "" 
    puts "Supported boards are:"
    puts "    tangnano - Sipeed Tang Nano"
    puts "    elbert_v2 - NumatoLab Elbert V2"
}

proc main {} {
    print_greeting
    if { [llength $::argv] == 0 } {
        show_help 
        return true
    }

    for {set i 0} {$i < [llength $::argv]} {incr i} {
        set option [lindex $::argv $i] 
        switch -exact -- $option {
            "show_help"         { show_help }
            "--board"           { incr i; set board [ get_board $i ] }
            "--list_boards"     { list_boards }
            default             { puts "unrecognized option: $option"; show_help }
        }
    }

    set script_path [ get_script_path ]
    source $script_path/boards/$board/build.tcl    

    set common_sources [ get_common_sources ] 
    
    configure_device 
    set_sources $common_sources $script_path/boards/$board
    set_options 
    build
}

main
