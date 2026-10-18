/// HTTP client adapters.
///
/// Native builds use `rhttp` (Rust/reqwest) with optional DNS/TLS workarounds.
/// The web build uses Dio's browser adapter and relies on the reverse proxy for
/// CORS, `Host` and `Referer` fix-ups.
library;

export 'http_adapter_native.dart'
    if (dart.library.js_interop) 'http_adapter_web.dart';
