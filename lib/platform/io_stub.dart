/// Web stub for `dart:io`.
///
/// Only the small surface used by PixEz is implemented.  Everything is a
/// no-op / empty value so that guarded code paths cannot crash the app in the
/// browser.  The build only uses this file on the web (`dart.library.io` is
/// false there).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class _UnsupportedSink implements StreamSink<List<int>> {
  Future<void> addStream(Stream<List<int>> stream) async {}

  Future<void> close() async {}

  void add(List<int> data) {}

  Future<void> get done => Future.value();

  void addError(Object error, [StackTrace? stackTrace]) {}
}

/// Minimal clone of `dart:io`'s `Platform`.
class Platform {
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static const bool isLinux = false;
  static const bool isMacOS = false;
  static const bool isWindows = false;
  static const bool isFuchsia = false;
  static const String operatingSystem = 'web';

  static String get version => 'web';
  static String get operatingSystemVersion => '';
  static String get localHostname => 'localhost';
  static int get numberOfProcessors => 1;
  static String get pathSeparator => '/';
  static Map<String, String> get environment => const {};
  static String get executable => '';
  static String get resolvedExecutable => '';
  static Uri get script => Uri();
  static String get localeName => 'en_US';
}

enum FileSystemEntityType { file, directory, link, notFound, unixDomainSock, pipe }

enum FileMode { read, write, append, writeOnly }

class FileStat {
  final int size;
  final int mode;
  final DateTime accessed;
  final DateTime changed;
  final DateTime modified;
  final FileSystemEntityType type;

  const FileStat({
    this.size = 0,
    this.mode = 0,
    this.type = FileSystemEntityType.notFound,
    DateTime? accessed,
    DateTime? changed,
    DateTime? modified,
  }) : accessed = accessed ?? const _Epoch(),
       changed = changed ?? const _Epoch(),
       modified = modified ?? const _Epoch();

  static Future<FileStat> stat(String path) async => const FileStat();
  static FileStat statSync(String path) => const FileStat();
}

class _Epoch implements DateTime {
  const _Epoch();

  @override
  dynamic noSuchMethod(Invocation invocation) => 0;
}

class FileSystemEntity {
  final String path;
  const FileSystemEntity(this.path);

  String get absolutePath => path;
  Uri get uri => Uri.parse(path);
  Directory get parent => Directory(path.split('/').reversed.skip(1).toList().reversed.join('/'));

  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  void deleteSync({bool recursive = false}) {}
  Future<FileStat> stat() async => const FileStat();
  FileStat statSync() => const FileStat();

  static Future<bool> isFile(String path) async => false;
  static Future<bool> isDirectory(String path) async => false;
  static Future<bool> isLink(String path) async => false;
  static Future<FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async => FileSystemEntityType.notFound;
  static FileSystemEntityType typeSync(
    String path, {
    bool followLinks = true,
  }) => FileSystemEntityType.notFound;
}

class IOSink implements StreamSink<List<int>> {
  bool _closed = false;

  void add(List<int> data) {}

  void addError(Object error, [StackTrace? stackTrace]) {}

  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> close() async {
    _closed = true;
  }

  Future<void> get done => Future.value();

  void write(Object? object) {}

  void writeln([Object? object = '']) {}

  void writeAll(Iterable objects, [String separator = '']) {}

  void writeCharCode(int charCode) {}

  Future<void> flush() async {}

  Encoding get encoding => utf8;

  set encoding(Encoding value) {}
}

class File extends FileSystemEntity {
  const File(super.path);

  Future<File> create({bool recursive = false, bool exclusive = false}) async => this;
  void createSync({bool recursive = false, bool exclusive = false}) {}

  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async => this;

  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {}

  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async => this;

  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {}

  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Uint8List readAsBytesSync() => Uint8List(0);

  Future<String> readAsString({Encoding encoding = utf8}) async => '';
  String readAsStringSync({Encoding encoding = utf8}) => '';

  Future<List<String>> readAsLines({Encoding encoding = utf8}) async => const [];
  List<String> readAsLinesSync({Encoding encoding = utf8}) => const [];

  Future<File> rename(String newPath) async => File(newPath);
  File renameSync(String newPath) => File(newPath);

  Future<File> copy(String newPath) async => File(newPath);
  File copySync(String newPath) => File(newPath);

  Future<File> delete({bool recursive = false}) async => this;

  Future<int> length() async => 0;
  int lengthSync() => 0;

  DateTime lastModifiedSync() => DateTime.fromMillisecondsSinceEpoch(0);

  Stream<List<int>> openRead([int? start, int? end]) => const Stream.empty();

  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) =>
      IOSink();

  Future<File> setLastModified(DateTime time) async => this;
  void setLastModifiedSync(DateTime time) {}
}

class Directory extends FileSystemEntity {
  const Directory(super.path);

  static Directory get current => const Directory('/');

  static Future<Directory> createTemp([String? prefix]) async =>
      Directory('/tmp/${prefix ?? ''}');

  static Directory createTempSync([String? prefix]) =>
      Directory('/tmp/${prefix ?? ''}');

  static Directory get systemTemp => const Directory('/tmp');

  Future<Directory> create({bool recursive = false}) async => this;
  void createSync({bool recursive = false}) {}

  Future<Directory> delete({bool recursive = false}) async => this;

  Future<List<FileSystemEntity>> list({
    bool recursive = false,
    bool followLinks = true,
  }) async => const [];

  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) => const [];
}

class Link extends FileSystemEntity {
  const Link(super.path);

  Future<Link> create(String target, {bool recursive = false}) async => this;
  Future<String> target() async => '';
  Future<Link> rename(String newPath) async => Link(newPath);
}

class HttpHeaders {
  static const String acceptHeader = 'accept';
  static const String acceptCharsetHeader = 'accept-charset';
  static const String acceptEncodingHeader = 'accept-encoding';
  static const String acceptLanguageHeader = 'accept-language';
  static const String authorizationHeader = 'authorization';
  static const String cacheControlHeader = 'cache-control';
  static const String connectionHeader = 'connection';
  static const String contentEncodingHeader = 'content-encoding';
  static const String contentLanguageHeader = 'content-language';
  static const String contentLengthHeader = 'content-length';
  static const String contentLocationHeader = 'content-location';
  static const String contentTypeHeader = 'content-type';
  static const String cookieHeader = 'cookie';
  static const String dateHeader = 'date';
  static const String etagHeader = 'etag';
  static const String expiresHeader = 'expires';
  static const String hostHeader = 'host';
  static const String ifModifiedSinceHeader = 'if-modified-since';
  static const String ifNoneMatchHeader = 'if-none-match';
  static const String lastModifiedHeader = 'last-modified';
  static const String locationHeader = 'location';
  static const String originHeader = 'origin';
  static const String pragmaHeader = 'pragma';
  static const String proxyAuthorizationHeader = 'proxy-authorization';
  static const String refererHeader = 'referer';
  static const String retryAfterHeader = 'retry-after';
  static const String serverHeader = 'server';
  static const String setCookieHeader = 'set-cookie';
  static const String transferEncodingHeader = 'transfer-encoding';
  static const String upgradeHeader = 'upgrade';
  static const String userAgentHeader = 'user-agent';
  static const String varyHeader = 'vary';
  static const String viaHeader = 'via';
  static const String warningHeader = 'warning';
  static const String wwwAuthenticateHeader = 'www-authenticate';

  final Map<String, List<String>> _headers = {};

  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  void clear() => _headers.clear();

  void noFolding(String name) {}
}

class HttpClient {
  bool Function(X509Certificate cert, String host, int port)? badCertificateCallback;
  bool autoUncompress = true;
  Duration? connectionTimeout;
  Duration? idleTimeout;
  String? userAgent;

  void close({bool force = false}) {}

  Future<HttpClientRequest> getUrl(Uri url) async => HttpClientRequest();
  Future<HttpClientRequest> postUrl(Uri url) async => HttpClientRequest();
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      HttpClientRequest();
}

class HttpClientRequest {
  final HttpHeaders headers = HttpHeaders();
  bool followRedirects = true;
  int maxRedirects = 5;
  int contentLength = -1;
  bool persistentConnection = true;
  bool bufferOutput = true;

  Future<void> addStream(Stream<List<int>> stream) async {}
  Future<HttpClientResponse> close() async => HttpClientResponse();
  Future<HttpClientResponse> get done => Future.value(HttpClientResponse());
  void abort([Object? exception, StackTrace? stackTrace]) {}
  void add(List<int> data) {}
  Future<void> flush() async {}
}

class HttpClientResponse {
  final HttpHeaders headers = HttpHeaders();
  int statusCode = 200;
  String reasonPhrase = 'OK';
  bool isRedirect = false;
  bool persistentConnection = true;
  int contentLength = -1;
  List<RedirectInfo> redirects = const [];
  List<Cookie> cookies = const [];

  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<List<int>>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  Future<Socket> detachSocket() async => Socket();
}

class RedirectInfo {
  final int statusCode;
  final String method;
  final Uri location;
  RedirectInfo(this.statusCode, this.method, this.location);
}

class Cookie {
  String name;
  String value;
  String? domain;
  String? path;
  DateTime? expires;
  int? maxAge;
  bool httpOnly;
  bool secure;

  Cookie(this.name, this.value)
    : httpOnly = false,
      secure = false;

  static String? fromSetCookieValue(String setCookieValue) => null;
}

class Socket {
  void add(List<int> data) {}

  void addError(Object error, [StackTrace? stackTrace]) {}

  Future<void> addStream(Stream<List<int>> stream) async {}

  Future<void> close() async {}

  Future<void> get done => Future.value();

  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<List<int>>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  void destroy() {}
}

class ServerSocket {
  static Future<ServerSocket> bind(Object address, int port) async =>
      ServerSocket();

  StreamSubscription<Socket> listen(
    void Function(Socket event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<Socket>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  Future<void> close() async {}
}

class InternetAddress {
  final String address;
  final String? host;
  final InternetAddressType type;
  final Uint8List rawAddress;

  InternetAddress(this.address, {this.host, this.type = InternetAddressType.IPv4})
    : rawAddress = Uint8List(0);

  static Future<List<InternetAddress>> lookup(
    String host, {
    InternetAddressType type = InternetAddressType.any,
  }) async => const [];

  static Future<String> reverse(String address) async => address;
}

enum InternetAddressType { IPv4, IPv6, any }

class X509Certificate {
  String get subject => '';
  String get issuer => '';
  DateTime get startValidity => DateTime.fromMillisecondsSinceEpoch(0);
  DateTime get endValidity => DateTime.fromMillisecondsSinceEpoch(0);
  Uint8List get sha1 => Uint8List(0);
  Uint8List get der => Uint8List(0);
  Uint8List get pem => Uint8List(0);
}

class Process {
  static Future<Process> start(
    Object executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async => Process();

  static Future<ProcessResult> run(
    Object executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = utf8,
    Encoding? stderrEncoding = utf8,
  }) async => ProcessResult(0, 0, '', '');

  static int runSync(Object executable, List<String> arguments, {String? workingDirectory, Map<String, String>? environment, bool includeParentEnvironment = true, bool runInShell = false, Encoding? stdoutEncoding = utf8, Encoding? stderrEncoding = utf8}) => 0;

  static Future<ProcessResult> runSync_(Object executable, List<String> arguments) async =>
      ProcessResult(0, 0, '', '');

  int get pid => 0;
  Stream<List<int>> get stdout => const Stream.empty();
  Stream<List<int>> get stderr => const Stream.empty();
  IOSink get stdin => IOSink();
  Future<int> get exitCode => Future.value(0);
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => false;
}

enum ProcessStartMode { normal, detached, detachedWithStdio, inheritStdio }

class ProcessSignal {
  static const ProcessSignal sigterm = ProcessSignal._();
  static const ProcessSignal sigkill = ProcessSignal._();
  static const ProcessSignal sigint = ProcessSignal._();
  static const ProcessSignal sighup = ProcessSignal._();
  static const ProcessSignal sigusr1 = ProcessSignal._();
  static const ProcessSignal sigusr2 = ProcessSignal._();
  const ProcessSignal._();
}

class ProcessResult {
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class Stdout extends IOSink {}
class Stderr extends IOSink {}
class Stdin extends IOSink {}

class IOException implements Exception {
  final String message;
  IOException([this.message = '']);
  @override
  String toString() => 'IOException: $message';
}

class FileSystemException implements IOException {
  final String message;
  final String? path;
  final OSError? osError;

  FileSystemException([this.message = '', this.path, this.osError]);

  @override
  String toString() => 'FileSystemException: $message${path == null ? '' : ', path = $path'}';
}

class SocketException implements IOException {
  final String message;
  final OSError? osError;
  final InternetAddress? address;
  final int? port;

  const SocketException(this.message, {this.osError, this.address, this.port});

  @override
  String toString() => 'SocketException: $message';
}

class HttpException implements IOException {
  final String message;
  final Uri? uri;

  const HttpException(this.message, {this.uri});

  @override
  String toString() => 'HttpException: $message';
}

class OSError {
  final String message;
  final int errorCode;
  const OSError([this.message = '', this.errorCode = 0]);
  @override
  String toString() => 'OSError: $message, errno = $errorCode';
}

class SignalException implements IOException {
  final String message;
  final int? osErrorCode;
  const SignalException(this.message, [this.osErrorCode]);
  @override
  String toString() => 'SignalException: $message';
}

class TlsException implements IOException {
  final String message;
  final OSError? osError;
  const TlsException(this.message, {this.osError});
  @override
  String toString() => 'TlsException: $message';
}

class HandshakeException implements TlsException {
  @override
  final String message;
  @override
  final OSError? osError;
  const HandshakeException(this.message, {this.osError});
}

class CertificateException implements TlsException {
  @override
  final String message;
  @override
  final OSError? osError;
  const CertificateException(this.message, {this.osError});
}

class SecurityContext {
  static SecurityContext get defaultContext => SecurityContext();
  void setTrustedCertificatesBytes(List<int> certBytes, {String? password}) {}
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String? password}) {}
  void useCertificateChainBytes(List<int> chainBytes, {String? password}) {}
  void usePrivateKeyBytes(List<int> keyBytes, {String? password}) {}
}

class RawSocket {
  static Future<RawSocket> connect(Object host, int port) async => RawSocket();
  void close() {}
  void shutdown() {}
}

class RawServerSocket {
  static Future<RawServerSocket> bind(Object address, int port) async =>
      RawServerSocket();
  void close() {}
}

/// `exit` is a no-op on the web.
Never exit(int code) => throw UnsupportedError('exit is not supported on web');

Stdout get stdout => Stdout();
Stderr get stderr => Stderr();
Stdin get stdin => Stdin();
int get pid => 0;

const ProcessSignal sigterm = ProcessSignal.sigterm;
const ProcessSignal sigkill = ProcessSignal.sigkill;
const ProcessSignal sigint = ProcessSignal.sigint;
const ProcessSignal sighup = ProcessSignal.sighup;
const ProcessSignal sigusr1 = ProcessSignal.sigusr1;
const ProcessSignal sigusr2 = ProcessSignal.sigusr2;

/// Kept for API parity with `dart:io` (unused on web).
class ZoneIO {}

/// `stdin`'s line splitter and friends are not needed on web.
class StdinException implements IOException {
  final String message;
  const StdinException(this.message);
  @override
  String toString() => 'StdinException: $message';
}

/// Unused but required by a few imports.
class FileLock {
  static const FileLock shared = FileLock._();
  static const FileLock exclusive = FileLock._();
  const FileLock._();
}

/// Never used on the web, exposed for API parity.
Future<Uint8List> readAllBytes(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

/// Not used, but avoids unused-import warnings for `dart:async`.
typedef _Keep = StreamSubscription<void>;

/// HTTP status codes (from `dart:io`).
class HttpStatus {
  static const int continue_ = 100;
  static const int switchingProtocols = 101;
  static const int processing = 102;
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int nonAuthoritativeInformation = 203;
  static const int noContent = 204;
  static const int resetContent = 205;
  static const int partialContent = 206;
  static const int multiStatus = 207;
  static const int alreadyReported = 208;
  static const int imUsed = 226;
  static const int multipleChoices = 300;
  static const int movedPermanently = 301;
  static const int found = 302;
  static const int movedTemporarily = 302;
  static const int seeOther = 303;
  static const int notModified = 304;
  static const int useProxy = 305;
  static const int temporaryRedirect = 307;
  static const int permanentRedirect = 308;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int paymentRequired = 402;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int notAcceptable = 406;
  static const int proxyAuthenticationRequired = 407;
  static const int requestTimeout = 408;
  static const int conflict = 409;
  static const int gone = 410;
  static const int lengthRequired = 411;
  static const int preconditionFailed = 412;
  static const int requestEntityTooLarge = 413;
  static const int requestUriTooLong = 414;
  static const int unsupportedMediaType = 415;
  static const int requestedRangeNotSatisfiable = 416;
  static const int expectationFailed = 417;
  static const int imATeapot = 418;
  static const int misdirectedRequest = 421;
  static const int unprocessableEntity = 422;
  static const int locked = 423;
  static const int failedDependency = 424;
  static const int upgradeRequired = 426;
  static const int preconditionRequired = 428;
  static const int tooManyRequests = 429;
  static const int requestHeaderFieldsTooLarge = 431;
  static const int connectionClosedWithoutResponse = 444;
  static const int unavailableForLegalReasons = 451;
  static const int clientClosedRequest = 499;
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
  static const int httpVersionNotSupported = 505;
  static const int variantAlsoNegotiates = 506;
  static const int insufficientStorage = 507;
  static const int loopDetected = 508;
  static const int notExtended = 510;
  static const int networkAuthenticationRequired = 511;
  static const int networkConnectTimeoutError = 599;
}
