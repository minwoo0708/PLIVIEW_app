import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/network_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  // 저장된 설정을 먼저 읽어 둬서, 첫 화면부터 다크모드·글자 크기가 맞게 나와요.
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const PliviewApp(),
  ));
}

class PliviewApp extends ConsumerWidget {
  const PliviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsSyncProvider);
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'PLIVIEW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: ref.watch(routerProvider),
      // 사용자가 고른 글자 크기를 앱 전체에 곱해요(폰 설정 글자 크기도 함께 반영).
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final system = media.textScaler.scale(1.0);
        final scale = (system * settings.textScale).clamp(0.8, 1.8);
        // 현재 화면 모드(시스템 설정 포함)를 앱 색 토큰에 알려 주고, 모드가 바뀌면 화면 전체를 새로 그려요.
        final brightness = Theme.of(context).brightness;
        AppColors.applyBrightness(brightness);
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: KeyedSubtree(key: ValueKey(brightness), child: NetworkGuard(child: child!)),
        );
      },
    );
  }
}
