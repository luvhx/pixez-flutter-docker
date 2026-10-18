/// HTTP client adapters: web implementation (browser / XHR).
library;

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:pixez/network/network_mode.dart';

/// Nothing to do on the web.
Future<void> initNetworkEngine() async {}

/// The browser adapter automatically uses the same-origin reverse proxy.
Future<HttpClientAdapter> createApiAdapter({
  required String host,
  required NetworkMode mode,
}) async => BrowserHttpClientAdapter();

Future<HttpClientAdapter> createImageAdapter({
  String? source,
  required NetworkMode mode,
}) async => BrowserHttpClientAdapter();

Future<HttpClientAdapter> createDohAdapter() async =>
    BrowserHttpClientAdapter();

Future<HttpClientAdapter> createInsecureAdapter() async =>
    BrowserHttpClientAdapter();
