add_executable(psram_tests)

find_package(verilator REQUIRED)
find_package(gtest REQUIRED)

target_sources(psram_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/psram_tests.cpp
)

verilate(psram_tests
  INCLUDE_DIRS "${verilog_sources};${verilog_sources}/pll;${verilog_sources}/osc;/home/mateusz/opt/Gowin_V1.9.7Beta_linux_EN/IDE/ipcore"
  SOURCES ${verilog_sources}/psram.v)

target_link_libraries(psram_tests
    PRIVATE
        gtest_main
        gtest
)

add_test(psram psram_tests)
