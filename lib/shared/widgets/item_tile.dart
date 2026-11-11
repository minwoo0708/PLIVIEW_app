import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'cover_image.dart';
import 'gradient_backdrop.dart';

/// 2열 그리드용 타일: 커버(정사각형) + 제목 + 보조 글자.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.rating,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImage(url: imageUrl, size: c.maxWidth, seed: id, ratingBadge: rating),
            const SizedBox(height: 6),
            // 화면 위쪽(진한 배경)에서는 흰 글자, 아래쪽(연한 배경)에서는 어두운 글자로 바뀌어요.
            AdaptiveColor(
              onDark: Colors.white,
              onLight: AppColors.textPrimary,
              builder: (_, color) => Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.mixed(14, weight: FontWeight.w800, color: color),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              AdaptiveColor(
                onDark: const Color(0xC7FFFFFF),
                onLight: AppColors.textSecondary,
                builder: (_, color) => Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mixed(12, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 곡 목록용 가로 행: 작은 커버 + 제목/아티스트 + 오른쪽 별점.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.rating,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.cover),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CoverImage(url: imageUrl, size: 56, radius: 12, seed: id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mixed(12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (rating != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('★ ${rating!.toStringAsFixed(1)}',
                    style: AppText.mixed(12, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
