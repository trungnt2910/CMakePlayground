cmake_minimum_required(VERSION 3.24)
project(lxmonika)

set(CMAKE_CXX_STANDARD 26)

# Match Visual Studio with everything Unicode by default.
add_compile_options(-municode)
add_link_options(-municode)

# Enable PDBs for use with VS Code Debugger.
add_compile_options(-gcodeview)
add_link_options(-Wl,--pdb=)

add_compile_options(-Werror)
add_compile_options(-Wall)
add_compile_options(-Wextra)

add_subdirectory(monika)
add_subdirectory(lxmonika)
