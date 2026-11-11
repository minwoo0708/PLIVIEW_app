import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/review.dart';
import '../../core/models/stats.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/gradient_backdrop.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/cover_image.dart';
import 'profile_providers.dart';

/// 05 나(프로필)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();
    final data = ref.watch(profileProvider(me.id));
    final bottom = MediaQuery.paddingOf(context).bottom + 110;

    return GradientBackdrop(
      child: SafeArea(
        bottom: false,
        child: Stack(children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(profileProvider(me.id));
              await ref.read(profileProvider(me.id).future);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
              children: [
                Center(child: Avatar(nickname: me.nickname, imageUrl: me.profileImageUrl, size: 88, border: true)),
                const SizedBox(height: 14),
                Center(child: Text(me.nickname, style: AppText.display(24))),
                const SizedBox(height: 6),
                if (me.email != null)
                  Center(child: Text(me.email!, style: AppText.grotesk(12, color: AppColors.white70))),
                const SizedBox(height: 14),
                data.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.lavender)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Text(e is ApiException ? e.userMessage : '불러올 수 없어요.',
                          style: AppText.gothic(14, color: AppColors.white85)),
                      TextButton(onPressed: () => ref.invalidate(profileProvider(me.id)), child: const Text('다시 시도')),
                    ]),
                  ),
                  data: (d) => _content(d),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 4,
            child: GestureDetector(
              onTap: () => context.push(Routes.settings),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.white16, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: SvgPicture.asset('assets/images/icon_settings.svg', width: 20, height: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// 별점 막대를 누르면, 그 별점을 준 곡·앨범·플리를 종류별로 나눠서 보여 줘요.
  void _openStar(int star) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero))),
      builder: (_) => _StarSheet(userId: me.id, star: star),
    );
  }

  Widget _content(ProfileData d) {
    final stats = d.profile.stats;
    final reviews = d.reviews.content;
    final shown = _showAll ? reviews : reviews.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('리뷰 ', '${stats.reviewCount}'),
          _pill('평균 ★', stats.averageRating?.toStringAsFixed(1) ?? '-'),
          _pill('플리 ', '${stats.countByType[ItemType.playlist] ?? 0}'),
        ]),
      ),
      const SizedBox(height: 14),
      _habitCard(stats),
      const SizedBox(height: 14),
      AdaptiveColor(
        onDark: Colors.white,
        onLight: AppColors.textPrimary,
        builder: (_, color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('최근에 남긴 평가', style: AppText.gothic(15, weight: FontWeight.w800, color: color)),
          if (reviews.length > 5)
            GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? '접기' : '모두 보기', style: AppText.gothic(12, weight: FontWeight.w500, color: color)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (reviews.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('아직 남긴 평가가 없어요.\n탐색에서 첫 리뷰를 남겨 보세요!',
                textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
          ),
        )
      else
        for (final r in shown) _reviewRow(r),
      const SizedBox(height: 6),
      _makePlaylistLink(),
      const SizedBox(height: 10),
      _rankingLink(),
    ]);
  }

  Widget _pill(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: AppColors.white16, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: label, style: AppText.gothic(12, weight: FontWeight.w600)),
          TextSpan(text: value, style: AppText.grotesk(12, weight: FontWeight.w500)),
        ])),
      );

  /// 별점 분포 막대. 가장 많은 구간을 100%로 보고 비율로 그립니다.
  /// 서버는 0.5 단위 10칸이라 화면에는 정수 별(1~5)로 합쳐서 보여 줍니다(예: 4점 = 4.0 + 4.5). 막대를 누르면 그 별점을 준 항목을 모아 보여 줘요.
  Widget _habitCard(UserStats s) {
    final buckets = <int, int>{for (var star = 1; star <= 5; star++) star: 0};
    s.ratingDistribution.forEach((key, count) {
      final star = starBucket(double.parse(key));
      buckets[star] = buckets[star]! + count;
    });
    final max = buckets.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('내 별점 습관', style: AppText.gothic(15, weight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        for (var star = 5; star >= 1; star--)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openStar(star),
            child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text('★ $star', style: AppText.mixed(12, weight: FontWeight.w600, color: AppColors.accent)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final ratio = max == 0 ? 0.0 : buckets[star]! / max;
                  return Stack(children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(4)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 8,
                      width: c.maxWidth * ratio,
                      decoration: BoxDecoration(
                        color: star >= 4 ? AppColors.primary : const Color(0xFFB9A8F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ]);
                }),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 24,
                child: Text('${buckets[star]}',
                    textAlign: TextAlign.right,
                    style: AppText.grotesk(12, weight: FontWeight.w500, color: AppColors.textSecondary)),
              ),
            ]),
            ),
          ),
      ]),
    );
  }

  Widget _reviewRow(Review r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => context.push(Routes.item(r.type.path, r.spotifyId)),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.cover),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              // 평점은 맨 왼쪽, 그 옆에 앨범·플리·곡 표지
              SizedBox(
                width: 36,
                child: Text(r.rating.toStringAsFixed(1),
                    style: AppText.grotesk(16, weight: FontWeight.w700, color: AppColors.accent)),
              ),
              CoverImage(url: r.item.imageUrl, size: 52, radius: AppRadius.scoreButton, seed: r.spotifyId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    (r.comment != null && r.comment!.isNotEmpty) ? r.comment! : (r.item.subtitle ?? r.type.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.gothic(12, color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );

  /// 내가 높게 평가한 곡으로 Spotify 플리를 만드는 화면으로 가요.
  Widget _makePlaylistLink() => GestureDetector(
        onTap: () => context.push(Routes.makePlaylist),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.totalBar)),
          child: Row(children: [
            Text('높게 평가한 곡으로 플리 만들기', style: AppText.gothic(14, weight: FontWeight.w700)),
            const Spacer(),
            Text('내 취향 플리', style: AppText.gothic(12, weight: FontWeight.w600, color: AppColors.lavender)),
            const SizedBox(width: 4),
            SvgPicture.asset('assets/images/icon_chevron.svg', width: 18, height: 18,
                colorFilter: const ColorFilter.mode(AppColors.lavender, BlendMode.srcIn)),
          ]),
        ),
      );

  Widget _rankingLink() => GestureDetector(
        onTap: () => context.push(Routes.ranking),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.totalBar)),
          child: Row(children: [
            Text('플리를 잘 만드는 사람들', style: AppText.gothic(14, weight: FontWeight.w700)),
            const Spacer(),
            Text('베스트 큐레이터', style: AppText.gothic(12, weight: FontWeight.w600, color: AppColors.lavender)),
            const SizedBox(width: 4),
            SvgPicture.asset('assets/images/icon_chevron.svg', width: 18, height: 18,
                colorFilter: const ColorFilter.mode(AppColors.lavender, BlendMode.srcIn)),
          ]),
        ),
      );
}

/// 같은 별점을 준 항목 모아보기 (곡 / 앨범 / 플리로 나눔).
class _StarSheet extends ConsumerWidget {
  const _StarSheet({required this.userId, required this.star});

  final int userId;
  final int star;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allUserReviewsProvider(userId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(children: [
            Text('★ $star점을 준 항목', style: AppText.display(20, color: AppColors.textPrimary)),
          ]),
        ),
        Expanded(
          child: all.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
              child: Text(e is ApiException ? e.userMessage : '불러올 수 없어요.',
                  style: AppText.gothic(14, color: AppColors.textSecondary)),
            ),
            data: (reviews) {
              final matched = reviews.where((r) => starBucket(r.rating) == star).toList();
              if (matched.isEmpty) {
                return Center(child: Text('$star점을 준 항목이 아직 없어요', style: AppText.gothic(14, color: AppColors.textSecondary)));
              }
              return ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 20),
                children: [
                  for (final type in [ItemType.track, ItemType.album, ItemType.playlist])
                    ..._group(context, type, matched.where((r) => r.type == type).toList()),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  List<Widget> _group(BuildContext context, ItemType type, List<Review> list) {
    if (list.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text('${type.label} ${list.length}',
            style: AppText.gothic(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      for (final r in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.item(r.type.path, r.spotifyId));
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.cover),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
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
                Text(r.rating.toStringAsFixed(1),
                    style: AppText.grotesk(14, weight: FontWeight.w700, color: AppColors.accent)),
              ]),
            ),
          ),
        ),
    ];
  }
}
