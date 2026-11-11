import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/review.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/item_tile.dart';
import 'home_providers.dart';

/// 홈 "더보기": 평점 높은 앨범(또는 플리)을 순위대로 나열해요.
class TopRatedScreen extends ConsumerWidget {
  const TopRatedScreen({super.key, required this.type});

  final ItemType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(topRatedProvider(type));
    final label = type == ItemType.playlist ? '플리' : '앨범';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
            stops: [0, 0.2, 0.34, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text('평점 높은 $label', style: AppText.display(28)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text('최근 90일 리뷰 기준, 평점 순이에요', style: AppText.gothic(13, color: AppColors.white70)),
            ),
            Expanded(
              child: list.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(e is ApiException ? e.userMessage : '불러올 수 없어요.',
                        style: AppText.gothic(14, color: AppColors.textSecondary)),
                    TextButton(onPressed: () => ref.invalidate(topRatedProvider(type)), child: const Text('다시 시도')),
                  ]),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text('아직 평점이 매겨진 $label가 없어요',
                          style: AppText.gothic(14, color: AppColors.textSecondary)),
                    );
                  }
                  final rows = (items.length + 1) ~/ 2;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: rows,
                    itemBuilder: (_, r) {
                      Widget tile(int i) {
                        if (i >= items.length) return const SizedBox.shrink();
                        final it = items[i];
                        return ItemTile(
                          id: it.spotifyId,
                          title: '${i + 1}. ${it.item.name}',
                          subtitle: it.item.subtitle,
                          imageUrl: it.item.imageUrl,
                          rating: it.averageRating,
                          onTap: () => context.push(Routes.item(type.path, it.spotifyId)),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: tile(r * 2)),
                          const SizedBox(width: 12),
                          Expanded(child: tile(r * 2 + 1)),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
