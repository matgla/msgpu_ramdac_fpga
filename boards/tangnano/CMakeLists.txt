find_program (gwsh "gw_sh" REQUIRED)

add_custom_target(
    tangnano 
    COMMAND ${gwsh} ${PROJECT_SOURCE_DIR}/build.tcl --board tangnano
)

find_package(Python3 COMPONENTS Interpreter REQUIRED)

find_program (programer_cli_exe "programmer_cli" REQUIRED)

add_custom_target(
    flash_gw_tangnano
    COMMAND 
    ${programer_cli_exe} -d GW1N-1 -r2 -f ${CMAKE_CURRENT_BINARY_DIR}/impl/pnr/project.fs
    VERBATIM
    DEPENDS tangnano
)

add_custom_target(
    flash_tangnano 
    COMMAND openFPGALoader ${CMAKE_CURRENT_BINARY_DIR}/impl/pnr/project.fs 
    VERBATIM 
    DEPENDS tangnano 
)
 