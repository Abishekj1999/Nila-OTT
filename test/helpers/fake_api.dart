import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nilaott/core/network/api_client.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

class FakeResponse {
  const FakeResponse(this.status, [this.body]);

  final int status;
  final Object? body;
}

/// Records requests and replies with canned responses keyed by "METHOD path".
class FakeAdapter implements HttpClientAdapter {
  final Map<String, FakeResponse> routes = {};
  final List<RequestOptions> requests = [];

  void on(String method, String path, int status, [Object? body]) => routes['$method $path'] = FakeResponse(status, body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final response = routes['${options.method} ${options.path}'];
    if (response == null) return ResponseBody.fromString('{"message":"Not found"}', 404, headers: _json);
    final body = response.body;
    final text = body == null ? '' : (body is String ? body : jsonEncode(body));
    return ResponseBody.fromString(text, response.status, headers: _json);
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

ApiClient fakeClient(FakeAdapter adapter, {SessionToken? token, void Function()? onUnauthorized}) {
  final client = ApiClient.create(
    baseUrl: 'http://test.local/api/v1',
    token: token ?? SessionToken(),
    onUnauthorized: onUnauthorized ?? () {},
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}
