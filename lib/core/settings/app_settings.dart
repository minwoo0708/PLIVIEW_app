import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';

/// 글자 크기 단계(전체 앱에 곱해지는 배율).
const textScaleSteps = [
  (0.85, '작게'),
  (1.0, '보통'),
  (1.15, '크게'),
  (1.3, '아주 크게'),
];

/// 사용자가 고른 화면 설정. 기기에 저장돼서 앱을 다시 켜도 유지되고, 로그인하면 서버와도 맞춰요.
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.textScale = 1.0});

  final ThemeMode themeMode;
  final double textScale;

  bool get isDefault => themeMode == ThemeMode.system && (textScale - 1.0).abs() < 0.001;

  AppSettings copyWith({ThemeMode? themeMode, double? textScale}) =>
      AppSettings(themeMode: themeMode ?? this.themeMode, textScale: textScale ?? this.textScale);

  /// 서버 값: `{"themeMode": "SYSTEM|LIGHT|DARK", "textScale": 1.0}`
  static AppSettings? fromServer(Object? json) {
    if (json is! Map) return null;
    final mode = switch ('${json['themeMode']}'.toUpperCase()) {
      'LIGHT' => ThemeMode.light,
      'DARK' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final scale = (json['textScale'] as num?)?.toDouble() ?? 1.0;
    return AppSettings(themeMode: mode, textScale: scale.clamp(0.8, 1.5));
  }

  Map<String, dynamic> toServer() => {
        'themeMode': switch (themeMode) {
          ThemeMode.light => 'LIGHT',
          ThemeMode.dark => 'DARK',
          ThemeMode.system => 'SYSTEM',
        },
        'textScale': textScale,
      };
}

/// 앱을 켤 때 main()에서 먼저 읽어 둔 기기 저장소. 그래서 첫 화면부터 저장된 설정으로 그려져요.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('main()에서 주입해야 해요'));

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'settings_theme_mode';
  static const _kScale = 'settings_text_scale';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final mode = switch (_prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final scale = (_prefs.getDouble(_kScale) ?? 1.0).clamp(0.8, 1.5);
    return AppSettings(themeMode: mode, textScale: scale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
    _pushToServer();
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    await _prefs.setDouble(_kScale, scale);
    _pushToServer();
  }

  /// 로그인하면 서버에 저장된 설정과 맞춰요.
  /// - 서버에 저장된 값이 기본값이 아니면 서버 값을 따라요(다른 기기에서 바꾼 설정 이어받기).
  /// - 서버가 기본값인데 이 기기에서 바꿔 둔 게 있으면, 기기 값을 서버에 올려요.
  /// - 서버 API가 실패해도 기기 저장만으로 동작해요.
  Future<void> pullFromServer() async {
    try {
      final server = AppSettings.fromServer(await ref.read(apiClientProvider).get('/api/users/me/settings'));
      if (server == null) return;
      if (!server.isDefault) {
        state = server;
        await _prefs.setString(_kTheme, server.themeMode.name);
        await _prefs.setDouble(_kScale, server.textScale);
      } else if (!state.isDefault) {
        await _pushToServer();
      }
    } catch (_) {
      // 서버 API가 없어도(404) 앱은 기기 저장만으로 동작해요.
    }
  }

  Future<void> _pushToServer() async {
    if (ref.read(authControllerProvider) is! SignedIn) return;
    try {
      await ref.read(apiClientProvider).put('/api/users/me/settings', body: state.toServer());
    } catch (_) {
      // 실패해도 기기에는 이미 저장됐어요.
    }
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

/// 로그인 상태가 되면 서버 설정을 한 번 불러오는 연결고리. 앱 루트에서 watch 해 둬요.
final settingsSyncProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next is SignedIn && prev is! SignedIn) {
      ref.read(appSettingsProvider.notifier).pullFromServer();
    }
  }, fireImmediately: true);
});
