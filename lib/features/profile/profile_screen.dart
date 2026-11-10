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
import '../../shared/widgets/avatar.dart';
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
          stops: [0, 0.40, 0.58, 1],
        ),
      ),
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
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('최근에 남긴 평가', style: AppText.gothic(15, weight: FontWeight.w800, color: AppColors.textPrimary)),
        if (reviews.length > 5)
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? '접기' : '모두 보기',
                style: AppText.gothic(12, weight: FontWeight.w500, color: AppColors.primary)),
          ),
      ]),
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
  /// 서버는 0.5 단위 10칸이라 화면에는 정수 별(1~5)로 합쳐서 보여 줍니다(예: 4점 = 3.5 + 4.0).
  Widget _habitCard(UserStats s) {
    final buckets = <int, int>{};
    for (var star = 1; star <= 5; star++) {
      final whole = s.ratingDistribution['$star.0'] ?? 0;
      final half = s.ratingDistribution['${star - 1}.5'] ?? 0; // 4.0 별에는 3.5도 포함
      buckets[star] = star == 1 ? whole + (s.ratingDistribution['0.5'] ?? 0) : whole + half;
    }
    final max = buckets.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('내 별점 습관', style: AppText.gothic(15, weight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text('★ $star', style: AppText.mixed(12, weight: FontWeight.w600, color: const Color(0xFF672BF4))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final ratio = max == 0 ? 0.0 : buckets[star]! / max;
                  return Stack(children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: const Color(0xFFE9E3FA), borderRadius: BorderRadius.circular(4)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.cover),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.scoreButton)),
                alignment: Alignment.center,
                child: Text(r.rating.toStringAsFixed(1), style: AppText.grotesk(18, weight: FontWeight.w700)),
              ),
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
