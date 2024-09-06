#ifndef FLUTTER_NATIVE_LIB_H
#define FLUTTER_NATIVE_LIB_H

#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define FFI_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT __attribute__((__visibility__("default")))
#endif

FFI_EXPORT
void* get_ui_command(uint32_t* length);

#ifdef __cplusplus
} /* extern "C" { */
#endif

#endif  // WEBF_BRIDGE_EXPORT_H
