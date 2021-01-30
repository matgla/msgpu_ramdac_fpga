cmake_minimum_required(VERSION 3.11)

project(msgpu_ramdac_fpga CXX)

include(FetchContent)

FetchContent_Declare(
  mspkg
  GIT_REPOSITORY https://github.com/matgla/mspkg.git
  GIT_TAG        master
)

FetchContent_MakeAvailable(mspkg)

if (BOARD)
    string(REPLACE ":" ";" BOARD ${BOARD})

    foreach (element ${BOARD})
        if (element STREQUAL "elbert_v2")
            message (STATUS "Configuring project for: Elbert V2")
            add_subdirectory(boards/elbert_v2)
        endif ()

        if (element STREQUAL "tangnano") 
            message (STATUS "Configuring project for: Tang Nano")
            add_subdirectory(boards/tangnano)
        endif ()
    endforeach ()
endif (BOARD) 

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${mspkg_SOURCE_DIR}/cmake)
include (mspkg)

setup_mspkg(${mspkg_SOURCE_DIR})

include(CTest)

set (verilog_sources ${PROJECT_SOURCE_DIR}/src)

if (NOT DISABLE_SIMULATION)
    add_subdirectory(sim)
endif ()

if (NOT DISABLE_TESTS)
    add_subdirectory(tests)
endif ()
