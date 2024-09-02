# The Memory Management of Dart FFI

Dart FFI allows dart developers to to call native C APIs, and to read, write, allocate, and deallocate native memory. 

This mechaism lead to a completely different memory management mode from regular Dart code, since normal Dart codes are auto managed by Dart GC.

For Dart developers, the underline memory allocation and deallocation from the Dart FFI should be managed manually, works like an Dart syntax C.

This article is designed to be an expansion contents of official Dart FFI docs, if you don't what the Dart FFI is, please visit [This Guide](https://dart.dev/interop/c-interop)

## How Dart FFI works

To understand why Dart FFI behavior so different compared to standard Dart codes, we needs to deep down into Dart VM, to find out how Dart FFI works in Dart VM.

At the beginning, let's look down the sample Dart FFI codes below:

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

From step 1 and step 2, we declared two typedef signature both for Dart FFI codes and Dart codes. 

It's an essential setup for generate native symbols from Dart types, and it's handled by Dart VM.

In step 3, we use an built-in function `ffi.DynamicLibrary.open` to load an dynamic library that was written in C and built by Clang. 

The `libhello.so` is an standard dynamic library with public exporting symbols. To execute the codes behind these symbols, in Linux/Unix system, we needs to use `dlopen`, `dlsym` and `dlclose` system API to tell operating system we needs this library and loading the codes into our code space. 

In Dart VM, here is [an function](https://github.com/dart-lang/sdk/blob/fe88cdb5aa822d72788a1b5109cd08a922cf4ef7/runtime/platform/utils.cc#L289) that done the same things for you, and switched to other system API for Windows platform.

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

In step 4, we use the `dylib.lookup` function to resolve native symbols in our Dart code. The genertic parameter we passed to this `lookup` function will converted to native symbol strings, and load them up using the following codes in Dart VM:

In Dart VM, here is [an function](https://github.com/dart-lang/sdk/blob/fe88cdb5aa822d72788a1b5109cd08a922cf4ef7/runtime/platform/utils.cc#L322) that done the same things for you, and switched to other system API for Windows platform.

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

With the pointer returned by `dlsym` and when wrapped with an Dart object, it's clear when we call the `hello();` in Dart, the Dart VM will call the the pointer to native library for us.

## The memory allocator in Dart FFI

From the content above, Dart VM play an role of translator between Dart and C. When you call any function defined by Dart FFI, Dart VM will generated the native symbol string and lookup that function by symbols, and when call the returned function pointer for you. 

So how about the native heap alocation? Can I use this translator to allocate an native heap memory using the `malloc()` or `free()` function defined in native library ?

The anwser is Yes:

The Dart team had published an official dart packages to allows developer to manages memory on the native heap, but also some essential utils for C strings.

```dart
import 'package:ffi/ffi.dart';
```

**Allocate an native memory using Dart FFI Package**

```dart
final Pointer<Uint16> result = malloc.allocate<Uint16>(units.length * sizeOf<Uint16>());
```

**The Allocator Class in Dart FFI package**


```dart
// Note that ole32.dll is the correct name in both 32-bit and 64-bit.
final DynamicLibrary stdlib = Platform.isWindows
    ? DynamicLibrary.open('ole32.dll')
    : DynamicLibrary.process();
```


