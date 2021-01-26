# Add here board sources 
global board_sources

#==========================#
#=         SOURCES        =#
#==========================#
set board_sources {
    top.v 
    tangnano.cst
    pll/pll.v
    psram.sv
    psram/commands.v 
    psram/spi_interface.sv
}
#<=======  SOURCES  ======># 

proc build {} {
    run syn
    run pnr
}

proc get_board_sources {board_path} {
    global board_sources  
    set sources_list {} 
    foreach s $board_sources {
        lappend sources_list [ list $board_path/$s ]
    }
    return $sources_list
}

proc configure_device {} {
    set_device GW1N-LV1QN48C6/I5
}

proc set_options {} {
    #set_option -synthesis_tool gowin 
    set_option -top_module top 

    set_option -use_sspi_as_gpio 1
    set_option -use_mspi_as_gpio 1
    set_option -use_done_as_gpio 1
    set_option -use_reconfign_as_gpio 1

    set_option -frequency 24
    set_option -bit_encrypt 0
    set_option -bit_security 0
    set_option -fix_gated_and_generated_clocks 1
    set_option -verilog_std sysv2017
    set_option -cst_warn_to_error 1
}

proc set_sources {project_sources board_path} {
    foreach s $project_sources {
        puts "file $s"
        add_file $s
    }

    set board_sources [ get_board_sources $board_path ] 
    foreach s $board_sources {
        add_file $s
    }
}
