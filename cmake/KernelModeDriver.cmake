# Detect WDK include paths from a llvm-mingw installation.
set(MONIKA_KM_INCLUDE_DIRECTORIES ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
list(TRANSFORM MONIKA_KM_INCLUDE_DIRECTORIES APPEND "/ddk")

#
# Import Stubs
# Add import stubs for missing symbols from ReactOS's libntoskrnl.a.
#

function(add_import_stub TARGET_NAME SOURCE_NAME)
    set(DLL_DECORATED FALSE)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
        set(DLL_ARCH "i386:x86-64")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        set(DLL_ARCH "i386")
        set(DLL_DECORATED TRUE) # Only i386 (stdcall) uses @N decoration.
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
        set(DLL_ARCH "arm")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        set(DLL_ARCH "arm64")
    else()
        message(FATAL_ERROR "Unsupported processor: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()

    find_program(DLLTOOL_EXECUTABLE
        NAMES "llvm-dlltool" "${CMAKE_C_COMPILER_TARGET}-dlltool" "dlltool"
        HINTS "${CMAKE_C_BIN_DIR}"
    )

    set(DEF_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.def")
    set(LIB_FILE "${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET_NAME}.a")

    set(DEF_CONTENT "LIBRARY ${SOURCE_NAME}\nEXPORTS\n")

    foreach(SYM_RAW IN LISTS ARGN)
        if(SYM_RAW MATCHES "([A-Za-z0-9_]+)\\(([0-9]+)\\)")
            set(SYM_NAME ${CMAKE_MATCH_1})
            set(PARAM_COUNT ${CMAKE_MATCH_2})

            if(DLL_DECORATED)
                math(EXPR STDCALL_BYTES "${PARAM_COUNT} * ${CMAKE_SIZEOF_VOID_P}")
                string(APPEND DEF_CONTENT "    ${SYM_NAME}@${STDCALL_BYTES}\n")
            else()
                string(APPEND DEF_CONTENT "    ${SYM_NAME}\n")
            endif()
        else()
            string(APPEND DEF_CONTENT "    ${SYM_RAW}\n")
        endif()
    endforeach()

    file(WRITE "${DEF_FILE}" "${DEF_CONTENT}")

    add_custom_target(${TARGET_NAME}_dlltool
        COMMAND "${DLLTOOL_EXECUTABLE}" "-m" "${DLL_ARCH}" "-d" "${DEF_FILE}" "-l" "${LIB_FILE}"
        BYPRODUCTS "${LIB_FILE}"
        DEPENDS "${DEF_FILE}"
        COMMENT "Generating import stub for ${SOURCE_NAME}..."
        VERBATIM
    )

    add_library(${TARGET_NAME} INTERFACE)
    target_link_libraries(${TARGET_NAME} INTERFACE "${LIB_FILE}")
    add_dependencies(${TARGET_NAME} ${TARGET_NAME}_dlltool)
endfunction()

add_import_stub(
    ntoscompat
    ntoskrnl.exe

    # List of symbols not exported by ReactOS ntoskrnl glue library here.
    # "FuncName(ParamCount)"
    "PsRegisterPicoProvider(2)"
)

#
# Signing
# Detect Windows 10 SDK and find signtool.
#

# This is always based on the %PROCESSOR_ARCHITECTURE% environment variable.
if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "AMD64")
    set(MONIKA_SDK_ARCH "x64")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86")
    set(MONIKA_SDK_ARCH "x86")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "ARM64")
    set(MONIKA_SDK_ARCH "ARM64")
elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "ARM")
    set(MONIKA_SDK_ARCH "ARM")
else()
    # Safe fallback.
    set(MONIKA_SDK_ARCH "x86")
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
    if(IS_DIRECTORY "${MONIKA_WINDOWS_KITS_ROOT}/bin/${DIR}/${MONIKA_SDK_ARCH}")
        if(DIR VERSION_GREATER MONIKA_LATEST_SDK_VERSION)
            set(MONIKA_LATEST_SDK_VERSION "${DIR}")
        endif()
    endif()
endforeach()

find_program(SIGNTOOL_EXECUTABLE
    NAMES signtool.exe
    HINTS "${MONIKA_WINDOWS_KITS_ROOT}/bin/${MONIKA_LATEST_SDK_VERSION}/${MONIKA_SDK_ARCH}"
    REQUIRED
)

macro(add_driver name)
    # Build raw library.
    add_library(${name} SHARED ${ARGN})

    target_compile_options(${name} PRIVATE -fms-extensions)
    target_compile_options(${name} PRIVATE -fPIC)
    target_compile_options(${name} PRIVATE -nostdlib)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i686")
        # Force __stdcall to avoid symbol clashes.
        target_compile_options(${name} PRIVATE -mrtd)
    endif()

    target_link_options(${name} PRIVATE -nostdlib)
    target_link_options(${name} PRIVATE -Wl,-subsystem=native)
    target_link_options(${name} PRIVATE -Wl,-entry=DriverEntry)
    target_link_options(${name} PRIVATE -Wl,-file-alignment=0x200)
    target_link_options(${name} PRIVATE -Wl,-section-alignment=0x1000)
    target_link_options(${name} PRIVATE -Wl,-image-base=0x140000000)
    target_link_options(${name} PRIVATE -Wl,--stack=0x100000)
    target_link_options(${name} PRIVATE -Wl,--exclude-all-symbols)
    target_link_options(${name} PRIVATE -Wl,--gc-sections)
    target_link_options(${name} PRIVATE -Wl,--dynamicbase)
    target_link_options(${name} PRIVATE -Wl,--nxcompat)
    target_link_options(${name} PRIVATE -Wl,/driver)

    target_include_directories(${name} SYSTEM PRIVATE ${MONIKA_KM_INCLUDE_DIRECTORIES})

    target_link_libraries(${name} PRIVATE ntoskrnl)
    target_link_libraries(${name} PRIVATE ntoscompat)

    set_target_properties(
        ${name} PROPERTIES

        PREFIX ""
        OUTPUT_NAME "${name}"
        SUFFIX ".sys" # A .sus file is an unsigned .sys file.

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
