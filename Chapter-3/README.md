# Memory Management in Dart FFI

Dart FFI allows Dart developers to call native C APIs, as well as read, write, allocate, and deallocate native memory.

This mechanism leads to a completely different memory management model compared to regular Dart code, as memory in Dart code is automatically managed by Dart's garbage collector (GC).

For Dart developers, using Dart FFI differs from working with normal Dart code because memory allocation and deallocation in Dart FFI must be handled manually, similar to how it works in C, but using Dart syntax.

This article expands upon the official Dart FFI documentation. If you are unfamiliar with Dart FFI, please visit [This Guide](https://dart.dev/interop/c-interop).

## How Dart FFI Works

To understand why Dart FFI behaves so differently from standard Dart code, we need to dive into the Dart VM to explore how Dart FFI works.

Let’s start by examining the following sample Dart FFI code:

```dart
// 1. Create a typedef with the FFI type signature of the C function.
typedef hello_world_func = ffi.Void Function();

// 2. Create a typedef for the variable to use when calling the C function.
typedef HelloWorld = void Function();

// 3. Open the dynamic library that contains the C function.
final dylib = ffi.DynamicLibrary.open('libhello.so');

// 4. Get a reference to the C function, and put it into a variable.
final HelloWorld hello = dylib
    .lookup<ffi.NativeFunction<hello_world_func>>('hello_world')
    .asFunction();

// 5. Call the C function.
hello();
```

In steps 1 and 2, we declare two typedefs, one for the Dart FFI code and one for the Dart function we will call. This setup is essential for generating native symbols from Dart types, and it is managed by the Dart VM.

In step 3, we use the built-in function `ffi.DynamicLibrary.open` to load a dynamic library written in C and built with Clang.

The `libhello.so` is a standard dynamic library with publicly exported symbols. To execute the code behind these symbols on Linux/Unix systems, we use the system APIs `dlopen`, `dlsym`, and `dlclose` to inform the operating system that we need this library and to load the code into our memory space.

In Dart VM, this [function](https://github.com/dart-lang/sdk/blob/fe88cdb5aa822d72788a1b5109cd08a922cf4ef7/runtime/platform/utils.cc#L289) accomplishes the same task, switching to the appropriate system API for Windows platforms.

```c++
void* Utils::LoadDynamicLibrary(const char* library_path, char** error) {
  void* handle = nullptr;

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  handle = dlopen(library_path, RTLD_LAZY);
#elif defined(DART_HOST_OS_WINDOWS)
  SetLastError(0);  // Clear any errors.

  if (library_path == nullptr) {
    handle = GetModuleHandle(nullptr);
  } else {
    // ...
  }
#endif

  if (handle == nullptr) {
    GetLastErrorAsString(error);
  }

  return handle;
}
```

In step 4, we use the `dylib.lookup` function to resolve native symbols in our Dart code. The generic parameter passed to this `lookup` function is converted to native symbol strings, which are then loaded using this function in the Dart VM:

```c++
void* Utils::ResolveSymbolInDynamicLibrary(void* library_handle,
                                           const char* symbol,
                                           char** error) {
  void* result = nullptr;

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_FUCHSIA)
  dlerror();  // Clear any errors.
  result = dlsym(library_handle, symbol);
  // Note: nullptr might be a valid return from dlsym. Must call dlerror
  // to differentiate.
  GetLastErrorAsString(error);
  return result;
#elif defined(DART_HOST_OS_WINDOWS)
  SetLastError(0);
  result = reinterpret_cast<void*>(
      GetProcAddress(reinterpret_cast<HMODULE>(library_handle), symbol));
#endif

  if (result == nullptr) {
    GetLastErrorAsString(error);
  }

  return result;
}
```

Once we obtain the pointer returned by `dlsym` and wrap it with a Dart object, calling `hello();` in Dart will invoke the corresponding function in the native library.

## Memory Allocation in Dart FFI

As described above, the Dart VM acts as a translator between Dart and C. When you call a function defined by Dart FFI, the Dart VM generates the native symbol string, looks up the function by symbols, and then invokes the returned function pointer.

### Allocating Native Memory

The Dart team has published an official Dart package that allows developers to manage memory on the native heap, as well as providing utilities for working with C strings.

```dart
import 'package:ffi/ffi.dart';
```

Using the `ffi` package, we can allocate native memory directly in Dart, and it returns a value of the `Pointer` class, which represents a raw C pointer to native heap memory.

```dart
final Pointer<Uint16> result = malloc.allocate<Uint16>(10 * sizeOf<Uint16>());
```

In this example, we allocate a chunk of native memory 10 times the size of a `Uint16` value. The `Pointer<Uint16> result` is a native pointer that points to the beginning of this memory block.

### How It Works

To understand the process behind the code, let’s examine the source code of the `package:ffi`. On Windows, the `ole32.dll` library exports the `CoTaskMemAlloc` and `CoTaskMemFree` symbols for memory allocation. On other platforms, the `DynamicLibrary.process()` call uses symbols from the main executable, which must include the `malloc` and `free` functions from the `libc` library.

The code detects platform differences and decides whether to use `malloc` or `CoTaskMemAlloc`:

```dart
// Allocates memory on the native heap, using `malloc` for POSIX systems and `CoTaskMemAlloc` for Windows.
Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
  Pointer<T> result;
  if (Platform.isWindows) {
    result = winCoTaskMemAlloc(byteCount).cast();
  } else {
    result = posixMalloc(byteCount).cast();
  }
  if (result.address == 0) {
    throw ArgumentError('Could not allocate $byteCount bytes.');
  }
  return result;
}

// Releases memory allocated on the native heap.
void free(Pointer pointer) {
  if (Platform.isWindows) {
    winCoTaskMemFree(pointer);
  } else {
    posixFree(pointer);
  }
}
```

### Dart FFI is Not Memory Safe

Dart is a memory-safe programming language, with memory management handled by the Dart VM and GC. However, Dart FFI is essentially a C language call in Dart syntax, meaning it is not memory-safe. Developers must carefully manage the memory they allocate using Dart FFI to avoid crashing their entire Flutter app.

**Tips for Debugging Dart FFI Crashes**

Crashes related to Dart FFI are difficult to inspect because, when they occur, the call stack often only shows assembly code, with few clues about the source of the problem. In debug mode, Flutter uses JIT compilation, which makes native call stacks harder to trace. However, in profile mode (AOT compilation), Dart function names are included in the native symbols, which makes debugging easier.

**Crash Stack in macOS with a Flutter Debug Build**

When running Flutter in debug mode, Dart FFI native call stacks are dynamically generated by the JIT compiler, making it challenging to reveal the full call stack.

```
flutter build macos --debug

Thread 5 Crashed:: io.flutter.ui
0   libsystem_kernel.dylib        	       0x18c96a0dc __pthread_kill + 8
1   libsystem_pthread.dylib       	       0x18c9a1cc0 pthread_kill + 288
2   libsystem_c.dylib             	       0x18c8ada40 abort + 180
3   libsystem_malloc.dylib        	       0x18c7c4b08 malloc_vreport + 908
4   libsystem_malloc.dylib        	       0x18c7c83f4 malloc_report + 64
5   libsystem_malloc.dylib        	       0x18c7dcebc find_zone_and_free + 308
6   ???                           	       0x11c308028 ???
7   ???                           	       0x12d3a48f4 ???
8   ???                           	       0x12d3a47cc ???
```

In contrast, using a profile build, you will see more useful information, such as Dart function names:

```
flutter build macos --profile

Thread 5 Crashed:: io.flutter.ui
0   libsystem_kernel.dylib        	       0x18c96a0dc __pthread_kill + 8
1   libsystem_pthread.dylib       	       0x18c9a1cc0 pthread_kill + 288
2   libsystem_c.dylib             	      

 0x18c8ada40 abort + 180
3   libsystem_malloc.dylib        	       0x18c7c4b08 malloc_vreport + 908
4   libsystem_malloc.dylib        	       0x18c7c83f4 malloc_report + 64
5   libsystem_malloc.dylib        	       0x18c7dcebc find_zone_and_free + 308
6   App                           	       0x106a6a018 stub CallNativeThroughSafepoint + 88
7   App                           	       0x106a99a28 posixFree + 136
8   App                           	       0x106a998bc MallocAllocator.free + 4 (allocation.dart:83) [inlined]
9   App                           	       0x106a998bc getUICommand + 396 (flutter_native_example.dart:51)
```

### Be Aware of Different Allocators on Windows and Other Platforms!

As mentioned above, Flutter uses `CoTaskMemAlloc` and `CoTaskMemFree` instead of `malloc` and `free` on Windows. This could lead to undefined behavior if you try to free a pointer allocated by Dart FFI using `free()` in C/C++ code on Windows.

For example, with the following Dart FFI allocated memory:

```dart
final Pointer<Uint16> result = malloc.allocate<Uint16>(10 * sizeOf<Uint16>());
```

Using `free()` will crash your Flutter app on Windows:

```c++
// Crash on Windows
free(result); // !!!!
```

Instead, use `CoTaskMemFree()` to avoid the issue:

```c++
#if WIN32
#include <Windows.h>
#endif
CoTaskMemFree(result); // Works
```

For classes shared between C/C++ and Dart FFI, it is recommended to use a custom allocator like the following `DartReadable` class, which overrides the default `new` and `delete` operators to use `CoTaskMemAlloc` and `CoTaskMemFree` on Windows.

```c++
#if WIN32
#include <Windows.h>
#endif


static void* dart_malloc(std::size_t size) {
#if WIN32
  return CoTaskMemAlloc(size);
#else
  return malloc(size);
#endif
}

static void dart_free(void* ptr) {
#if WIN32
  return CoTaskMemFree(ptr);
#else
  return free(ptr);
#endif
}

struct DartReadable {
  // Dart FFI use ole32 as it's allocator, we need to override the default allocator to compact with Dart FFI.
  static void* operator new(std::size_t size) {
    return dart_malloc(size);
  };

  void* operator new[](size_t size) {
    return dart_malloc(size);
  }

  static void operator delete(void* ptr) noexcept {
    dart_free(ptr);
  };

  static void operator delete[](void* ptr) noexcept {
    dart_free(ptr);
  };
};

// Example structs shared with Dart FFI.
struct UICommand : public DartReadable {
  int64_t data_{0};
  double f_{0.0};
  UICommand() {};
  explicit UICommand(int64_t data, double f) : data_(data), f_(f) {};
};
```

## Usage Practice: Allocating Native Memory in C/C++, Using It in Dart, and Releasing It in Dart

In most cases, it is advisable to follow RAII principles (Resource Acquisition Is Initialization) to maintain memory safety in C/C++ code. However, for advanced use cases—such as sending a buffer of UI commands from C/C++ to be consumed in Dart—releasing native-allocated memory directly in Dart can be convenient.

Here is an example where a block of linear memory is allocated in C++, used in Dart, and then released in Dart:

```c++
void* get_ui_command(uint32_t* length) {
  *length = 10;
  auto* data = new UICommand[10];

  for (int i = 0; i < 10; i++) {
    data[i].data_ = i;
    data[i].f_ = i + 0.1;
  }

  return data;
}
```

In Dart, we can receive the head pointer of this memory and use the `+` operator for continuous index reading, similar to pointer arithmetic in C.

Here is the full Dart implementation to convert this block of memory into a list of Dart objects:

```dart
List<UICommand> getUICommand() {
  Pointer<Uint32> commandLength = malloc.allocate<Uint32>(sizeOf<Uint32>());
  Pointer<NativeUICommand> nativeUICommands =
      _bindings.get_ui_command(commandLength).cast<NativeUICommand>();

  List<UICommand> data = List.generate(commandLength.value, (int index) {
    return UICommand(
        (nativeUICommands + index).ref.data, (nativeUICommands + index).ref.f);
  });
  
  malloc.free(nativeUICommands);
  malloc.free(commandLength);

  return data;
}
```

## Check the Demo and Try It Yourself

All the code in this article is located in this GitHub repository:

https://github.com/andycall/The_Comprehensive_Guide_to_Using_Cpp_in_Flutter/tree/main/Chapter-3

## Next Chapter

In the next chapter, we will focus on more details regarding bidirectional synchronous and asynchronous calls, as well as the Dart VM's Dynamic Linking (DL) APIs, which allow developers to operate on Dart objects directly from C/C++.