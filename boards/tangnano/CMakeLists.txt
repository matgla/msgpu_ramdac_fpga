find_program (gwsh "gw_sh" REQUIRED)

add_custom_target(
    tangnano 
    COMMAND ${gwsh} ${PROJECT_SOURCE_DIR}/build.tcl --board tangnano
)

find_package(Python3 COMPONENTS Interpreter REQUIRED)

find_program(docker_executable docker REQUIRED)

add_custom_target(
    flash_gw_tangnano
    COMMAND 
    sudo ${docker_executable} run --privileged --cap-add=ALL
        -v /dev:/dev 
        -v /lib/modules:/lib/modules 
        -v ${CMAKE_CURRENT_BINARY_DIR}/impl/pnr:/var/binary 
        -it pepijndevos/apicula /bin/bash -c 
        "apt update && apt -y install kmod; /usr/src/gowin/Programmer/bin/programmer_cli -d GW1N-1 -r2 -f /var/binary/project.fs"
    VERBATIM
    DEPENDS tangnano
)

add_custom_target(
    flash_tangnano 
    COMMAND openFPGALoader ${CMAKE_CURRENT_BINARY_DIR}/impl/pnr/project.fs 
    VERBATIM 
    DEPENDS tangnano 
)
