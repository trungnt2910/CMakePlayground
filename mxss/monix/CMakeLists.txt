project(monix)

monika_feature(MXSS)

file(GLOB MONIX_ROOTFS_SOURCE_FILES "src/*")

foreach(SRC_FILE IN LISTS MONIX_ROOTFS_SOURCE_FILES)
    get_filename_component(SRC_NAME "${SRC_FILE}" NAME_WE)

    set(BIN_FILE ${CMAKE_CURRENT_BINARY_DIR}/${SRC_NAME})

    add_custom_target(${SRC_NAME}
        COMMAND ${CMAKE_CXX_COMPILER}
                ${SRC_FILE}
                -o ${BIN_FILE}
                --target=${CMAKE_SYSTEM_PROCESSOR}-linux-gnu
                -std=c++26 -O2
                -Werror -Wall -Wextra -Wpedantic
                -nostdlib -static -s
                -ffreestanding -fuse-ld=lld
        OUTPUT  ${BIN_FILE}
        COMMENT "Building Monix CXX executable ${SRC_NAME}"
        VERBATIM
    )

    monika_should_install_target(${SRC_NAME} SHOULD_INSTALL)
    if(SHOULD_INSTALL)
        install(FILES ${BIN_FILE} DESTINATION monix-${CMAKE_SYSTEM_PROCESSOR}/bin)
    endif()
endforeach()
