cmake_minimum_required(VERSION 3.11)

project(msgpu_ramdac_fpga CXX)

include(FetchContent)

FetchContent_Declare(
  mspkg
  GIT_REPOSITORY https://github.com/matgla/mspkg.git
  GIT_TAG        master
)

FetchContent_MakeAvailable(mspkg)


set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${mspkg_SOURCE_DIR}/cmake)
include (mspkg)

setup_mspkg(${mspkg_SOURCE_DIR})

include(CTest)

set (verilog_sources ${PROJECT_SOURCE_DIR}/src)

add_subdirectory(sim)
add_subdirectory(tests)
