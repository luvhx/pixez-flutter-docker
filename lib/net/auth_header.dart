import 'package:flutter/foundation.dart' show kIsWeb;

/// Header used to carry the Pixiv access token.
///
/// The web deployment puts HTTP Basic Auth in front of nginx, and nginx only
/// looks at the standard `Authorization` header for it.  A Bearer token in
/// that same header makes nginx answer 401, which re-opens the browser login
/// dialog on every request after signing in to Pixiv.
///
/// On the web the token therefore travels in a custom header that nginx copies
/// into `Authorization` for the Pixiv upstream (see deploy/nginx.conf).
const String kPixivAuthHeader = kIsWeb
    ? 'X-Pixiv-Authorization'
    : 'Authorization';
