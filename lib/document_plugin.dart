/// File saving.
///
/// Native builds use the platform channels (Storage Access Framework / photo
/// library).  The web build triggers a normal browser download.
library;

export 'document_plugin_native.dart'
    if (dart.library.js_interop) 'document_plugin_web.dart';
