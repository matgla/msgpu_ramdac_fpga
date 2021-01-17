find_program (TCL "xtclsh" REQUIRED)

add_custom_target(
    elbert_v2
    COMMAND ${TCL} ${PROJECT_SOURCE_DIR}/build.tcl --board elbert_v2 
)

find_package(Python3 COMPONENTS Interpreter REQUIRED)

add_custom_target(
    flash_elbert_v2
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/flash_elbert.py --binary
    ${CMAKE_CURRENT_BINARY_DIR}/build/gpu.bin
    DEPENDS 
    elbert_v2
)

