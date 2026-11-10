import 'package:flutter/material.dart';

/// Figma "PLIVIEW v2"에서 뽑은 색상 토큰.
abstract final class AppColors {
  static const ink = Color(0xFF170A40);
  static const inkMid = Color(0xFF2A1475);
  static const primary = Color(0xFF5B2EFF);
  static const primaryLight = Color(0xFF9267F7);
  static const lavender = Color(0xFFC9B8FF);
  static const surface = Color(0xFFF6F2FF);
  static const chip = Color(0xFFF1ECFF);
  static const border = Color(0xFFE4DEF5);
  static const textPrimary = Color(0xFF1A1233);
  static const textSecondary = Color(0xFF6F6A8A);
  static const spotifyGreen = Color(0xFF1DB954);
  static const error = Color(0xFFFF8A8A);
  static const errorOnLight = Color(0xFFD93A3A);

  static const white85 = Color(0xD9FFFFFF);
  static const white75 = Color(0xBFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white55 = Color(0x8CFFFFFF);
  static const white16 = Color(0x29FFFFFF);
  static const white14 = Color(0x24FFFFFF);
  static const white8 = Color(0x14FFFFFF);
  static const navBackground = Color(0xF0170A40);
  static const badgeBackground = Color(0x8C000000);

  /// 홈 배경: ink → inkMid(30%) → surface(56%)
  static const homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ink, inkMid, surface, surface],
    stops: [0, 0.30, 0.56, 1],
  );

  /// 평가하기 배경: 같은 색, 정지점 0 / 26 / 40 / 100%
  static const rateGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ink, inkMid, surface, surface],
    stops: [0, 0.26, 0.40, 1],
  );

  /// 시작하기 배경
  static const startGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ink, Color(0xFF4B2BD6), surface, surface],
    stops: [0, 0.5, 0.92, 1],
  );

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
