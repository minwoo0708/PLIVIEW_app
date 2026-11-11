import 'package:flutter/material.dart';

/// Figma "PLIVIEW v2"에서 뽑은 색상 토큰.
abstract final class AppColors {
  static const ink = Color(0xFF170A40);
  static const inkMid = Color(0xFF2A1475);
  static const primary = Color(0xFF5B2EFF);
  static const primaryLight = Color(0xFF9267F7);
  static const lavender = Color(0xFFC9B8FF);
  // ── 라이트/다크에 따라 바뀌는 색 ──────────────────────────
  // 앱 루트(main.dart)가 화면 모드가 바뀔 때 [applyBrightness]를 불러서 전환해요.
  static bool _dark = false;
  static bool get isDark => _dark;
  static void applyBrightness(Brightness b) => _dark = b == Brightness.dark;

  /// 화면 아래쪽 바탕색(그라데이션의 끝)
  static Color get surface => _dark ? const Color(0xFF120B2B) : const Color(0xFFF6F2FF);

  /// 흰 카드·입력칸 배경
  static Color get card => _dark ? const Color(0xFF1E1640) : Colors.white;
  static Color get chip => _dark ? const Color(0xFF2B2152) : const Color(0xFFF1ECFF);
  static Color get border => _dark ? const Color(0xFF352B63) : const Color(0xFFE4DEF5);
  static Color get textPrimary => _dark ? const Color(0xFFF3EFFF) : const Color(0xFF1A1233);
  static Color get textSecondary => _dark ? const Color(0xFFA8A2C9) : const Color(0xFF6F6A8A);

  /// 막대 그래프의 빈 칸
  /// 카드 위의 강조 글자색(다크에서는 더 밝은 보라)
  static Color get accent => _dark ? const Color(0xFFB9A4FF) : const Color(0xFF5B2EFF);

  static Color get track => _dark ? const Color(0xFF2B2152) : const Color(0xFFE9E3FA);
  static const spotifyGreen = Color(0xFF1DB954);
  static const error = Color(0xFFFF8A8A);
  static Color get errorOnLight => _dark ? const Color(0xFFFF8A8A) : const Color(0xFFD93A3A);

  static const white85 = Color(0xD9FFFFFF);
  static const white75 = Color(0xBFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white55 = Color(0x8CFFFFFF);
  static const white16 = Color(0x29FFFFFF);
  static const white14 = Color(0x24FFFFFF);
  static const white8 = Color(0x14FFFFFF);
  static const navBackground = Color(0xF0170A40);
  static const badgeBackground = Color(0x8C000000);

  /// 모든 화면의 배경(피그마 PLIVIEW v2): 화면 전체 높이에 걸쳐 진남색 → 보라(50%) → 연보라(92%) → 연보라.
  static LinearGradient get screenGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [ink, _dark ? const Color(0xFF331F9E) : const Color(0xFF4B2BD6), surface, surface],
        stops: const [0, 0.5, 0.92, 1],
      );

  // 예전 이름들(같은 그라데이션을 가리켜요).

  /// 히어로 카드 (약 163°, 끝점 73%)
  static const heroGradient = LinearGradient(
    begin: Alignment(-0.3, -1),
    end: Alignment(0.3, 0.46),
    colors: [primaryLight, primary],
  );
}

/// 모서리 반지름 토큰.
abstract final class AppRadius {
  static const pill = 999.0;
  static const hero = 28.0;
  static const card = 24.0;
  static const totalBar = 20.0;
  static const cover = 18.0;
  static const input = 16.0;
  static const scoreButton = 14.0;
}
