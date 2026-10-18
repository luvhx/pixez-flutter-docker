/// HTTP client adapters: native implementation (rhttp / Rust).
library;

import 'package:dio/dio.dart';
import 'package:dio_compatibility_layer/dio_compatibility_layer.dart';
import 'package:pixez/network/network_mode.dart';
import 'package:pixez/network/pixez_network_settings.dart';
import 'package:rhttp/rhttp.dart' as r;

/// Initialise the Rust HTTP engine. Must be called before any rhttp client
/// is created.
Future<void> initNetworkEngine() async {
  await r.Rhttp.init();
}

/// Adapter for the Pixiv APP API / OAuth endpoints.
Future<HttpClientAdapter> createApiAdapter({
  required String host,
  required NetworkMode mode,
}) async {
  final client = await r.RhttpCompatibleClient.create(
    settings: PixezNetworkSettings.forHost(host, mode),
  );
  return ConversionLayerAdapter(client);
}

/// Adapter for image downloads.
Future<HttpClientAdapter> createImageAdapter({
  String? source,
  required NetworkMode mode,
}) async {
  final client = await r.RhttpCompatibleClient.create(
    settings: PixezNetworkSettings.forImages(source, mode),
  );
  return ConversionLayerAdapter(client);
}

/// Adapter used for the DNS-over-HTTPS lookups.
Future<HttpClientAdapter> createDohAdapter() async {
  final client = await r.RhttpCompatibleClient.create(
    settings: r.ClientSettings(
      dnsSettings: r.DnsSettings.static(
        overrides: {
          "1dot1dot1dot1.cloudflare-dns.com": [
            '104.16.248.249',
            '104.16.249.249',
          ],
        },
      ),
      tlsSettings: r.TlsSettings(verifyCertificates: true, sni: false),
    ),
  );
  return ConversionLayerAdapter(client);
}

/// Adapter used by the "network check" screen (accepts bad certificates).
Future<HttpClientAdapter> createInsecureAdapter() async {
  final client = await r.RhttpCompatibleClient.create(
    settings: r.ClientSettings(
      tlsSettings: r.TlsSettings(verifyCertificates: false, sni: false),
    ),
  );
  return ConversionLayerAdapter(client);
}
