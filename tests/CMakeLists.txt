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
        ${CMAKE_CURRENT_SOURCE_DIR}/fifo_tests.cpp
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
  SOURCES ${verilog_sources}/clock_divider.v)

verilate(msgpu_ramdac_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/fifo.v)


target_link_libraries(msgpu_ramdac_tests
    PRIVATE
        gtest_main
        gtest
)

add_executable(msgpu_tests)

target_sources(msgpu_tests
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/msgpu_tests.cpp
)

set (async_fifo ${mspkg_SOURCE_DIR}/packages/sources/async_fifo/src/vlog)

set (async_fifo_sources
    ${async_fifo}/fifo_2mem.v
    ${async_fifo}/async_fifo.v
)

verilate(msgpu_tests
  INCLUDE_DIRS "${async_fifo};${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc"
  SOURCES ${verilog_sources}/msgpu.v;${async_fifo_sources}
  TOP_MODULE msgpu
  VERILATOR_ARGS --timescale-override /1fs -Wno-WIDTH
)

target_link_libraries(msgpu_tests
  PRIVATE
      gtest_main
      gtest
)


add_test(other msgpu_ramdac_tests)
add_test(msgpu_tests msgpu_tests)
