# esp_google_protobuf

This is a wrapper for Google Protobuf library version v3.20.3 (29/09/2022).
I haven't managed to port last version, since it depends on Abseil,
and porting abseil is not easy. Currently lite version is supported.

## What is Protobuf?

Protocol Buffers are language-neutral, platform-neutral extensible mechanisms for serializing structured data.

## What this library does?

It:
* builds `protoc` for your host PC where build runs
* builds `libprotobuf-lite.a`
* creates `libprotobuf-lite.alloc8.a` which uses aliased new/delete
to allocate 8-bytes aligned memory
* recursively finds all `*.proto` files in specific directory
* produces `*.pb.cc` / `*.pb.h` files from found `*.proto` with `protoc`
* creates list of generated sources to be used in `idf_component_register()`

## Using

There is an example in `example` directory.
Script automatically finds all `*.proto` files recursively, and
you can add necessary built-in proto-files (like `any.proto`) manually.
You should specify all directories to search. Generated files are
created relatively to this directories.
Generated directory can be any you want. I use generation into source
but you can use build directory as an output like this:
```
set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
```
But it's not convenient if you generate `compile_commands.json` with clang compiler.


## Warning 1

There can be a linker error if no optimization is enabled:
```
esp-idf/proto_files/libproto_files.a(file1.pb.cc.obj): in function `_ZNK6google8protobuf8internal16InternalMetadata14unknown_fieldsINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEERKT_PFSC_vE':
/home/albert/esp_google_protobuf/examples/pb_example/managed_components/albkharisov__esp_google_protobuf/protobuf/src/google/protobuf/metadata_lite.h:138:(.text._ZN6google8protobuf8internal16InternalMetadata9MergeFromINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEEvRKS2_[_ZN6google8protobuf8internal16InternalMetadata9MergeFromINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEEvRKS2_]+0x18): dangerous relocation: windowed longcall crosses 1GB boundary; return may fail: *UND*
```
So please enable optimization to avoid it.

## Warning 2

Protobuf library expects to have 8-bytes aligned addresses to use, so don't pass non-8-aligned
addresses otherwise you can get assert in inner files. It's better to use inner allocation
because it uses aligned addresses.

## Warning 3

I didn't check all the cases, structures and features of google-protobuf,
so if you find bugs - please feel free to create PR or write me an email (albkharisov@gmail.com).

