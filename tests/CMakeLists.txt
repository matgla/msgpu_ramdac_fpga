enable_testing()

add_executable(msgpu_ramdac_tests)

find_package(verilator REQUIRED)
find_package(gtest REQUIRED)

target_sources(msgpu_ramdac_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/clock_divider_tests.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gated_clock_tests.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/psram_tests.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/mcu_bus_tests.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/msgpu_tests.cpp
)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/psram.v)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/gated_clock.v)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/mcu_bus.v)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/msgpu.v)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/clock_divider.v)


target_link_libraries(msgpu_ramdac_tests
    PRIVATE
        gtest_main
        gtest
)

add_test(tests msgpu_ramdac_tests)
