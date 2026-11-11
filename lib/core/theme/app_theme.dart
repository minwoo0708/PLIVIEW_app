import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// 라이트·다크 공통 설정. 색은 [AppColors]가 현재 모드에 맞춰 돌려주지만, ThemeData를 만들 때
  /// 모드가 확정되기 전일 수 있어서 여기서는 밝기에 따라 직접 고릅니다.
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF120B2B) : const Color(0xFFF6F2FF);
    final card = dark ? const Color(0xFF1E1640) : Colors.white;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: dark ? AppColors.lavender : AppColors.primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      // 기본 글꼴은 Gothic A1. 나머지 글꼴은 AppText에서 직접 지정합니다.
      fontFamily: GoogleFonts.gothicA1().fontFamily,
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.lavender,
        selectionColor: Color(0x665B2EFF),
        selectionHandleColor: AppColors.lavender,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF2B2152) : AppColors.ink,
        contentTextStyle: GoogleFonts.gothicA1(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
