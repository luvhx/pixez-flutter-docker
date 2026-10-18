/// Settings import / export.
///
/// Native builds use the Storage Access Framework.  On the web, exports become
/// browser downloads and imports use the file picker.
library;

export 'saf_plugin_native.dart'
    if (dart.library.js_interop) 'saf_plugin_web.dart';
