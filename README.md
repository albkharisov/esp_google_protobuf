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

Call to these functions in CMakeLists.txt of you component this order:

1. `discover_proto_files()` - find proto-files
2. `idf_component_register()` - use these files as a sources
3. `add_proto_generation()` - add generation of CXX files

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

Pay an attention to PROTO_DIRS argument of `discover_proto_files()`:
function searches for all proto-files inside component directory which called this function
and then throw out all files don't belong to PROTO_DIRS, so you shouldn't specify
subdir of mentioned already mentioned directory.
Also it's crucial to put correct dir names for PROTO_DIRS since `protoc` makes strict
search in *exact* directories.

Function `add_proto_generation()` adds dependency to current component for generating
CXX files: `*.pb.cc` / `*.pb.h`, so they are generated before building this component.
Also this function depends on building `protoc` on your host system, which is used
for generating CXX files.

## protoc host build

Using `add_proto_generation()` triggers host build of `protoc` which requires
host build environment: cmake and compiler. But they can be absent (like in CI).
In this case you can generate CXX files locally, add them into git-index,
and comment `add_proto_generation()` - this will exclude `protoc` host build.

## Warning 1

There can be a linker error if no optimization is enabled:
```
esp-idf/proto_files/libproto_files.a(file1.pb.cc.obj): in function `_ZNK6google8protobuf8internal16InternalMetadata14unknown_fieldsINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEERKT_PFSC_vE':
/home/albert/esp_google_protobuf/examples/pb_example/managed_components/albkharisov__esp_google_protobuf/protobuf/src/google/protobuf/metadata_lite.h:138:(.text._ZN6google8protobuf8internal16InternalMetadata9MergeFromINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEEvRKS2_[_ZN6google8protobuf8internal16InternalMetadata9MergeFromINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEEvRKS2_]+0x18): dangerous relocation: windowed longcall crosses 1GB boundary; return may fail: *UND*
```
So please enable optimization to avoid it.
[Issue in esp-idf repo](https://github.com/espressif/esp-idf/issues/15381)


## Warning 2

Protobuf library expects to have 8-bytes aligned addresses to use, so don't pass non-8-aligned
addresses otherwise you can get assert in inner files. It's better to use inner allocation
because it uses aligned addresses.


## Warning 3

I didn't check all the cases, structures and features of google-protobuf,
so if you find bugs - please feel free to create PR or write me an email (albkharisov@gmail.com).

