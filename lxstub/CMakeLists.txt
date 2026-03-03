project(lxstub)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

file(GLOB_RECURSE LXSTUB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

add_driver(
    lxstub

    ${LXSTUB_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/lxstub.rc
)
