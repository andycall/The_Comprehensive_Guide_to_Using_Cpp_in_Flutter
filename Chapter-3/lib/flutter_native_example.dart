import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'flutter_native_example_bindings_generated.dart';

final class NativeUICommand extends Struct {
  @Int64()
  external int data;

  @Double()
  external double f;
}

class UICommand {
  int data;
  double f;

  UICommand(this.data, this.f);
}

const String _libName = 'demo_library';

/// The dynamic library in which the symbols for [FlutterNativeExampleBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final FlutterNativeExampleBindings _bindings =
    FlutterNativeExampleBindings(_dylib);

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
