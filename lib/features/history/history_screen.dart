import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// 04 재생 기록 — 사용자 본인 Spotify 연동이 필요해서 2단계에서 만듭니다.
/// 지금은 안내 화면만 보여 줍니다.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.homeGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('최근에 들은 곡', style: AppText.gothic(13, weight: FontWeight.w500, color: AppColors.white70)),
            const SizedBox(height: 4),
            Text('재생 기록', style: AppText.jua(30)),
            const Spacer(),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/images/icon_clock.svg',
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Spotify 연동하면 볼 수 있어요',
                    style: AppText.mixed(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('최근에 들은 곡을 바로 평가할 수 있게\n곧 준비할게요.',
                    textAlign: TextAlign.center,
                    style: AppText.gothic(13, color: AppColors.textSecondary, height: 1.5)),
              ]),
            ),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}
