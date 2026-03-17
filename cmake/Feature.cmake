set(MONIKA_FEATURES "")

function(monika_add_feature FEATURE_NAME DEFAULT)
    string(TOUPPER ${FEATURE_NAME} FEATURE_NAME_UPPER)
    option(INSTALL_${FEATURE_NAME_UPPER} "Install ${FEATURE_NAME}" ${DEFAULT})

    list(APPEND MONIKA_FEATURES ${FEATURE_NAME})
    set(MONIKA_FEATURES "${MONIKA_FEATURES}" PARENT_SCOPE)
endfunction()

monika_add_feature(Core ON)
monika_add_feature(MXSS OFF)

define_property(DIRECTORY PROPERTY MONIKA_FEATURE
    INHERITED
    BRIEF_DOCS "The feature this directory belongs to."
)

macro(monika_feature FEATURE_NAME)
    if(NOT ${FEATURE_NAME} IN_LIST MONIKA_FEATURES)
        message(FATAL_ERROR "Unknown feature: ${FEATURE_NAME}")
    endif()
    set_directory_properties(PROPERTIES MONIKA_FEATURE ${FEATURE_NAME})
endmacro()

function(monika_should_install_target name RESULT_VAR)
    get_target_property(FEATURE_DIRECTORY ${name} SOURCE_DIR)
    get_directory_property(FEATURE_NAME DIRECTORY ${FEATURE_DIRECTORY} MONIKA_FEATURE)

    string(TOUPPER "${FEATURE_NAME}" FEATURE_NAME_UPPER)

    set(${RESULT_VAR} ${INSTALL_${FEATURE_NAME_UPPER}} PARENT_SCOPE)
endfunction()
