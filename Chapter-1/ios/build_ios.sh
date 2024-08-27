#!/bin/bash

BASEDIR=$(dirname $0)/../src/
# Help Xcode to locate cmake executable
PATH=$PATH:/opt/homebrew/bin

# Define the function for macOS build
build_ios() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for iOS with $BUILD_TYPE mode"
  cmake -DPLATFORM=OS64COMBINED -DCMAKE_TOOLCHAIN_FILE=$BASEDIR/ios-cmake/ios.toolchain.cmake -G "Xcode" -B $BASEDIR/cmake-build-ios -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-ios --config $BUILD_TYPE
}

# Call the main function with all the script arguments
build_ios  "$@"