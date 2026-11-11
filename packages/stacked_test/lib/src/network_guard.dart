import 'dart:async';
import 'dart:io';

/// The bytes of a 1x1 transparent PNG.
const List<int> kTransparentPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// A request the guard refused to make.
class BlockedRequest {
  BlockedRequest(this.method, this.url, this.stackTrace);

  final String method;
  final Uri url;
  final StackTrace stackTrace;

  Map<String, String> toJson() => {'method': method, 'url': url.toString()};
}

class NetworkBlockedException implements IOException {
  NetworkBlockedException(this.method, this.url);

  final String method;
  final Uri url;

  String get message =>
      'Network request blocked during a journey: $method $url. '
      'Add a fixture for the service that makes this call.';

  @override
  String toString() => message;
}

const _imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'];

/// Blocks every HTTP request made through dart:io, except image requests
/// (when [allowImages] is true), which get a transparent PNG.
class StackedNetworkGuard extends HttpOverrides {
  StackedNetworkGuard({this.allowImages = true});

  final bool allowImages;
  final List<BlockedRequest> blocked = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _GuardHttpClient(this);
}

class _GuardHttpClient implements HttpClient {
  _GuardHttpClient(this.guard);

  final StackedNetworkGuard guard;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    final path = url.path.toLowerCase();
    if (guard.allowImages && _imageExtensions.any(path.endsWith)) {
      return Future.value(_ImageRequest(method, url));
    }
    guard.blocked.add(BlockedRequest(method, url, StackTrace.current));
    return Future.error(NetworkBlockedException(method, url));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  Uri _uri(String host, int port, String path) =>
      Uri(scheme: 'http', host: host, port: port, path: path);

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      openUrl(method, _uri(host, port, path));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      openUrl('GET', _uri(host, port, path));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      openUrl('POST', _uri(host, port, path));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      openUrl('PUT', _uri(host, port, path));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      openUrl('DELETE', _uri(host, port, path));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      openUrl('PATCH', _uri(host, port, path));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      openUrl('HEAD', _uri(host, port, path));

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.isSetter ? null : super.noSuchMethod(invocation);
}

class _ImageRequest implements HttpClientRequest {
  _ImageRequest(this.method, this.uri);

  @override
  final String method;

  @override
  final Uri uri;

  @override
  Future<HttpClientResponse> close() => Future.value(_ImageResponse());

  @override
  Future<HttpClientResponse> get done => Future.value(_ImageResponse());

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  List<Cookie> get cookies => const [];

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable([kTransparentPng]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
