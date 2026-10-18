/// Cross-platform replacement for `dart:io`.
///
/// Native platforms re-export `dart:io` unchanged.  The web build gets a
/// small, dependency-free stub implementing the small part of the API that
/// PixEz touches.  All web stubs are defensive: they never throw, they simply
/// report "nothing here", which lets the app guard its file-system code with
/// `kIsWeb` / `Platform.isWeb` checks.
library;

export 'io_stub.dart' if (dart.library.io) 'io_native.dart';
