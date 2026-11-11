import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 로딩 중에 실제 화면과 같은 모양의 회색(보라) 자리표시를 보여 주는 스켈레톤 UI.
/// [Shimmer]로 감싸면 안의 [SkeletonBox]들이 함께 반짝이며 움직여요.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.skeletonBase;
    final light = AppColors.skeletonHighlight;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final dx = (_c.value * 2 - 0.5) * rect.width; // 왼쪽 밖에서 오른쪽 밖으로 지나가요
          return LinearGradient(
            colors: [base, light, base],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: _SlideTransform(dx - rect.width / 2),
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.dx);

  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}

/// 둥근 사각형 한 칸.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.skeletonBase, borderRadius: BorderRadius.circular(radius)),
      );
}

/// 2열 커버 타일 자리표시(홈·검색·더보기).
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.rows = 1});

  final int rows;

  Widget _tile() => LayoutBuilder(
        builder: (_, c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: c.maxWidth, height: c.maxWidth, radius: AppRadius.cover),
          const SizedBox(height: 8),
          const SkeletonBox(width: 110, height: 14),
          const SizedBox(height: 6),
          const SkeletonBox(width: 70, height: 12),
        ]),
      );

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _tile()),
                const SizedBox(width: 12),
                Expanded(child: _tile()),
              ]),
            ),
        ]),
      );
}

/// 가로 한 줄 카드 자리표시(리뷰·곡·랭킹 목록). 카드 안에 표지 + 두 줄 글자 모양.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 4, this.coverSize = 52});

  final int count;
  final double coverSize;

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.cover),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  SkeletonBox(width: coverSize, height: coverSize, radius: 12),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SkeletonBox(height: 14),
                      SizedBox(height: 8),
                      SkeletonBox(width: 120, height: 12),
                    ]),
                  ),
                ]),
              ),
            ),
        ]),
      );
}

/// 상세 화면(앨범·플리) 전체 자리표시: 큰 커버, 제목, 점수 줄, 버튼, 목록.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const SkeletonBox(width: 40, height: 40, radius: 20),
            const SizedBox(height: 14),
            const SkeletonBox(height: 230, radius: AppRadius.hero),
            const SizedBox(height: 18),
            const SkeletonBox(width: 220, height: 28),
            const SizedBox(height: 12),
            const SkeletonBox(width: 160, height: 14),
            const SizedBox(height: 18),
            const SkeletonBox(width: 120, height: 34),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(child: SkeletonBox(height: 46, radius: 23)),
              const SizedBox(width: 10),
              const Expanded(child: SkeletonBox(height: 46, radius: 23)),
            ]),
            const SizedBox(height: 24),
            const SkeletonBox(width: 80, height: 18),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) ...[
              const SkeletonBox(height: 58, radius: AppRadius.scoreButton),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );
}

/// 프로필 화면 자리표시: 통계 알약, 별점 습관 카드, 최근 평가 줄.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            SkeletonBox(width: 76, height: 32, radius: 16),
            SizedBox(width: 8),
            SkeletonBox(width: 96, height: 32, radius: 16),
            SizedBox(width: 8),
            SkeletonBox(width: 76, height: 32, radius: 16),
          ]),
          const SizedBox(height: 14),
          const SkeletonBox(height: 200, radius: 22),
          const SizedBox(height: 20),
          const SkeletonBox(width: 140, height: 18),
          const SizedBox(height: 12),
          const SkeletonRows(count: 3),
        ]),
      );
}
