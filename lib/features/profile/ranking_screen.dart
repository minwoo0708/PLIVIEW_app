import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/stats.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/brand_chip.dart';
import 'profile_providers.dart';

/// 10 베스트 큐레이터 (플리 주인별 평균 점수 순위)
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(curatorRankingProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
            stops: [0, 0.50, 0.68, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.me)),
              ),
              const SizedBox(height: 14),
              Text('베스트\n큐레이터', style: AppText.display(30, height: 38 / 30)),
              const SizedBox(height: 14),
              ranking.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.lavender)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text(e is ApiException ? e.userMessage : '불러올 수 없어요.', style: AppText.gothic(14, color: AppColors.white85)),
                    TextButton(onPressed: () => ref.invalidate(curatorRankingProvider), child: const Text('다시 시도')),
                  ]),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('아직 순위가 없어요.\n플리를 평가하면 만든 사람이 순위에 올라요.',
                            textAlign: TextAlign.center,
                            style: AppText.gothic(14, color: AppColors.white85, height: 1.5)),
                      ),
                    );
                  }
                  final top = list.first;
                  return Column(children: [
                    _TopCard(rank: top),
                    const SizedBox(height: 14),
                    for (final r in list.skip(1)) _RankRow(rank: r),
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.rank});

  final CuratorRank rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.2, 0.6),
          colors: [AppColors.lavender, Color(0xFF592BC4)],
          stops: [0, 0.73],
        ),
      ),
      child: Row(children: [
        Avatar(nickname: rank.ownerName, size: 68, border: true),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${rank.rank}', style: AppText.grotesk(12, weight: FontWeight.w700, color: AppColors.ink)),
              TextSpan(text: '위', style: AppText.gothic(12, weight: FontWeight.w800, color: AppColors.ink)),
            ])),
            Text('@${rank.ownerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.grotesk(20, weight: FontWeight.w700, color: AppColors.ink)),
            Text.rich(TextSpan(style: AppText.gothic(12, weight: FontWeight.w500, color: const Color(0xBF170A40)), children: [
              const TextSpan(text: '플리 '),
              TextSpan(text: '${rank.playlistCount}', style: AppText.grotesk(12, weight: FontWeight.w500, color: const Color(0xBF170A40))),
              const TextSpan(text: '개 · 리뷰 '),
              TextSpan(text: '${rank.reviewCount}', style: AppText.grotesk(12, weight: FontWeight.w500, color: const Color(0xBF170A40))),
            ])),
          ]),
        ),
        Text('★ ${rank.averageRating.toStringAsFixed(1)}', style: AppText.mixed(20, weight: FontWeight.w800, color: AppColors.ink)),
      ]),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank});

  final CuratorRank rank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cover),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          SizedBox(width: 24, child: Text('${rank.rank}', style: AppText.display(22, color: AppColors.primary))),
          const SizedBox(width: 12),
          Avatar(nickname: rank.ownerName, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('@${rank.ownerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.grotesk(14, weight: FontWeight.w700, color: AppColors.textPrimary)),
              Text.rich(TextSpan(style: AppText.gothic(11, color: AppColors.textSecondary), children: [
                const TextSpan(text: '플리 '),
                TextSpan(text: '${rank.playlistCount}', style: AppText.grotesk(11, color: AppColors.textSecondary)),
                const TextSpan(text: '개'),
              ])),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x29672BF4), borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text('★ ${rank.averageRating.toStringAsFixed(1)}',
                style: AppText.mixed(13, weight: FontWeight.w800, color: const Color(0xFF3B09B0))),
          ),
        ]),
      ),
    );
  }
}
