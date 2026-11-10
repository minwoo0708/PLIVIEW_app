import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// "PLIVIEW" 알약 배지.
class BrandChip extends StatelessWidget {
  const BrandChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'PLIVIEW',
        style: AppText.grotesk(12, weight: FontWeight.w700, color: AppColors.ink).copyWith(letterSpacing: 0.96),
      ),
    );
  }
}

/// 로그인·회원가입 배경: 단색 ink + 오른쪽 위 장식 링.
class InkScaffold extends StatelessWidget {
  const InkScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          Positioned(
            right: -120,
            top: -60,
            child: SvgPicture.asset('assets/images/deco_ring.svg', width: 260, height: 260),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// 둥근 반투명 뒤로가기 버튼.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.white16, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgPicture.asset('assets/images/icon_back.svg', width: 20, height: 20),
      ),
    );
  }
}
