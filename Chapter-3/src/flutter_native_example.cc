#include "flutter_native_example.h"
#include <thread>
#include <chrono>
#include <vector>
#include <iostream>

#if WIN32
#include <Windows.h>
#endif

struct DartReadable {
  // Dart FFI use ole32 as it's allocator, we need to override the default allocator to compact with Dart FFI.
  static void* operator new(std::size_t size) {
#if WIN32
    return CoTaskMemAlloc(size);
#else
    return malloc(size);
#endif
  };

  void* operator new[](size_t size) {
#if WIN32
    return CoTaskMemAlloc(size);
#else
    return malloc(size);
#endif
  }

  static void operator delete(void* ptr) noexcept {
#if WIN32
    return CoTaskMemFree(ptr);
#else
    return free(ptr);
#endif
  };

  static void operator delete[](void* ptr) noexcept {
#if WIN32
    return CoTaskMemFree(ptr);
#else
    return free(ptr);
#endif
  };

};

struct UICommand : public DartReadable {
  int64_t data_{0};
  double f_{0.0};
  UICommand() {};
  explicit UICommand(int64_t data, double f): data_(data), f_(f) {};
};

void* get_ui_command(uint32_t* length) {
  *length = 10;
  auto* data = new UICommand[10];

  for (int i = 0; i < 10; i ++) {
    data[i].data_ = i;
    data[i].f_ = i + 0.1;
  }

  return data;
}