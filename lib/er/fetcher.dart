/// Task queue.
///
/// Native builds download in a background isolate.  The browser cannot spawn
/// isolates or write to an arbitrary folder, so the web implementation streams
/// the file with Dio and hands the bytes to a normal browser download.
library;

export 'fetcher_native.dart' if (dart.library.js_interop) 'fetcher_web.dart';
