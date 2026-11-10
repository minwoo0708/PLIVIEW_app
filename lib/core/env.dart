import 'package:flutter/foundation.dart';

/// 서버 주소.
/// `--dart-define=API_BASE_URL=http://192.168.0.10:8080` 으로 덮어쓸 수 있고,
/// 없으면 실행 환경에 맞춰 자동으로 고릅니다.
abstract final class Env {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8080';
    // 안드로이드 에뮬레이터에서 PC의 localhost는 10.0.2.2 입니다.
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}
