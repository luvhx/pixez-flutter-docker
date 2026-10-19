/// Web endpoints: everything goes through the same-origin reverse proxy so the
/// browser never has to deal with CORS or Pixiv's hot-link protection.
library;

const String kApiBaseUrl = '/pixiv-api';
const String kOauthBaseUrl = '/pixiv-oauth';
const String kAccountBaseUrl = '/pixiv-accounts';
const String kWebBaseUrl = '/pixiv-web';
const String kPixivisionBaseUrl = '/pixivision';
const String kSauceNaoBaseUrl = '/saucenao';

/// Optional custom image host (for example `i.pixiv.re`).  When set, images
/// are fetched by the browser directly from this host instead of the
/// same-origin `/pximg` proxy.
String? webImageHostOverride;

/// Rewrite Pixiv image hosts to the configured host or the proxy.
String webImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;

  final custom = webImageHostOverride?.trim();
  if (custom != null && custom.isNotEmpty) {
    if (uri.host == 'i.pximg.net' || uri.host == 's.pximg.net') {
      final normalized = custom.contains('://') ? custom : 'https://$custom';
      final base = Uri.tryParse(normalized);
      if (base != null && base.host.isNotEmpty) {
        final prefix = base.path == '/' ? '' : base.path;
        return base
            .replace(
              path: '$prefix${uri.path}',
              query: uri.hasQuery ? uri.query : null,
            )
            .toString();
      }
    }
    return url;
  }

  final prefix = switch (uri.host) {
    'i.pximg.net' => '/pximg',
    's.pximg.net' => '/spximg',
    _ => null,
  };
  if (prefix == null) return url;

  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$prefix${uri.path}$query';
}

/// Web pages are always opened externally (new tab), so keep them absolute.
String webPageUrl(String url) => url;

String? proxyHostHeader([String? host]) => host;

/// Rewrite any known Pixiv / SauceNAO host to its same-origin proxy prefix.
String webProxyUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;

  final prefix = switch (uri.host) {
    'i.pximg.net' => '/pximg',
    's.pximg.net' => '/spximg',
    'app-api.pixiv.net' => '/pixiv-api',
    'oauth.secure.pixiv.net' => '/pixiv-oauth',
    'accounts.pixiv.net' => '/pixiv-accounts',
    'www.pixiv.net' => '/pixiv-web',
    'www.pixivision.net' => '/pixivision',
    'saucenao.com' => '/saucenao',
    _ => null,
  };
  if (prefix == null) return url;

  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$prefix${uri.path}$query';
}
