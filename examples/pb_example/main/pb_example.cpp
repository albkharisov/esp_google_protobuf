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


