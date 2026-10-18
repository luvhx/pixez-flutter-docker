/// Platform specific endpoints used by the app.
///
/// On the web every Pixiv endpoint is served from the same origin under a
/// reverse-proxy prefix (see `deploy/nginx.conf`).  This is required because
/// Pixiv does not send CORS headers and the browser cannot spoof the `Host`
/// or `Referer` headers.  Native builds talk to Pixiv directly.
library;

export 'endpoints_native.dart' if (dart.library.js_interop) 'endpoints_web.dart';
