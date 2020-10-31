add_executable(msgpu_simulation)

find_package(verilator REQUIRED)

target_sources(msgpu_simulation
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
)

verilate(msgpu_simulation
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc;/home/mateusz/opt/Gowin_V1.9.7Beta_linux_EN/IDE/ipcore"
  SOURCES ${verilog_sources}/msgpu.v)
