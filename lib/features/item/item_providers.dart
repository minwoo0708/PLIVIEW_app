import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/models/stats.dart';

/// (종류, Spotify id). 종류는 track / album / playlist.
typedef ItemKey = (String kind, String id);

ItemType typeOfKind(String kind) => switch (kind) {
      'track' => ItemType.track,
      'album' => ItemType.album,
      _ => ItemType.playlist,
    };

/// Spotify에서 가져온 곡·앨범·플리 정보.
final spotifyItemProvider = FutureProvider.autoDispose.family<SpotifyItem, ItemKey>((ref, key) {
  final repo = ref.watch(musicRepositoryProvider);
  return switch (key.$1) {
    'track' => repo.track(key.$2),
    'album' => repo.album(key.$2),
    _ => repo.playlist(key.$2),
  };
});

/// 평균 별점·분포·내 리뷰.
final itemSummaryProvider = FutureProvider.autoDispose.family<ItemSummary, ItemKey>((ref, key) {
  return ref.watch(musicRepositoryProvider).summary(typeOfKind(key.$1), key.$2);
});

/// 항목의 리뷰 목록 (정렬: latest | rating_desc | rating_asc).
final itemReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, (ItemKey, String)>((ref, args) async {
  final (key, sort) = args;
  final page = await ref.watch(musicRepositoryProvider).itemReviews(typeOfKind(key.$1), key.$2, sort: sort);
  return page.content;
});

/// 리뷰를 쓰거나 고친 뒤 상세 화면 데이터를 새로 불러옵니다.
void refreshItem(WidgetRef ref, ItemKey key) {
  ref.invalidate(itemSummaryProvider(key));
  for (final sort in const ['latest', 'rating_desc', 'rating_asc']) {
    ref.invalidate(itemReviewsProvider((key, sort)));
  }
}

/// 앨범 수록곡 평점을 한 번에 조회합니다. 키는 곡 id를 쉼표로 이은 문자열이에요.
final trackRatingsProvider = FutureProvider.autoDispose.family<Map<String, TrackRating>, String>((ref, ids) {
  return ref.watch(musicRepositoryProvider).trackRatings(ids.split(',').where((e) => e.isNotEmpty).toList());
});
