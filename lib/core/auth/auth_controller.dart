import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/user.dart';
import 'token_storage.dart';

/// 로그인 상태.
sealed class AuthState {
  const AuthState();
}

/// 앱 시작 직후 저장된 토큰을 확인하는 중.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedOut extends AuthState {
  const SignedOut();
}

class SignedIn extends AuthState {
  const SignedIn(this.user);
  final User user;
}

class AuthController extends Notifier<AuthState> {
  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  @override
  AuthState build() {
    _api.onUnauthorized = _expire;
    Future.microtask(_restore);
    return const AuthLoading();
  }

  /// 저장된 토큰이 있으면 `/api/users/me`로 유효한지 확인합니다.
  Future<void> _restore() async {
    final token = await _tokens.read();
    if (token == null) {
      state = const SignedOut();
      return;
    }
    try {
      final json = await _api.get('/api/users/me');
      state = SignedIn(User.fromJson(json as Map<String, dynamic>));
    } on ApiException catch (e) {
      if (e.isNetwork) {
        // 서버가 꺼져 있어도 토큰은 지우지 않고 로그인 화면으로 보냅니다.
        state = const SignedOut();
        return;
      }
      await _tokens.clear();
      state = const SignedOut();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final json = await _api.post('/api/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    await _signIn(AuthResult.fromJson(json as Map<String, dynamic>));
  }

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final json = await _api.post('/api/auth/signup', body: {
      'email': email.trim(),
      'password': password,
      'nickname': nickname.trim(),
    });
    await _signIn(AuthResult.fromJson(json as Map<String, dynamic>));
  }

  Future<void> _signIn(AuthResult result) async {
    await _tokens.write(result.accessToken);
    state = SignedIn(result.user);
  }

  /// 닉네임 변경처럼 내 정보가 바뀌었을 때 갱신합니다.
  void updateUser(User user) {
    if (state is SignedIn) state = SignedIn(user);
  }

  /// 로그아웃: 저장한 토큰만 지웁니다(서버 호출 없음).
  Future<void> logout() async {
    await _tokens.clear();
    state = const SignedOut();
  }

  void _expire() {
    if (state is SignedIn) logout();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// 로그인한 사용자. 로그인 화면 밖에서만 씁니다.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is SignedIn ? state.user : null;
});
