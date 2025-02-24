idf_component_register(
    INCLUDE_DIRS
        protobuf/src
)

option(BUILD_SHARED_LIBS OFF)
option(protobuf_BUILD_SHARED_LIBS OFF)
option(protobuf_BUILD_TESTS OFF)
option(protobuf_BUILD_CONFORMANCE OFF)
option(protobuf_BUILD_PROTOC_BINARIES OFF)
option(protobuf_WITH_ZLIB OFF)
option(protobuf_DISABLE_RTTI ON)
option(protobuf_INSTALL OFF)
option(protobuf_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/protobuf)

add_subdirectory(protobuf/cmake EXCLUDE_FROM_ALL)

add_library(alloc_pb src/alloc_pb.cpp)

set(PROTO_LIB_NAME libprotobuf-lite)
target_compile_options(${PROTO_LIB_NAME} PRIVATE -Wno-deprecated-enum-enum-conversion)
target_include_directories(${PROTO_LIB_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/local_include")

set(INPUT_LIB_PB ${CMAKE_CURRENT_BINARY_DIR}/protobuf/cmake/${PROTO_LIB_NAME}.a)
set(OUTPUT_LIB_PB ${CMAKE_BINARY_DIR}/${PROTO_LIB_NAME}.alloc8.a)
set(OBJCOPY xtensa-esp32-elf-objcopy)

# google-protobuf requires allocated memory by 8, so redefine operator new
# to allocate 8 bytes only for this library
add_custom_command(OUTPUT ${OUTPUT_LIB_PB}
     COMMAND
        ${OBJCOPY}
        ${INPUT_LIB_PB}
        --redefine-sym _Znwj=__wrap_new8
        --redefine-sym _ZdlPv=__wrap_delete8
        ${OUTPUT_LIB_PB}
     DEPENDS ${PROTO_LIB_NAME}
     COMMENT "Creating ${PROTO_LIB_NAME} with wrapped new/delete"
     VERBATIM)
add_custom_target(protobuf_lite_alloc8_generator DEPENDS ${OUTPUT_LIB_PB})

add_library(protobuf_lite_alloc8 STATIC IMPORTED GLOBAL)
add_dependencies(protobuf_lite_alloc8 protobuf_lite_alloc8_generator)
set_target_properties(protobuf_lite_alloc8 PROPERTIES IMPORTED_LOCATION "${OUTPUT_LIB_PB}")


get_target_property(INCLUDE_DIRS protobuf::libprotobuf-lite INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(COMPILE_DEFS protobuf::libprotobuf-lite INTERFACE_COMPILE_DEFINITIONS)
get_target_property(COMPILE_OPTS protobuf::libprotobuf-lite INTERFACE_COMPILE_OPTIONS)
if(INCLUDE_DIRS)
    set_target_properties(protobuf_lite_alloc8 PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${INCLUDE_DIRS}")
endif()
if(COMPILE_DEFS)
    set_target_properties(protobuf_lite_alloc8 PROPERTIES INTERFACE_COMPILE_DEFINITIONS "${COMPILE_DEFS}")
endif()
if(COMPILE_OPTS)
    set_target_properties(protobuf_lite_alloc8 PROPERTIES INTERFACE_COMPILE_OPTIONS "${COMPILE_OPTS}")
endif()

add_library(protobuf::libprotobuf-lite ALIAS protobuf_lite_alloc8)
add_dependencies(${COMPONENT_LIB} protobuf::libprotobuf-lite)

set_property(DIRECTORY "${COMPONENT_DIR}" APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTPUT_LIB_PB})

target_link_libraries(${COMPONENT_LIB} INTERFACE
    ${OUTPUT_LIB_PB}
    alloc_pb
)

set(PROTOC_BINARY_DIR "${CMAKE_SOURCE_DIR}/build_host_protoc")

externalproject_add(protoc_host
    PREFIX ${PROTOC_BINARY_DIR}
    SOURCE_DIR ${COMPONENT_DIR}/protobuf/cmake
    CONFIGURE_COMMAND cmake --log-level=ERROR -S${COMPONENT_DIR}/protobuf/cmake -DCMAKE_RULE_MESSAGES=OFF -DCMAKE_BUILD_TYPE=Release -Dprotobuf_BUILD_SHARED_LIBS=OFF -DBUILD_SHARED_LIBS=OFF -Dprotobuf_WITH_ZLIB=OFF -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_CONFORMANCE=OFF -Dprotobuf_DISABLE_RTTI=ON -Dprotobuf_BUILD_PROTOC_BINARIES=ON -DWITH_PROTOC=OFF -DCMAKE_CXX_FLAGS="-w"

    BUILD_IN_SOURCE 0
    BINARY_DIR ${PROTOC_BINARY_DIR}
    BUILD_COMMAND cmake --build . --target protoc --parallel
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS ${PROTOC_BINARY_DIR}/protoc
    EXCLUDE_FROM_ALL TRUE
)

