import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/spotify_item.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/gradient_backdrop.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/item_tile.dart';

final _artistAlbumsProvider = FutureProvider.autoDispose.family<List<SpotifyItem>, String>(
  (ref, id) => ref.watch(musicRepositoryProvider).artistAlbums(id),
);

/// 아티스트를 누르면 나오는 앨범 목록. 앨범을 누르면 앨범 상세로 갑니다.
class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.id, this.name});

  final String id;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(_artistAlbumsProvider(id));
    return Scaffold(
      body: GradientBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.search)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Text(name ?? '아티스트', style: AppText.display(28), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: albums.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text(e is ApiException ? e.userMessage : '앨범을 불러올 수 없어요.',
                      style: AppText.gothic(14, color: AppColors.textSecondary)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(child: Text('앨범이 없어요', style: AppText.gothic(14, color: AppColors.textSecondary)));
                  }
                  final rows = (list.length + 1) ~/ 2;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: rows,
                    itemBuilder: (_, r) {
                      Widget tile(int i) => i >= list.length
                          ? const SizedBox.shrink()
                          : ItemTile(
                              id: list[i].id,
                              title: list[i].name,
                              subtitle: list[i].releaseDate,
                              imageUrl: list[i].imageUrl,
                              onTap: () => context.push(Routes.item('album', list[i].id)),
                            );
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
