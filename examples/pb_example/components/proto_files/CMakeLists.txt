if(NOT CMAKE_BUILD_EARLY_EXPANSION)
    include(${CMAKE_SOURCE_DIR}/managed_components/albkharisov__esp_google_protobuf/cmake/ProtobufConfig.cmake)

    set(GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generated")
    # any.proto is absent in lite environment
    set(ADDITIONAL_PROTO
        google/protobuf/any.proto
    )
    list(APPEND PROTO_DIRS
       repo1
       third_party
    )

    discover_proto_files(proto_SOURCES generated_SOURCES "${PROTO_DIRS}" ${GENERATED_DIR} ${ADDITIONAL_PROTO})

    message(STATUS "found proto: ")
    foreach(line IN LISTS proto_SOURCES)
        message(STATUS "\t${line}")
    endforeach()

# idf_component_register() checks source files availability
# so create them on this step. Real ones appear during a build step
    foreach(file IN LISTS generated_SOURCES)
        get_filename_component(dir ${file} DIRECTORY)
        make_directory(${dir})
        file(TOUCH ${file})
    endforeach()

endif()

set(generated_INCLUDES
    ${GENERATED_DIR}/dir1
    ${GENERATED_DIR}
)

idf_component_register(
    INCLUDE_DIRS
        "${generated_INCLUDES}"
    SRCS
        ${generated_SOURCES}
    REQUIRES
        albkharisov__esp_google_protobuf
)

registrate_proto_generation("${PROTO_DIRS}" "${proto_SOURCES}" ${GENERATED_DIR})

