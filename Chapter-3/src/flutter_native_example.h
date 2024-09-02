#ifndef FLUTTER_NATIVE_LIB_H
#define FLUTTER_NATIVE_LIB_H

#if defined(_WIN32)
#define FFI_EXPORT_C extern "C" __declspec(dllexport)
#define WEBF_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT_C extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_EXPORT_C int sum(int a, int b);

// A longer lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_EXPORT_C int sum_long_running(int a, int b);

#endif