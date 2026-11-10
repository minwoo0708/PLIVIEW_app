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
import '../../shared/widgets/item_tile.dart';
import 'profile_providers.dart';

/// 베스트 큐레이터 프로필: 위쪽엔 큐레이터 정보와 점수, 아래쪽엔 그 사람의 플리(인기순).
class CuratorScreen extends ConsumerWidget {
  const CuratorScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(curatorProfileProvider(userId));
    final playlists = ref.watch(curatorPlaylistsProvider(userId));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
            stops: [0, 0.34, 0.50, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.ranking)),
              ),
              const SizedBox(height: 12),
              profile.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.lavender)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e is ApiException && e.code == 'CURATOR_NOT_FOUND'
                        ? 'Spotify를 연동하지 않은 사용자예요.'
                        : (e is ApiException ? e.userMessage : '불러올 수 없어요.'),
                    textAlign: TextAlign.center,
                    style: AppText.gothic(14, color: AppColors.white85),
                  ),
                ),
                data: (c) => _Header(curator: c),
              ),
              const SizedBox(height: 18),
              Text('플리 인기순', style: AppText.gothic(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              playlists.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Text(e is ApiException ? e.userMessage : '플리를 불러올 수 없어요.',
                    style: AppText.gothic(14, color: AppColors.textSecondary)),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('리뷰가 달린 플리가 아직 없어요',
                              style: AppText.gothic(14, color: AppColors.textSecondary)),
                        ),
                      )
                    : _Grid(items: list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.curator});

  final CuratorRank curator;

  @override
  Widget build(BuildContext context) {
    String f(double? v) => v == null ? '-' : v.toStringAsFixed(1);
    Widget metric(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.scoreButton)),
            child: Column(children: [
              Text(label, style: AppText.gothic(11, weight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppText.display(20, color: AppColors.primary)),
            ]),
          ),
        );
    return Column(children: [
      Avatar(nickname: curator.nickname, imageUrl: curator.profileImageUrl, size: 80, border: true),
      const SizedBox(height: 12),
      Text(curator.nickname, style: AppText.display(22)),
      const SizedBox(height: 4),
      Text('Spotify · ${curator.spotifyDisplayName ?? curator.spotifyUserId}',
          style: AppText.mixed(12, color: AppColors.white70)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        _pill('플리 ', '${curator.playlistCount}'),
        _pill('리뷰 ', '${curator.reviewCount}'),
        _pill('평균 ★', f(curator.averageRating)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        metric('컨셉 일치도', f(curator.scores.concept)),
        const SizedBox(width: 8),
        metric('곡 흐름', f(curator.scores.flow)),
        const SizedBox(width: 8),
        metric('발견성', f(curator.scores.discovery)),
      ]),
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
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items});

  final List<PopularItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = (items.length + 1) ~/ 2;
    Widget tile(int i) {
      if (i >= items.length) return const SizedBox.shrink();
      final it = items[i];
      return ItemTile(
        id: it.spotifyId,
        title: it.item.name,
        subtitle: '리뷰 ${it.reviewCount}',
        imageUrl: it.item.imageUrl,
        rating: it.averageRating,
        onTap: () => context.push(Routes.item('playlist', it.spotifyId)),
      );
    }

    return Column(children: [
      for (var r = 0; r < rows; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: tile(r * 2)),
            const SizedBox(width: 12),
            Expanded(child: tile(r * 2 + 1)),
          ]),
        ),
    ]);
  }
}
