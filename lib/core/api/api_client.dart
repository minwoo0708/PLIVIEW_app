import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../env.dart';
import 'api_exception.dart';

/// 서버와 통신하는 HTTP 클라이언트.
/// - 저장된 토큰을 `Authorization: Bearer ...` 헤더로 붙입니다.
/// - 에러는 모두 [ApiException]으로 바꿔 던집니다.
/// - 401 UNAUTHORIZED가 오면 [onUnauthorized]를 불러 로그아웃시킵니다.
class ApiClient {
  ApiClient(this._tokens, {String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            contentType: Headers.jsonContentType,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) {
          final data = e.response?.data;
          if (e.response?.statusCode == 401 && data is Map && data['code'] == 'UNAUTHORIZED') {
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
  }

  final TokenStorage _tokens;
  final Dio _dio;

  /// 토큰이 만료·위조됐을 때 호출됩니다. 인증 상태 관리자가 등록합니다.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) => _send(() => _dio.delete(path, data: body));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return {
      for (final e in query.entries)
        if (e.value != null) e.key: e.value,
    };
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStorageProvider)));
