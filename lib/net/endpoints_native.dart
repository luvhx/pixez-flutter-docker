/// Native endpoints: talk to Pixiv directly.
library;

const String kApiBaseUrl = 'https://app-api.pixiv.net';
const String kOauthBaseUrl = 'https://oauth.secure.pixiv.net';
const String kAccountBaseUrl = 'https://accounts.pixiv.net';
const String kWebBaseUrl = 'https://www.pixiv.net';
const String kPixivisionBaseUrl = 'https://www.pixivision.net';
const String kSauceNaoBaseUrl = 'https://saucenao.com';

/// Native builds keep absolute image URLs.
String webImageUrl(String url) => url;

/// Web-only custom image host setting; unused on native builds.
String? webImageHostOverride;

/// Web only: rewrite `www.pixiv.net` links.
String webPageUrl(String url) => url;

/// Web only: the reverse proxy may need to know the original host.
String? proxyHostHeader([String? host]) => null;

/// Native builds always use absolute URLs.
String webProxyUrl(String url) => url;
