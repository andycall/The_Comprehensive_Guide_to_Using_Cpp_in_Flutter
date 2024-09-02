#!/bin/bash

BASEDIR=$(dirname $0)/../src/
# Help Xcode to locate cmake executable
PATH=$PATH:/opt/homebrew/bin

# Define the function for macOS build
build_macos() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for macOS with $BUILD_TYPE mode"
  cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -G "Unix Makefiles" -B $BASEDIR/cmake-build-macos -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-macos
}

# Call the main function with all the script arguments
build_macos  "$@"