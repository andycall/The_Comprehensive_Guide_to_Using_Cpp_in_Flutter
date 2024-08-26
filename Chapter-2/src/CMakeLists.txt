# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.19)

set(CMAKE_OSX_DEPLOYMENT_TARGET 10.11)
project(flutter_native_example_library)
set(CMAKE_CXX_STANDARD 17)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
endif()

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin" OR ${CMAKE_SYSTEM_NAME} MATCHES "iOS")
  add_library(demo_library STATIC
    "flutter_native_example.cc"
  )
else()
  add_library(demo_library SHARED
    "flutter_native_example.cc"
  )
endif()

set_target_properties(demo_library PROPERTIES
  PUBLIC_HEADER flutter_native_example.h
  OUTPUT_NAME "demo_library"
)

target_compile_definitions(demo_library PUBLIC DART_SHARED_LIB)
