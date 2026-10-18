/// One-time platform storage initialisation (databases, paths, single instance).
library;

export 'storage_init_native.dart'
    if (dart.library.js_interop) 'storage_init_web.dart';
