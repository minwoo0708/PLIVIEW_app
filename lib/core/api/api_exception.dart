import 'package:dio/dio.dart';

/// 서버 공통 에러 응답(`{status, code, message, errors[]}`)을 담습니다.
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });

  final int status;
  final String code;
  final String message;

  /// 검증 실패(400 INVALID_INPUT)일 때 필드 이름 → 이유.
  final Map<String, String> fieldErrors;

  bool get isNetwork => code == 'NETWORK_ERROR';

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['code'] is String) {
      final errors = <String, String>{};
      for (final err in (data['errors'] as List? ?? const [])) {
        if (err is Map && err['field'] != null) {
          errors.putIfAbsent(err['field'].toString(), () => err['reason']?.toString() ?? '');
        }
      }
      return ApiException(
        status: (data['status'] as num?)?.toInt() ?? e.response?.statusCode ?? 0,
        code: data['code'] as String,
        message: data['message'] as String? ?? '알 수 없는 오류가 발생했어요.',
        fieldErrors: errors,
      );
    }
    if (e.response == null) {
      return ApiException(
        status: 0,
        code: 'NETWORK_ERROR',
        message: '서버에 연결할 수 없어요. 네트워크를 확인해 주세요.',
      );
    }
    return ApiException(
      status: e.response?.statusCode ?? 0,
      code: 'UNKNOWN',
      message: '알 수 없는 오류가 발생했어요.',
    );
  }

  /// 화면에 보여 줄 문장. 몇몇 코드는 더 친절한 문장으로 바꿉니다.
  String get userMessage => switch (code) {
        'LOGIN_FAILED' => '이메일 또는 비밀번호가 틀렸어요.',
        'PASSWORD_MISMATCH' => '현재 비밀번호가 일치하지 않아요.',
        'SPOTIFY_RATE_LIMITED' => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
        'SPOTIFY_UNAVAILABLE' || 'SPOTIFY_NOT_CONFIGURED' => '음악 정보를 불러올 수 없어요.',
        'SPOTIFY_NOT_FOUND' || 'REVIEW_NOT_FOUND' => '찾을 수 없어요.',
        _ => message,
      };

  @override
  String toString() => 'ApiException($status $code: $message)';
}
