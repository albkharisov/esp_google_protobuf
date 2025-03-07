# pb_example

Simple serialization/deserialization example.
Use int, string, bytes, any, oneof fields.


#### Build:
```
idf.py build
```


#### Protobuf

```protobuf
syntax = "proto3";
package example;

import "google/protobuf/any.proto";
import "logs.proto";

message SubMessage {
  int32 val = 1;
}

message foo {
  int32 bar = 1;

  google.protobuf.Any val = 2;

  optional string s = 3;
  optional bytes b = 4;

  oneof test_oneof {
    string name = 5;
    SubMessage sub_message = 6;
  }

  extlib.msg1 m1 = 7;
}
```


#### main/pb_example.cpp:

```cpp
#include "file1.pb.h"
#include "google/protobuf/any.pb.h"
#include "logs.pb.h"
#include "esp_log.h"

static const char* const tag = "pb_example";

extern "C"
void app_main(void)
{
    bool result = false;
    std::string buffer;

    {
        example::foo f{};
        extlib::msg1 m{};

        f.mutable_b()->append("\xAA\xBB\xCC");
        f.mutable_s()->append("def");
        m.add_data(12);
        m.add_data(15);
        f.mutable_val()->PackFrom(m);
        m.clear_data();
        m.add_data(3);
        m.add_data(4);
        *f.mutable_m1() = m;

        f.mutable_sub_message();

        // add oneof and rewrite it
        f.mutable_name()->append("Echpochmuck");
        f.mutable_sub_message()->set_val(99);

        result = f.SerializeToString(&buffer);

        ESP_LOGI(tag, "serialization %s", result ? "OK" : "FAILED");
    }

    {
        example::foo f{};
        extlib::msg1 m{};

        result = f.ParseFromString(buffer);

        ESP_LOGI(tag, "deserialization %s", result ? "OK" : "FAILED");

        ESP_LOGI(tag, "f.s: \'%s\'", f.s().c_str());
        for (const auto& v : f.b()) {
            ESP_LOGI(tag, "f.b: 0x%02X", v);
        }

        result = f.val().UnpackTo(&m);
        ESP_LOGI(tag, "deserialization of Any field %s", result ? "OK" : "FAILED");

        for (const auto& v : m.data()) {
            ESP_LOGI(tag, "m.data: %ld", v);
        }

        for (const auto& v : f.m1().data()) {
            ESP_LOGI(tag, "v.m1.data: %ld", v);
        }

        switch(f.test_oneof_case()) {
        case example::foo::kSubMessage:
            ESP_LOGI(tag, "oneof is f.sub_message().val(): %ld", f.sub_message().val());
            break;
        case example::foo::kName:
            ESP_LOGI(tag, "oneof is f.name(): %s", f.name().c_str());
            break;
        case example::foo::TEST_ONEOF_NOT_SET:
            ESP_LOGI(tag, "oneof is not set");
            break;
        }

    }
}
```


#### components/proto_files/CMakeLists.txt:

```cmake
if(NOT CMAKE_BUILD_EARLY_EXPANSION)
    include(${CMAKE_SOURCE_DIR}/managed_components/albkharisov__esp_google_protobuf/cmake/ProtobufConfig.cmake)

    set(GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generated")
    # any.proto is absent in lite environment
    set(ADDITIONAL_PROTO
        google/protobuf/any.proto
    )
    list(APPEND PROTO_DIRS
       repo1
       third_party/repo2
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

# comment this if you want to keep generated CXX files in git index
# and don't want to build protoc and generate proto files each time.
add_proto_generation("${PROTO_DIRS}" "${proto_SOURCES}" ${GENERATED_DIR})
```
