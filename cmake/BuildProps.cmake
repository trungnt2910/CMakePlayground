set(MONIKA_BUILD_PROPS_H "${CMAKE_BINARY_DIR}/monika_build_props.h")

add_custom_target(UpdateBuildProps
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR="${CMAKE_SOURCE_DIR}"
        -DOUTPUT_FILE="${MONIKA_BUILD_PROPS_H}"
        -P "${CMAKE_SOURCE_DIR}/cmake/GetBuildProps.cmake"
    BYPRODUCTS "${MONIKA_BUILD_PROPS_H}"
    COMMENT "Checking Git status and updating metadata..."
)

add_compile_options(-include ${MONIKA_BUILD_PROPS_H})

# add_compile_options does not apply to the resource compiler.
set(CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} --preprocessor-arg=-include")
set(CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} --preprocessor-arg=\"${MONIKA_BUILD_PROPS_H}\"")

# Set timestamp separately during configure time to avoid massive rebuilds.
string(TIMESTAMP MONIKA_TIMESTAMP "%a %b %d %H:%M:%S UTC %Y" UTC)
add_compile_definitions(MONIKA_TIMESTAMP="${MONIKA_TIMESTAMP}")

# Avoid unwanted user-mode libaries from messing up with kernel-mode projects.
set(CMAKE_CXX_STANDARD_LIBRARIES "")

macro(add_executable name)
    _add_executable(${name} ${ARGN})
    add_dependencies(${name} UpdateBuildProps)
endmacro()

macro(add_library name)
    _add_library(${name} ${ARGN})
    add_dependencies(${name} UpdateBuildProps)
endmacro()
