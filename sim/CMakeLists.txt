add_executable(msgpu_simulation)

find_package(verilator REQUIRED)
find_package(SFML COMPONENTS graphics REQUIRED)

target_sources(msgpu_simulation
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/window.hpp 

        ${CMAKE_CURRENT_SOURCE_DIR}/window.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
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
)

add_custom_command(TARGET msgpu_simulation POST_BUILD 
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/test.png ${CMAKE_CURRENT_BINARY_DIR}/test.png)

