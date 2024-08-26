#include "flutter_native_example.h"
#include <thread>
#include <chrono>
#include <iostream>

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
int sum(int a, int b) {
  return a + b;
}

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
int sum_long_running(int a, int b) {
  using namespace std::chrono_literals;
  // Simulate work.
  std::this_thread::sleep_for(2000ms);
  return a + b;
}
