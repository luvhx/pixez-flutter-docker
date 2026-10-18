/// SQLite access.
///
/// Native builds use `sqflite_common_ffi` (bundled SQLite). The web build uses
/// `sqflite_common_ffi_web`, i.e. SQLite compiled to WebAssembly, persisting in
/// IndexedDB.  The wasm/worker assets are copied to `web/` by
/// `dart run sqflite_common_ffi_web:setup` (done by `tool/build_web.sh`).
library;

export 'db_native.dart' if (dart.library.js_interop) 'db_web.dart';
