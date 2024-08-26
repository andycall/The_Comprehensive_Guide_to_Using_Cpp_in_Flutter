#!/bin/bash

BASEDIR=$(dirname $0)
# Help Xcode to locate cmake executable
PATH=$PATH:/opt/homebrew/bin

env

# Define the function for macOS build
build_macos() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for macOS with $BUILD_TYPE mode"
  cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -G "Unix Makefiles" -B $BASEDIR/cmake-build-macos -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-macos

#  ln -fs "$OBJROOT/XCBuildData/build.db" "${BUILT_PRODUCTS_DIR}/build_phony"
}

# Define the function for iOS build
build_ios() {
  BUILD_TYPE="${1:-Debug}"
  echo "Building for iOS with $BUILD_TYPE mode"
  cmake -DPLATFORM=OS64COMBINED -DCMAKE_TOOLCHAIN_FILE=$BASEDIR/ios-cmake/ios.toolchain.cmake -G "Xcode" -B $BASEDIR/cmake-build-ios -S $BASEDIR/
  cmake --build $BASEDIR/cmake-build-ios --config $BUILD_TYPE

#  ln -fs "$OBJROOT/XCBuildData/build.db" "${BUILT_PRODUCTS_DIR}/build_phony"
}

# Define the main function to call the appropriate build function
main() {
  if [ -z "$1" ]; then
      echo "Usage: $0 <build_arch> [additional parameters]"
      exit 1
  fi

  BUILD_ARCH=$1
  shift # Remove the first parameter, leaving the rest

  case "$BUILD_ARCH" in
      macos)
          build_macos "$@"
      ;;
      ios)
          build_ios "$@"
      ;;
      *)
          echo "Unknown architecture: $BUILD_ARCH"
          exit 1
      ;;
  esac
}

# Call the main function with all the script arguments
main "$@"