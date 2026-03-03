cmake_minimum_required(VERSION 3.24)
project(lxmonika)

set(CMAKE_CXX_STANDARD 26)

# Match Visual Studio with everything Unicode by default.
add_compile_options(-municode)
add_link_options(-municode)

# Enable PDBs for use with VS Code Debugger.
add_compile_options(-gcodeview)
add_link_options(-Wl,--pdb=)

# Catch more errors during compilation.
add_compile_options(-Werror)
add_compile_options(-Wall)
add_compile_options(-Wextra)

# Generate `MONIKA_` properties.
include(${CMAKE_SOURCE_DIR}/cmake/BuildProps.cmake)

# Support for building kernel-mode drivers
include(${CMAKE_SOURCE_DIR}/cmake/KernelModeDriver.cmake)

add_subdirectory(lxstub)
add_subdirectory(lxmonika)
add_subdirectory(monika)
