import 'package:flutter/material.dart';

import '../../core/models/review.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'cover_image.dart';
import 'star_rating.dart';

/// 리뷰 한 건을 보여 주는 흰 카드.
/// - [showItem]이 true면 왼쪽에 항목 커버와 이름을 같이 보여 줍니다(피드·프로필용).
/// - [outdated]가 true면 플리가 평가 이후 바뀌었다는 "수정됨" 배지를 붙입니다.
/// - 내 리뷰([Review.isMine])일 때만 수정·삭제 버튼을 보여 줍니다.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.showItem = false,
    this.outdated = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Review review;
  final bool showItem;
  final bool outdated;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static String formatDate(DateTime t) {
    final l = t.toLocal();
    return '${l.year}.${l.month.toString().padLeft(2, '0')}.${l.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final r = review;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.totalBar),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showItem) ...[
              Row(children: [
                CoverImage(url: r.item.imageUrl, size: 48, radius: 12, seed: r.spotifyId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (r.item.subtitle != null)
                      Text(r.item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mixed(12, color: AppColors.textSecondary)),
                  ]),
                ),
                _typeChip(r.type),
              ]),
              const SizedBox(height: 12),
            ],
            Row(children: [
              if (!showItem) ...[
                _avatar(r.author),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.author.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mixed(13, weight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ] else
                const Spacer(),
              StarRating(value: r.rating, size: 14, gap: 1),
              const SizedBox(width: 6),
              Text(r.rating.toStringAsFixed(1),
                  style: AppText.mixed(13, weight: FontWeight.w700, color: AppColors.primary)),
            ]),
            if (r.comment != null && r.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(r.comment!, style: AppText.gothic(14, color: AppColors.textPrimary, height: 1.45)),
            ],
            if (r.highlights != null && !r.highlights!.isEmpty) ..._highlights(r.highlights!),
            if (r.playlistScores != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _scoreChip('컨셉', r.playlistScores!.concept),
                _scoreChip('흐름', r.playlistScores!.flow),
                _scoreChip('발견성', r.playlistScores!.discovery),
              ]),
            ],
            if (r.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in r.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text('#$t', style: AppText.gothic(12, weight: FontWeight.w600, color: AppColors.primary)),
                  ),
              ]),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Text(formatDate(r.createdAt), style: AppText.mixed(11, color: AppColors.textSecondary)),
              if (outdated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('수정됨', style: AppText.gothic(10, weight: FontWeight.w800, color: AppColors.ink)),
                ),
              ],
              const Spacer(),
              if (r.isMine && onEdit != null)
                _action('수정', onEdit!, AppColors.primary),
              if (r.isMine && onDelete != null) ...[
                const SizedBox(width: 4),
                _action('삭제', onDelete!, AppColors.errorOnLight),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  /// 앨범·플리 리뷰의 하이라이트: 곡 선택, 최고의 순간, 전체 평가.
  List<Widget> _highlights(ReviewHighlights h) {
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label  ', style: AppText.gothic(12, weight: FontWeight.w700, color: AppColors.primary)),
            TextSpan(text: value, style: AppText.mixed(13, weight: FontWeight.w600, color: AppColors.textPrimary)),
          ])),
        );
    return [
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.scoreButton)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (h.bestTrack != null) line('최고의 곡', h.bestTrack!.name),
          if (h.worstTrack != null) line('워스트 곡', h.worstTrack!.name),
          if (h.underratedTrack != null) line('과소평가', h.underratedTrack!.name),
          if (h.bestMoment != null) line('최고의 순간', h.bestMoment!),
          if (h.body != null) ...[
            const SizedBox(height: 4),
            Text(h.body!, style: AppText.gothic(13, color: AppColors.textPrimary, height: 1.5)),
          ],
        ]),
      ),
    ];
  }

  Widget _action(String label, VoidCallback onTap, Color color) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(label, style: AppText.gothic(12, weight: FontWeight.w700, color: color)),
        ),
      );

  Widget _typeChip(ItemType type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(type.label, style: AppText.gothic(11, weight: FontWeight.w700, color: AppColors.primary)),
      );

  Widget _scoreChip(String label, double v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$label ', style: AppText.gothic(11, color: AppColors.textSecondary)),
          TextSpan(text: v.toStringAsFixed(1), style: AppText.mixed(11, weight: FontWeight.w700, color: AppColors.primary)),
        ])),
      );

  Widget _avatar(ReviewAuthor a) {
    final initial = a.nickname.isEmpty ? '?' : a.nickname.characters.first;
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: AppText.gothic(13, weight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}
