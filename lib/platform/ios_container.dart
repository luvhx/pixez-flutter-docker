/// iOS App Group container lookup (used to share the glance cache with the
/// widget extension).  Returns `null` everywhere else.
library;

export 'ios_container_native.dart'
    if (dart.library.js_interop) 'ios_container_web.dart';
