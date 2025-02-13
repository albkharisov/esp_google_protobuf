function(discover_proto_files out_proto out_sources proto_dirs generated_dir additional_proto)
    file(GLOB_RECURSE proto_SOURCES *.proto)
    set(proto_SOURCES_REL "")

    foreach(FILE ${proto_SOURCES})
        foreach(DIR ${proto_dirs})
            set(THIRD_PARTY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${DIR}")
            file(RELATIVE_PATH RELATIVE_FILE ${THIRD_PARTY_DIR} ${FILE})

            if(NOT ${RELATIVE_FILE} MATCHES "\\.\\.")
                list(APPEND proto_SOURCES_REL ${RELATIVE_FILE})
            endif()
        endforeach()
    endforeach()

    list(APPEND proto_SOURCES_REL ${additional_proto})
    list(TRANSFORM proto_SOURCES_REL REPLACE "\\.proto" "\.pb\.cc" OUTPUT_VARIABLE generated_SOURCES)
    list(TRANSFORM generated_SOURCES PREPEND "${generated_dir}/")

    set(${out_proto} ${proto_SOURCES_REL} PARENT_SCOPE)
    set(${out_sources} ${generated_SOURCES} PARENT_SCOPE)
endfunction()

function(add_proto_generation proto_dirs proto_sources generated_dir)
    list(APPEND PROTO_PATHS
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../protobuf/src
        .
        ${proto_dirs}
    )
    list(TRANSFORM PROTO_PATHS PREPEND "--proto_path=")

    set(DONE_FILE "${CMAKE_BINARY_DIR}/protoc_build_done")
    set(PROTOC "${CMAKE_SOURCE_DIR}/build_host_protoc/protoc")
    set(CPP_OUT --cpp_out=lite:${generated_dir})

    set(CMD
        cd ${CMAKE_CURRENT_SOURCE_DIR}
        && ${PROTOC}
            ${PROTO_PATHS}
            ${CPP_OUT}
            ${proto_sources}
        && touch ${DONE_FILE}
        && cd -
    )

    string(ASCII 27 Esc)
    set(ColourReset "${Esc}[m")
    set(Yellow "${Esc}[33m")

    add_custom_command(
        OUTPUT "${DONE_FILE}"
        COMMAND ${CMD}
        DEPENDS ${PROTOC}
        COMMENT "${Yellow} Generating CXX files from proto-files ${ColourReset}"
        VERBATIM
    )

    add_custom_target(generated_proto_srcs DEPENDS "${DONE_FILE}")
    add_dependencies(${COMPONENT_LIB} generated_proto_srcs)

endfunction()

