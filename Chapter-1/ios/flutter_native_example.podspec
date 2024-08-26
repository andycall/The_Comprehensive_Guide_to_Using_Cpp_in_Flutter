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
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.script_phase = {
    :name => 'Build Native library',
    # First argument is relative path to the `rust` folder, second is name of rust library
    :script => 'bash "' + __dir__ + '/../src/build_ios_macos.sh" ios $CONFIGURATION',
    :execution_position=> :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/build_phony'],
    :output_files => [__dir__ + "/../src/cmake-build-ios/$CONFIGURATION-iphoneos/libdemo_library.a"],
  }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ' + __dir__ + '/../src/cmake-build-ios/$CONFIGURATION-iphoneos/libdemo_library.a',
  }
  s.swift_version = '5.0'
end
