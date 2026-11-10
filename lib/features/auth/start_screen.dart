import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/primary_button.dart';

/// 01 시작하기
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.startGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandChip(),
                const SizedBox(height: 14),
                Text('듣고, 점수 주고,\n같이 고르는 플리', style: AppText.jua(34, height: 44 / 34)),
                const SizedBox(height: 14),
                Text(
                  '곡도 앨범도 플레이리스트도\n내 기준으로 기록해요',
                  style: AppText.gothic(15, color: AppColors.white75, height: 23 / 15),
                ),
                const Spacer(),
                const _CoverGrid(),
                const Spacer(),
                PrimaryButton(
                  label: '이메일로 시작하기',
                  background: AppColors.primary,
                  foreground: Colors.white,
                  onPressed: () => context.push(Routes.signup),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('이메일만 있으면 바로 시작할 수 있어요',
                      style: AppText.gothic(12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push(Routes.login),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text.rich(
                        TextSpan(
                          style: AppText.gothic(14, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: '이미 계정이 있나요? '),
                            TextSpan(
                              text: '로그인',
                              style: AppText.gothic(14, weight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 커버 그리드: 세 줄로 어긋나게 놓고, 오른쪽 줄은 화면 밖으로 살짝 잘립니다.
class _CoverGrid extends StatelessWidget {
  const _CoverGrid();

  static Widget _svg(String name, double size) =>
      SvgPicture.asset('assets/images/$name', width: size, height: size);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                const _BarCover(size: 150, radius: 24, colors: [Color(0xFF9267F7), Color(0xFF7B2FFF)]),
                const SizedBox(height: 14),
                _svg('start_cover_1.svg', 110),
              ]),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 44),
                child: Column(children: [
                  _svg('start_cover_2.svg', 110),
                  const SizedBox(height: 14),
                  _svg('start_cover_3.svg', 150),
                ]),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(children: [
                  _svg('start_cover_4.svg', 50),
                  const SizedBox(height: 14),
                  const _BarCover(size: 50, radius: 16, colors: [Color(0xFFB395F9), Color(0xFF5B2EFF)]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 막대 3개가 그려진 그라데이션 커버. 크기에 비례해 그립니다.
class _BarCover extends StatelessWidget {
  const _BarCover({required this.size, required this.radius, required this.colors});

  final double size;
  final double radius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final u = size / 150; // 150 기준 비율
    Widget bar(double left, double top, double w, double h, double alpha) => Positioned(
          left: left * u,
          top: top * u,
          child: Container(
            width: w * u,
            height: h * u,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(6 * u),
            ),
          ),
        );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -1),
          end: const Alignment(0.5, 0.46),
          colors: colors,
        ),
      ),
      child: Stack(children: [
        bar(30, 52.5, 27, 75, 0.35),
        bar(66, 30, 27, 97.5, 0.55),
        bar(102, 7.5, 27, 120, 0.75),
      ]),
    );
  }
}
