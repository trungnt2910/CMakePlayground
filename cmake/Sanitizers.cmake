set(MONIKA_ASAN_ARCH ${CMAKE_SYSTEM_PROCESSOR})
# For some weird reasons, i686 MinGW provides libclang_rt.asan_dynamic-i386.dll.
# Note the i386, not i686.
if(MONIKA_ASAN_ARCH MATCHES "i686")
    set(MONIKA_ASAN_ARCH "i386")
endif()

# Enabling sanitizers forces the executable to be dynamically linked to these.
set(MONIKA_SANITIZER_DLLS
    "libc++.dll"
    "libclang_rt.asan_dynamic-${MONIKA_ASAN_ARCH}.dll"
    "libunwind.dll"
)

function(monika_target_add_sanitizers name)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        # Disable ASAN for ARM-based targets since our LLVM builds
        # do not provide the required runtime libraries.
        if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64" AND
        NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7")
            target_compile_options(${name} PRIVATE -fsanitize=address)
            target_link_options(${name} PRIVATE -fsanitize=address)
        endif()

        target_compile_options(${name} PRIVATE -fsanitize=undefined)
        target_link_options(${name} PRIVATE -fsanitize=undefined)
    endif()
endfunction()

function(monika_install_sanitizers name)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        foreach(DLL_NAME ${MONIKA_SANITIZER_DLLS})
            find_file(DLL_PATH_${DLL_NAME}
                NAMES ${DLL_NAME}
                PATHS ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES}
                PATH_SUFFIXES "../bin" # The actual .dlls are in bin/; lib/ contains the glues.
            )

            if(DLL_PATH_${DLL_NAME})
                add_custom_command(TARGET ${name} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${DLL_PATH_${DLL_NAME}}"
                        "$<TARGET_FILE_DIR:${name}>/${DLL_NAME}"
                )

                set_property(TARGET ${name} APPEND PROPERTY
                    ADDITIONAL_CLEAN_FILES "$<TARGET_FILE_DIR:${name}>/${DLL_NAME}"
                )

                install(FILES "${DLL_PATH_${DLL_NAME}}" DESTINATION bin/${MONIKA_INSTALL_ARCH})
            endif()
        endforeach()
    endif()
endfunction()
