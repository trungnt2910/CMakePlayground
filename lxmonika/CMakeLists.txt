project(lxmonika)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include_private)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

file(GLOB_RECURSE LXSTUB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

add_driver(
    lxmonika

    ${LXSTUB_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/lxmonika.rc
)

target_compile_definitions(lxmonika PRIVATE MONIKA_IN_DRIVER=1)

target_compile_options(lxmonika PRIVATE -Wno-missing-field-initializers)

# [[msvc::forceinline]]
target_compile_options(lxmonika PRIVATE -Wno-unknown-attributes)

# NTSTATUS to PVOID in Logging
target_compile_options(lxmonika PRIVATE -Wno-int-to-void-pointer-cast)

# Deprecated ExAllocatePoolWithTag
target_compile_options(lxmonika PRIVATE -Wno-deprecated-declarations)

# Casting between older and later Monika callbacks
target_compile_options(lxmonika PRIVATE -Wno-cast-function-type-mismatch)

# RTL_CONSTANT_STRING
# UNICODE_STRING expects the number of **bytes** in its members,
# so this division is expected.
target_compile_options(lxmonika PRIVATE -Wno-sizeof-array-div)

target_link_libraries(lxmonika PRIVATE cng)
target_link_libraries(lxmonika PRIVATE wdmsec)

target_link_libraries(lxmonika PRIVATE lxstub)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/" DESTINATION "Include/lxmonika")
