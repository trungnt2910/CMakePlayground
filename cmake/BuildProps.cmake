set(MONIKA_BUILD_PROPS_H "${CMAKE_BINARY_DIR}/monika_build_props.h")

add_custom_target(UpdateBuildProps
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR="${CMAKE_SOURCE_DIR}"
        -DOUTPUT_FILE="${MONIKA_BUILD_PROPS_H}"
        -P "${CMAKE_SOURCE_DIR}/cmake/GetBuildProps.cmake"
    BYPRODUCTS "${MONIKA_BUILD_PROPS_H}"
    COMMENT "Checking Git status and updating metadata..."
)

# add_compile_options does not apply to the resource compiler.
set(CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} --preprocessor-arg=-include")
set(CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} --preprocessor-arg=\"${MONIKA_BUILD_PROPS_H}\"")

# Set timestamp separately during configure time to avoid massive rebuilds.
string(TIMESTAMP MONIKA_TIMESTAMP "%a %b %d %H:%M:%S UTC %Y" UTC)

macro(monika_target_build_props name)
    add_dependencies(${name} UpdateBuildProps)

    target_compile_options(${name} PRIVATE -include${MONIKA_BUILD_PROPS_H})
    target_compile_definitions(${name} PRIVATE MONIKA_TIMESTAMP="${MONIKA_TIMESTAMP}")
endmacro()

macro(monika_target_pdb name)
    set_property(TARGET ${name} APPEND PROPERTY
        ADDITIONAL_CLEAN_FILES "$<TARGET_FILE_DIR:${name}>/$<TARGET_FILE_BASE_NAME:${name}>.pdb"
    )
endmacro()

macro(monika_target_mingw_pdb name)
    target_link_options(${name} PRIVATE
        -Wl,--pdb=$<TARGET_FILE_DIR:${name}>/$<TARGET_FILE_BASE_NAME:${name}>.pdb)

    monika_target_pdb(${name})
endmacro()

macro(add_executable name)
    _add_executable(${name} ${ARGN})

    monika_target_build_props(${name})
    monika_target_mingw_pdb(${name})
endmacro()

macro(add_library name)
    _add_library(${name} ${ARGN})

    monika_target_build_props(${name})
    monika_target_mingw_pdb(${name})
endmacro()
