import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/stats.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/item_tile.dart';
import '../../shared/widgets/review_card.dart';
import 'home_providers.dart';

/// 02 홈
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(weeklyAlbumProvider);
    ref.invalidate(popularAlbumsProvider);
    ref.invalidate(feedProvider);
    await Future.wait([
      ref.read(weeklyAlbumProvider.future),
      ref.read(popularAlbumsProvider.future),
      ref.read(feedProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final weekly = ref.watch(weeklyAlbumProvider);
    final popular = ref.watch(popularAlbumsProvider);
    final feed = ref.watch(feedProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 110;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.homeGradient),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
            children: [
              Text('안녕하세요, ${user?.nickname ?? ''}님',
                  style: AppText.gothic(13, weight: FontWeight.w500, color: AppColors.white70)),
              const SizedBox(height: 4),
              Text('오늘은 뭘\n들어볼까요?', style: AppText.display(30, height: 38 / 30)),
              const SizedBox(height: 16),
              // 히어로 카드는 인기 앨범이 있을 때만 보여 줍니다.
              if (weekly.hasValue && weekly.value == null) ...[
                const _EmptyHeroCard(),
                const SizedBox(height: 16),
              ] else if (weekly.asData?.value != null) ...[
                _HeroCard(item: weekly.asData!.value!),
                const SizedBox(height: 16),
              ],
              _section('지금 많이 듣는 앨범', onMore: () => context.go(Routes.search)),
              const SizedBox(height: 14),
              popular.when(
                loading: () => const _Loading(),
                error: (e, _) => _ErrorText(e, onRetry: () => ref.invalidate(popularAlbumsProvider)),
                data: (list) => list.isEmpty
                    ? const _Empty('아직 리뷰가 없어요.\n탐색에서 앨범을 찾아 첫 리뷰를 남겨 보세요!')
                    : _AlbumGrid(items: list),
              ),
              const SizedBox(height: 22),
              _section('최신 리뷰'),
              const SizedBox(height: 14),
              feed.when(
                loading: () => const _Loading(),
                error: (e, _) => _ErrorText(e, onRetry: () => ref.invalidate(feedProvider)),
                data: (list) => list.isEmpty
                    ? const _Empty('아직 올라온 리뷰가 없어요.')
                    : Column(children: [
                        for (final r in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(
                              review: r,
                              showItem: true,
                              onTap: () => context.push(Routes.item(r.type.path, r.spotifyId)),
                            ),
                          ),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, {VoidCallback? onMore}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary).copyWith(letterSpacing: -0.17)),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text('더보기', style: AppText.gothic(12, weight: FontWeight.w500, color: AppColors.primary)),
            ),
        ],
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});

  final PopularItem item;

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (item.item.subtitle != null) item.item.subtitle!,
      if (item.averageRating != null) '★ ${item.averageRating!.toStringAsFixed(1)}',
    ].join(' · ');
    return GestureDetector(
      onTap: () => context.push(Routes.item('album', item.spotifyId)),
      child: Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        child: Stack(children: [
          Positioned(
            left: 170,
            top: -48,
            child: SvgPicture.asset('assets/images/hero_ring.svg', width: 190, height: 190),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('이주의 앨범', style: AppText.gothic(11, weight: FontWeight.w800, color: AppColors.ink)),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.display(22)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.mixed(13, weight: FontWeight.w500, color: AppColors.white85)),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                child: SvgPicture.asset('assets/images/icon_play.svg', width: 18, height: 18),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.items});

  final List<PopularItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = (items.length + 1) ~/ 2;
    Widget tile(BuildContext context, int i) {
      if (i >= items.length) return const SizedBox.shrink();
      final it = items[i];
      return ItemTile(
        id: it.spotifyId,
        title: it.item.name,
        subtitle: it.item.subtitle,
        imageUrl: it.item.imageUrl,
        rating: it.averageRating,
        onTap: () => context.push(Routes.item('album', it.spotifyId)),
      );
    }

    return Column(children: [
      for (var r = 0; r < rows; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: tile(context, r * 2)),
            const SizedBox(width: 12),
            Expanded(child: tile(context, r * 2 + 1)),
          ]),
        ),
    ]);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
        ),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.error, {required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text(error is ApiException ? (error as ApiException).userMessage : '불러올 수 없어요.',
              textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary)),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ]),
      );
}

/// 이번 주 인기 앨범이 아직 없을 때 히어로 자리에 보여 주는 카드.
class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(Routes.search),
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('이주의 앨범', style: AppText.gothic(11, weight: FontWeight.w800, color: AppColors.ink)),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('첫 리뷰를 남겨 보세요', style: AppText.display(22)),
              const SizedBox(height: 2),
              Text('리뷰가 쌓이면 이번 주 인기 앨범이 여기에 떠요',
                  style: AppText.gothic(13, weight: FontWeight.w500, color: AppColors.white85)),
            ]),
          ],
        ),
      ),
    );
  }
}
