/// Preview widget for a locally picked file.
library;

export 'file_image_native.dart'
    if (dart.library.js_interop) 'file_image_web.dart';
