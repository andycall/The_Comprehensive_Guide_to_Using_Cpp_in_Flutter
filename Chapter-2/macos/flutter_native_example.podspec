#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_native_example.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_native_example'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'
  s.library = 'c++'
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

  s.swift_version = '5.0'
end
