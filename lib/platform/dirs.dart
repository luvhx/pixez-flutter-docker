/// Platform data directories.
///
/// Native builds delegate to `path_provider`; the web build has no file system
/// and returns dummy paths.  Code that actually touches those paths is guarded
/// by `kIsWeb` (downloads go through the browser instead).
library;

export 'dirs_native.dart' if (dart.library.js_interop) 'dirs_web.dart';
