import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// 앨범·플리 커버. 이미지가 없거나 불러오는 중이면 보라색 그라데이션을 보여 줍니다.
/// Spotify 규정에 따라 커버는 자르거나 변형하지 않고 정사각형 그대로 씁니다.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = AppRadius.cover,
    this.seed = '',
    this.ratingBadge,
  });

  final String? url;
  final double size;
  final double radius;

  /// 자리표시 색을 항목마다 다르게 하려고 쓰는 값(보통 Spotify id).
  final String seed;

  /// 커버 왼쪽 위에 올리는 "★ 4.2" 배지 값.
  final double? ratingBadge;

  static const _palettes = [
    [Color(0xFFB395F9), Color(0xFF5B2EFF)],
    [Color(0xFFD5C6F7), Color(0xFF8A6BFF)],
    [Color(0xFF592BC4), Color(0xFF250E5C)],
    [Color(0xFF672BF4), Color(0xFF4B18C2)],
    [Color(0xFF2B1D6E), Color(0xFFC9B8FF)],
  ];

  Widget _placeholder() {
    final colors = _palettes[seed.hashCode.abs() % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: const Alignment(-0.5, -1), end: const Alignment(0.5, 0.46), colors: colors),
      ),
      child: Center(
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: const BoxDecoration(color: Color(0xB3FFFFFF), shape: BoxShape.circle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null || url!.isEmpty)
              _placeholder()
            else
              CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, _) => _placeholder(),
                errorWidget: (_, _, _) => _placeholder(),
              ),
            if (ratingBadge != null)
              Positioned(left: 8, top: 8, child: RatingBadge(value: ratingBadge!)),
          ],
        ),
      ),
    );
  }
}

/// 검정 55% 알약 + "★ 4.2"
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '★ ${value.toStringAsFixed(1)}',
        style: AppText.mixed(11, weight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
