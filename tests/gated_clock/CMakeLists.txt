add_executable(gated_clock_tests)

find_package(verilator REQUIRED)
find_package(gtest REQUIRED)

target_sources(gated_clock_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/gated_clock_tests.cpp
)

verilate(gated_clock_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc;/home/mateusz/opt/Gowin_V1.9.7Beta_linux_EN/IDE/ipcore"
  SOURCES ${verilog_sources}/gated_clock.v)

target_link_libraries(gated_clock_tests
    PRIVATE
        gtest_main
        gtest
)

add_test(gated_clock gated_clock_tests)
