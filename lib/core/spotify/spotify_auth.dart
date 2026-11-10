import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Spotify 사용자 연동(PKCE).
/// 최근 재생 기록처럼 "내 Spotify 계정"이 필요한 기능에만 씁니다.
/// 음악 정보 조회(검색·상세)는 서버가 대신 하므로 연동 없이도 쓸 수 있어요.
///
/// - Client ID는 공개값이라 코드에 넣어도 됩니다. Client Secret은 넣지 않습니다(PKCE라 필요 없음).
/// - 개발 모드라 Spotify Dashboard → User Management에 등록한 계정만 연동돼요.
class SpotifyAuth {
  SpotifyAuth({FlutterAppAuth? appAuth, FlutterSecureStorage? storage})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _storage = storage ?? const FlutterSecureStorage();

  static const clientId = '120ed05f019a4d0791e7e90e300256e3';
  static const redirectUrl = 'pliview://callback';
  static const scopes = ['user-read-recently-played'];

  static const _config = AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://accounts.spotify.com/authorize',
    tokenEndpoint: 'https://accounts.spotify.com/api/token',
  );

  static const _kAccess = 'spotify_access_token';
  static const _kRefresh = 'spotify_refresh_token';
  static const _kExpiry = 'spotify_token_expiry';

  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;

  /// 연동돼 있는지(리프레시 토큰이 있는지).
  Future<bool> isConnected() async => (await _storage.read(key: _kRefresh)) != null;

  /// Spotify 로그인 화면을 열어 연동합니다. 사용자가 닫으면 false.
  Future<bool> connect() async {
    try {
      final res = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          serviceConfiguration: _config,
          scopes: scopes,
        ),
      );
      await _save(res.accessToken, res.refreshToken, res.accessTokenExpirationDateTime);
      return res.accessToken != null;
    } on FlutterAppAuthUserCancelledException {
      return false;
    }
  }

  /// 유효한 액세스 토큰을 돌려줍니다. 만료됐으면 리프레시 토큰으로 새로 받고,
  /// 그것도 안 되면 연동을 해제하고 null을 돌려줍니다.
  Future<String?> accessToken() async {
    final access = await _storage.read(key: _kAccess);
    final expiry = DateTime.tryParse(await _storage.read(key: _kExpiry) ?? '');
    if (access != null && expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return access;
    }
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null) return null;
    try {
      final res = await _appAuth.token(
        TokenRequest(clientId, redirectUrl, serviceConfiguration: _config, refreshToken: refresh, scopes: scopes),
      );
      await _save(res.accessToken, res.refreshToken ?? refresh, res.accessTokenExpirationDateTime);
      return res.accessToken;
    } catch (_) {
      await disconnect();
      return null;
    }
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiry);
  }

  Future<void> _save(String? access, String? refresh, DateTime? expiry) async {
    if (access != null) await _storage.write(key: _kAccess, value: access);
    if (refresh != null) await _storage.write(key: _kRefresh, value: refresh);
    if (expiry != null) await _storage.write(key: _kExpiry, value: expiry.toIso8601String());
  }
}

final spotifyAuthProvider = Provider<SpotifyAuth>((ref) => SpotifyAuth());

/// 연동 여부를 화면이 지켜볼 수 있게 하는 상태.
class SpotifyLinkNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    Future.microtask(refresh);
    return const AsyncValue.loading();
  }

  SpotifyAuth get _auth => ref.read(spotifyAuthProvider);

  Future<void> refresh() async {
    state = AsyncValue.data(await _auth.isConnected());
  }

  /// 연동을 시도하고 결과(성공 여부)를 돌려줍니다.
  Future<bool> connect() async {
    try {
      final ok = await _auth.connect();
      state = AsyncValue.data(ok || await _auth.isConnected());
      return ok;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _auth.disconnect();
    state = const AsyncValue.data(false);
  }
}

final spotifyLinkProvider = NotifierProvider<SpotifyLinkNotifier, AsyncValue<bool>>(SpotifyLinkNotifier.new);
