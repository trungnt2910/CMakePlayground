project(monika)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/res)

file(GLOB_RECURSE MONIKA_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

string(TIMESTAMP MONIKA_TIMESTAMP  "%a %b %d %H:%M:%S UTC %Y" UTC)
string(TIMESTAMP MONIKA_BUILD_YEAR "%Y")
if(NOT DEFINED MONIKA_BUILD_AUTHOR)
    set(MONIKA_BUILD_AUTHOR "Trung Nguyen")
endif()

add_executable(
    monika

    ${MONIKA_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/res/monika.rc
)

target_compile_definitions(monika PRIVATE MONIKA_TIMESTAMP="${MONIKA_TIMESTAMP}")
target_compile_definitions(monika PRIVATE MONIKA_BUILD_YEAR="${MONIKA_BUILD_YEAR}")
target_compile_definitions(monika PRIVATE MONIKA_BUILD_AUTHOR="${MONIKA_BUILD_AUTHOR}")

# Annoying. For complex structs we are not meant to init everything from the start.
target_compile_options(monika PRIVATE -Wno-missing-field-initializers)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # Disable ASAN for ARM-based targets since our LLVM builds
    # do not provide the required runtime libraries.
    if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64" AND
       NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7")
        target_compile_options(monika PRIVATE -fsanitize=address)
        target_link_options(monika PRIVATE -fsanitize=address)
    endif()
    target_compile_options(monika PRIVATE -fsanitize=undefined)
    target_link_options(monika PRIVATE -fsanitize=undefined)
endif()

target_link_libraries(monika ntdll)
