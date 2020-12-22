add_executable(msgpu_simulation)

find_package(verilator REQUIRED)
find_package(SFML COMPONENTS graphics REQUIRED)

target_sources(msgpu_simulation
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/color.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/image_loader.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/window.hpp 
        ${CMAKE_CURRENT_SOURCE_DIR}/msgpu_simulation.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/mcu_interface.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/vga_interface.hpp 

        ${CMAKE_CURRENT_SOURCE_DIR}/color.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/image_loader.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/window.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/msgpu_simulation.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/mcu_interface.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/vga_interface.cpp
)

target_link_libraries(msgpu_simulation
    PRIVATE 
        pthread
        sfml-graphics
        sfml-window 
        sfml-system
)

target_include_directories(msgpu_simulation PRIVATE ${SFML_INCLUDE_DIRS})

verilate(msgpu_simulation
    INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
    SOURCES ${verilog_sources}/msgpu.v
    TOP_MODULE msgpu
    VERILATOR_ARGS --trace --threads 1 -Wall -Wpedantic 
)

target_compile_options(msgpu_simulation 
    PRIVATE 
        $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra -Wpedantic -Wcast-align -Wunused -Wshadow
        -Wpointer-arith -Wcast-qual -Wno-missing-braces -std=c++2a>
)

add_custom_command(TARGET msgpu_simulation POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/test.png ${CMAKE_CURRENT_BINARY_DIR}/test.png
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/msgpu_simulation
    ${PROJECT_BINARY_DIR}/msgpu_simulation
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/test.png ${PROJECT_BINARY_DIR}/test.png
)

