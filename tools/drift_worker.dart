import 'package:drift/wasm.dart';

/// This Dart program is the entrypoint of a web worker that will be compiled to
/// JavaScript by running `build_runner build`.
void main() {
  return WasmDatabase.workerMainForOpen();
}
