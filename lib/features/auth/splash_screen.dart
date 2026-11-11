import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/brand_chip.dart';

/// 스플래시를 최소 이 시간 동안은 보여 줍니다(로그인 확인이 더 빨리 끝나도).
const splashMinDuration = Duration(milliseconds: 1800);

/// 스플래시 최소 시간이 지났는지. 라우터가 이 값이 true가 되어야 다음 화면으로 보내요.
class SplashDone extends Notifier<bool> {
  @override
  bool build() {
    Future.delayed(splashMinDuration, () {
      if (ref.mounted) state = true;
    });
    return false;
  }
}

final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

/// 앱을 켠 직후 보여 주는 화면. 로고가 서서히 커지며 나타나요.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(children: [
        Positioned(
          right: -120,
          top: -60,
          child: FadeTransition(
            opacity: fade,
            child: SvgPicture.asset('assets/images/deco_ring.svg', width: 260, height: 260),
          ),
        ),
        Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const BrandChip(),
                const SizedBox(height: 14),
                Text('PLIVIEW',
                    style: AppText.display(40, color: Colors.white).copyWith(letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('듣고, 점수 매기고, 나누기',
                    style: AppText.gothic(14, color: AppColors.lavender, weight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
