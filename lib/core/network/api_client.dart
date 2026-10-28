import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// Holds the current bearer token in memory for the interceptor.
class SessionToken {
  String? value;
}

/// Attaches the bearer token and reports 401s on authenticated requests.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._token, {required this.onUnauthorized});

  final SessionToken _token;
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _token.value;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sentToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && sentToken) onUnauthorized();
    handler.next(err);
  }
}

/// Debug-only request log: method, path and status. Never headers or bodies,
/// so tokens and passwords cannot leak into logs.
class SafeLogInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('[api] ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[api] ${err.requestOptions.method} ${err.requestOptions.path} ✕ ${err.response?.statusCode ?? err.type.name}');
    handler.next(err);
  }
}

/// Thin wrapper over Dio that unwraps the `{ "data": ... }` envelope and
/// converts every failure into an [ApiException].
class ApiClient {
  ApiClient(this.dio);

  factory ApiClient.create({
    required String baseUrl,
    required SessionToken token,
    required void Function() onUnauthorized,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(AuthInterceptor(token, onUnauthorized: onUnauthorized));
    if (kDebugMode) dio.interceptors.add(SafeLogInterceptor());
    return ApiClient(dio);
  }

  final Dio dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query, required T Function(Object? data) parse, CancelToken? cancelToken}) =>
      _send(() => dio.get<dynamic>(path, queryParameters: _clean(query), cancelToken: cancelToken), parse);

  Future<T> post<T>(String path, {Object? body, required T Function(Object? data) parse}) =>
      _send(() => dio.post<dynamic>(path, data: body), parse);

  Future<T> put<T>(String path, {Object? body, required T Function(Object? data) parse}) =>
      _send(() => dio.put<dynamic>(path, data: body), parse);

  Future<void> delete(String path) => _send(() => dio.delete<dynamic>(path), (_) {});

  Future<void> postEmpty(String path) => _send(() => dio.post<dynamic>(path), (_) {});

  Future<T> _send<T>(Future<Response<dynamic>> Function() request, T Function(Object? data) parse) async {
    try {
      final response = await request();
      if (response.statusCode == 204) return parse(null);
      final body = response.data;
      if (body is! Map || !body.containsKey('data')) {
        throw const ApiException(ApiErrorKind.malformed);
      }
      return parse(body['data']);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return {
      for (final e in query.entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: e.value,
    };
  }
}

Map<String, dynamic> asMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return data.cast<String, dynamic>();
  throw const ApiException(ApiErrorKind.malformed);
}

List<Map<String, dynamic>> asMapList(Object? data) {
  if (data is! List) throw const ApiException(ApiErrorKind.malformed);
  return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}
