import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 글꼴 규칙
/// - display: 제목, 카드 제목, 큰 점수 숫자. 굵고 또렷한 고딕 (한글은 Gothic A1, 영문·숫자는 Space Grotesk)
/// - Gothic A1: 한글 본문
/// - Space Grotesk: 영문·숫자 (곡명, 아티스트, 점수, 시간)
///
/// 한글과 영문이 섞인 문장이 많아서 [mixed]는 Space Grotesk를 기본으로 두고
/// 한글은 Gothic A1로 대체(fallback)되게 합니다. 디자인에서 영문·숫자만
/// Space Grotesk로 쓰는 것과 같은 결과가 나옵니다.
abstract final class AppText {
  /// 제목용 굵은 고딕. 동글동글한 글꼴 대신 깔끔한 고딕으로 통일합니다.
  static TextStyle display(double size, {Color color = Colors.white, double? height}) {
    return mixed(size, weight: FontWeight.w800, color: color, height: height, letterSpacing: -size * 0.02);
  }

  static TextStyle gothic(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
  }) {
    return GoogleFonts.gothicA1(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle grotesk(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  /// 영문·숫자는 Space Grotesk, 한글은 Gothic A1.
  static TextStyle mixed(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
    double? letterSpacing,
  }) {
    final korean = GoogleFonts.gothicA1(fontWeight: weight);
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: _groteskWeight(weight),
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: [korean.fontFamily!]);
  }

  /// Space Grotesk는 300~700만 있어서 굵은 값은 700으로 맞춥니다.
  static FontWeight _groteskWeight(FontWeight w) {
    if (w.value >= FontWeight.w700.value) return FontWeight.w700;
    if (w.value <= FontWeight.w300.value) return FontWeight.w300;
    return w;
  }
}
