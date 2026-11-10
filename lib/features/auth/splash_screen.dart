import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/brand_chip.dart';

/// 앱을 켠 직후 저장된 토큰을 확인하는 동안 보여 주는 화면.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(child: BrandChip()),
    );
  }
}
