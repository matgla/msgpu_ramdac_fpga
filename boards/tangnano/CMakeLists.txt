find_program (gwsh "gw_sh" REQUIRED)

add_custom_target(
    tangnano 
    COMMAND ${gwsh} ${PROJECT_SOURCE_DIR}/build.tcl --board tangnano
)

find_package(Python3 COMPONENTS Interpreter REQUIRED)

