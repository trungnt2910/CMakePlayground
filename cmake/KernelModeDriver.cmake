# This is always based on the %PROCESSOR_ARCHITECTURE% environment variable.
if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "AMD64")
    set(MONIKA_HOST_SDK_ARCH "x64")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86")
    set(MONIKA_HOST_SDK_ARCH "x86")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "ARM64")
    set(MONIKA_HOST_SDK_ARCH "ARM64")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "ARM")
    set(MONIKA_HOST_SDK_ARCH "ARM")
else()
    # Safe fallback.
    set(MONIKA_HOST_SDK_ARCH "x86")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    set(MONIKA_SDK_ARCH "x64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
    set(MONIKA_SDK_ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
    set(MONIKA_SDK_ARCH "ARM")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(MONIKA_SDK_ARCH "ARM64")
endif()

set(REGS
    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots"
    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows Kits\\Installed Roots"
)

foreach(REG IN LISTS REGS)
    cmake_host_system_information(RESULT KITS_ROOT
        QUERY WINDOWS_REGISTRY ${REG}
        VALUE "KitsRoot10"
    )
    if(EXISTS "${KITS_ROOT}")
        set(MONIKA_WINDOWS_KITS_ROOT "${KITS_ROOT}")
        break()
    endif()
endforeach()

if(NOT MONIKA_WINDOWS_KITS_ROOT)
    message(FATAL_ERROR "Failed to determine Windows 10 SDK location.")
endif()

# Find all Windows 10 SDK versions available by scanning what binaries are provided.
file(GLOB SDK_BIN_DIRS RELATIVE
    "${MONIKA_WINDOWS_KITS_ROOT}/bin"
    "${MONIKA_WINDOWS_KITS_ROOT}/bin/10.*"
)

set(MONIKA_LATEST_SDK_VERSION "0.0.0.0")
foreach(DIR IN LISTS SDK_BIN_DIRS)
    # Find an SDK that also has WDK for kernel headers and libraries for the target arch.
    if(IS_DIRECTORY "${MONIKA_WINDOWS_KITS_ROOT}/bin/${DIR}/${MONIKA_HOST_SDK_ARCH}" AND
       IS_DIRECTORY "${MONIKA_WINDOWS_KITS_ROOT}/Lib/${DIR}/km/${MONIKA_SDK_ARCH}" AND
       IS_DIRECTORY "${MONIKA_WINDOWS_KITS_ROOT}/Include/${DIR}/km")
        if(DIR VERSION_GREATER MONIKA_LATEST_SDK_VERSION)
            set(MONIKA_LATEST_SDK_VERSION "${DIR}")
        endif()
    endif()
endforeach()

find_program(SIGNTOOL_EXECUTABLE
    NAMES signtool.exe
    HINTS "${MONIKA_WINDOWS_KITS_ROOT}/bin/${MONIKA_LATEST_SDK_VERSION}/${MONIKA_HOST_SDK_ARCH}"
    REQUIRED
)

macro(add_driver name)
    set(DRIVER_SRCS "")
    set(DRIVER_DEFS "")

    foreach(file ${ARGN})
        if(file MATCHES "\\.def$")
            if(IS_ABSOLUTE "${file}")
                list(APPEND DRIVER_DEFS "${file}")
            else()
                list(APPEND DRIVER_DEFS "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
            endif()
        else()
            list(APPEND DRIVER_SRCS "${file}")
        endif()
    endforeach()

    # Build raw library.
    _add_library(${name} SHARED ${DRIVER_SRCS})

    # Make sure the library has access to Monika props.
    monika_target_build_props(${name})

    # Register the PDB with CMake.
    monika_target_pdb(${name})

    # Lock to RS1 to target as many Windows devices as possible.
    target_compile_definitions(${name} PRIVATE NTDDI_VERSION=NTDDI_WIN10_RS1)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
        target_compile_definitions(${name} PRIVATE _AMD64_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        target_compile_definitions(${name} PRIVATE _X86_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
        target_compile_definitions(${name} PRIVATE _ARM_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        target_compile_definitions(${name} PRIVATE _ARM64_)
    endif()

    # Force MSVC mode.
    target_compile_options(${name} PRIVATE --target=${CMAKE_SYSTEM_PROCESSOR}-pc-windows-msvc)
    target_compile_options(${name} PRIVATE -fms-extensions)
    target_compile_options(${name} PRIVATE -fms-compatibility)
    target_compile_options(${name} PRIVATE -fms-compatibility-version=19.30)
    target_compile_options(${name} PRIVATE -nostdlib)
    target_compile_options(${name} PRIVATE -nostdinc)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        # Force __stdcall to avoid symbol clashes.
        target_compile_options(${name} PRIVATE -mrtd)
    endif()

    target_link_options(${name} PRIVATE --target=${CMAKE_SYSTEM_PROCESSOR}-pc-windows-msvc)
    target_link_options(${name} PRIVATE -nostdlib)
    target_link_options(${name} PRIVATE -fuse-ld=lld)
    target_link_options(${name} PRIVATE -Wl,-exclude-all-symbols)
    target_link_options(${name} PRIVATE -Wl,/debug:FULL)
    target_link_options(${name} PRIVATE -Wl,/subsystem:native)
    target_link_options(${name} PRIVATE -Wl,/entry:DriverEntry)
    target_link_options(${name} PRIVATE -Wl,/filealign:0x200)
    target_link_options(${name} PRIVATE -Wl,/align:0x1000)
    target_link_options(${name} PRIVATE -Wl,/base:0x140000000)
    target_link_options(${name} PRIVATE -Wl,/stack:0x100000)
    target_link_options(${name} PRIVATE -Wl,/opt:ref)
    target_link_options(${name} PRIVATE -Wl,/opt:icf)
    target_link_options(${name} PRIVATE -Wl,/dynamicbase)
    target_link_options(${name} PRIVATE -Wl,/nxcompat)
    target_link_options(${name} PRIVATE -Wl,/driver)
    target_link_options(${name} PRIVATE -Wl,/implib:$<TARGET_IMPORT_FILE:${name}>)
    target_link_options(${name} PRIVATE
        -Wl,/pdb:$<TARGET_FILE_DIR:${name}>/$<TARGET_FILE_BASE_NAME:${name}>.pdb)

    foreach(def_file ${DRIVER_DEFS})
        target_link_options(${name} PRIVATE "-Wl,/def:${def_file}")
    endforeach()

    target_include_directories(${name} SYSTEM PRIVATE
        ${MONIKA_WINDOWS_KITS_ROOT}/Include/${MONIKA_LATEST_SDK_VERSION}/km
        ${MONIKA_WINDOWS_KITS_ROOT}/Include/${MONIKA_LATEST_SDK_VERSION}/km/crt
        ${MONIKA_WINDOWS_KITS_ROOT}/Include/${MONIKA_LATEST_SDK_VERSION}/shared
    )

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
        target_compile_definitions(${name} PRIVATE _AMD64_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        target_compile_definitions(${name} PRIVATE _X86_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
        target_compile_definitions(${name} PRIVATE _ARM_)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        target_compile_definitions(${name} PRIVATE _ARM64_)
    endif()

    target_link_directories(${name} PRIVATE
        ${MONIKA_WINDOWS_KITS_ROOT}/Lib/${MONIKA_LATEST_SDK_VERSION}/km/${MONIKA_SDK_ARCH}
    )

    target_link_libraries(${name} PRIVATE ntoskrnl)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        target_link_libraries(${name} PRIVATE bufferoverflowk)
    endif()

    set_target_properties(
        ${name} PROPERTIES

        PREFIX ""
        OUTPUT_NAME "${name}"
        SUFFIX ".sys"

        IMPORT_PREFIX ""
        ARCHIVE_OUTPUT_NAME "${name}"
        IMPORT_SUFFIX ".lib"
    )

    # Sign the driver.
    add_custom_command(TARGET ${name} POST_BUILD
        COMMAND "${SIGNTOOL_EXECUTABLE}" sign /v /fd sha256 /n WDKTestCert "$<TARGET_FILE:${name}>"
        COMMENT "Signing driver ${name}.sys with WDKTestCert"
    )
endmacro()
