set_device GW1N-LV1QN48C6/I5
add_file src/msgpu.v
add_file src/mcu_bus.v
add_file src/clock_divider.v
add_file src/message_broker.v
add_file src/pixel_memory.v
add_file src/vga.v
add_file src/osc/osc.v
add_file src/pll/pll.v
add_file src/msgpu.cst
add_file src/dual_port_ram.v 

set_option -synthesis_tool synplify_pro
set_option -top_module msgpu

set_option -use_sspi_as_gpio 1
set_option -use_mspi_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_reconfign_as_gpio 1

set_option -frequency 24
set_option -bit_encrypt 0
set_option -bit_security 0
set_option -fix_gated_and_generated_clocks 1
run syn
run pnr
