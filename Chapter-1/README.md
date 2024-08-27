# The Comprehensive Guide to Using C/C++ in Flutter —- Part I

Flutter is an open-source UI software development kit created by Google. Its core advantage compared to other cross-platform UI development kits is that it uses its own rendering engine, originally based on Chrome’s Skia. Currently, a new engine called Impeller has been introduced on iOS and Android. With the advantage of a self-owned rendering engine, Flutter controls every pixel on all platform devices, including mobile and desktop platforms, eliminating implementation differences on the UI between these platforms.

Flutter and Dart excel on the UI side, but for commercial business apps in production, there is a lot of business logic that often depends on other hardware or components provided by the target platform OS. The Dart programming language was intentionally designed for building delightful UIs but is not suitable for accessing hardware I/O and native system components, multithreaded programming, or high-performance computing areas. Therefore, we need to use “low-level” programming languages such as C/C++ or to handle these tasks. Not only do these languages interact directly with hardware without the need for an abstraction layer, but they also work well and efficiently across all platforms.

This guide is designed for mobile/desktop developers who want to integrate C/C++ codes into their Flutter apps. It includes best practices for configuring build tools, debugging on mobile and desktop, using Dart FFI for bidirectional synchronous and asynchronous calls, handling complex data structures, performance optimization tips, listening for essential Dart VM callbacks on the C/C++ side, and some essential reminders for the Windows platform.

## **Initialize the Flutter Project**

The Flutter command includes a built-in scaffold project for using C/C++ with Dart FFI examples.

```
flutter create --template=plugin_ffi demo_library --platforms android,ios,macos,windows,linux
```

This command creates a Flutter plugin package that contains the basic build scripts for adding C/C++ source code into Flutter packages.

The C/C++ code is configured and compiled by CMake on Windows, Linux, and Android, and it works well. However, for iOS and macOS, it is configured and compiled using CocoaPods directly.

Managing two build systems for more complex C/C++ projects is not practical for production use. Therefore, we need to modify the `src/CMakeLists.txt` file to generate a static archive library and link the build system from CocoaPods to CMake for the iOS and macOS platforms.

## Configure Static Linked Build with CMake for macOS

First, we need to update our `src/CMakeLists.txt` file and change our build target to a static library for generating a static archive library:

```cmake
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
endif()

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin" OR ${CMAKE_SYSTEM_NAME} MATCHES "iOS")
  add_library(demo_library STATIC
    "flutter_native_example.c"
  )
else()
  add_library(demo_library SHARED
    "flutter_native_example.c"
  )
endif()
```

When the build targets the macOS or iOS platform, we set the library type to a static library.

Then, add the following shell script named `build_macos.sh` or `build_ios.sh` to build our static library:

```bash
# Define the function for macOS build
build_macos() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for macOS in $BUILD_TYPE mode"
  cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -G "Unix Makefiles" -B $BASEDIR/cmake-build-macos -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-macos
}

build_macos "$@"
```

Run the following command: `./build_macos.sh Release` or `./build_macos.sh Debug` for debug purposes.

```
➜  src ./build_macos.sh Release
Building for macOS in Release mode
-- Configuring done (0.0s)
-- Generating done (0.0s)
-- Build files have been written to: /Users/andycall/workspace/flutter_native_example/src/cmake-build-macos
[ 50%] Building C object CMakeFiles/demo_library.dir/flutter_native_example.c.o
[100%] Linking C static library libdemo_library.a
[100%] Built target demo_library
```

We can see that `libdemo_library.a` was generated at `<project>/src/cmake-build-macos/libdemo_library.a`.

**Link CMake with CocoaPods in macOS**

Now, open `<project>/macos/flutter_native_example.podspec` and add a "Script Phase" to call the CMake command automatically when the user executes the `flutter run` or `flutter build` command.

```ruby
s.prepare_command = 'bash build_macos.sh'
s.script_phase = {
  :name => 'Trigger Native Build',
  # First argument is relative path to the `rust` folder, second is name of rust library
  :script => 'ln -fs "$OBJROOT/XCBuildData/build.db" "${BUILT_PRODUCTS_DIR}/build_phony"',
  :execution_position=> :before_compile,
  :input_files => ['${BUILT_PRODUCTS_DIR}/build_phony'],
  :output_files => [__dir__ + "/../src/cmake-build-macos/libdemo_library.a"],
}
s.pod_target_xcconfig = {
  'DEFINES_MODULE' => 'YES',
  'OTHER_LDFLAGS' => '-force_load ' + __dir__ + '/../src/cmake-build-macos/libdemo_library.a',
}
```

**Remove the C++ Source Files Included in CocoaPods**

Don't forget to remove all contents in `<project>/macos/Classes/flutter_native_example.c` to avoid duplicate symbols compile errors.

**Test with `flutter run` Command**

Now it's time to test our modified build scripts and see if everything is working well.

```
cd example && flutter run -d macos
```

## Migrating to iOS Platform Support

The build configuration for iOS is very similar to macOS builds.

Building for the iOS platform on macOS requires additional steps for configuring the cross-compilation toolchain.

Use the following commands at the root of the project to get the `ios-cmake` project and compile iOS targets using CMake:

```bash
git subtree add --prefix src/ios-cmake https://github.com/leetal/ios-cmake.git master --squash
```

**Add Shell Scripts to Build a Static Library for iOS**

```bash
# Define the function for iOS build
build_ios() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for iOS with $BUILD_TYPE mode"
  cmake -DPLATFORM=OS64COMBINED -DCMAKE_TOOLCHAIN_FILE=$BASEDIR/ios-cmake/ios.toolchain.cmake -G "Xcode" -B $BASEDIR/cmake-build-ios -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-ios --config $BUILD_TYPE
}
```

Run the following command: `./build_ios.sh Release` or `./build_ios.sh ios Debug` for debug purposes.

The static library will be located in `<project>/src/cmake-build-ios/Debug-iphoneos` with a Debug build and `<project>/src/cmake-build-ios/Release-iphoneos` with a Release build variant.

**Link CMake with CocoaPods in iOS**

Now it's time to modify `<project>/ios/flutter_native_example.podspec` to add the build phase and connect our scripts with the CocoaPods build.

```ruby
s.prepare_command = 'bash build_ios.sh'
s.script_phase = {
  :name => 'Trigger Native Build',
  # First argument is relative path to the `rust` folder, second is name of rust library
  :script => 'ln -fs "$OBJROOT/XCBuildData/build.db" "${BUILT_PRODUCTS_DIR}/build_phony"',
  :execution_position=> :before_compile,
  :input_files => ['${BUILT_PRODUCTS_DIR}/build_phony'],
  :output_files => [__dir__ + "/../src/cmake-build-ios/$CONFIGURATION-iphoneos/libdemo_library.a"],
}

# Flutter.framework does not contain a i386 slice.
s.pod_target_xcconfig = {
  'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  'OTHER_LDFLAGS' => '-force_load ' + __dir__ + '/../src/cmake-build-ios/$CONFIGURATION-iphoneos/libdemo_library.a',
}
```

**Remove the C++ Source Files Included in CocoaPods**

Don't forget to remove all contents in `<project>/ios/Classes/flutter_native_example.c` to avoid duplicate symbols compile errors.

**Test with `flutter run` Command**

Now it's time to test our modified build scripts and see if everything is working well.

```bash
cd example && flutter run -d <device_id>
```

## Compile for Android, Linux, and Windows

The Flutter scaffold project already has good configuration for building on Android, Linux, and Windows using dynamic library loading.

## Check the Demo and Try It Yourself

All the code in this article is located in this GitHub repository:

https://github.com/andycall/The_Comprehensive_Guide_to_Using_Cpp_in_Flutter/tree/main/Chapter-1

## Next Chapter

In the next chapter, we will focus on debugging C/C++ code in Flutter apps across multiple platforms, using a range of development IDEs such as Xcode, Visual Studio, Android Studio, and CLion.
