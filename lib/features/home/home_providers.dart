import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/stats.dart';

/// 홈 히어로 "이주의 앨범": 최근 7일 인기 앨범 1위. 없으면 null.
final weeklyAlbumProvider = FutureProvider.autoDispose<PopularItem?>((ref) async {
  final list = await ref.watch(musicRepositoryProvider).popular(type: ItemType.album, days: 7, limit: 1);
  return list.isEmpty ? null : list.first;
});

/// "지금 많이 듣는 앨범" 목록 (최근 7일 리뷰가 많은 순).
final popularAlbumsProvider = FutureProvider.autoDispose<List<PopularItem>>((ref) {
  return ref.watch(musicRepositoryProvider).popular(type: ItemType.album, days: 7, limit: 10);
});

/// 최신 리뷰 피드(모든 사용자).
final feedProvider = FutureProvider.autoDispose<List<Review>>((ref) async {
  final page = await ref.watch(musicRepositoryProvider).feed(page: 0, size: 10);
  return page.content;
});

/// "이번 주의 플리" 기준: 최근 7일 리뷰가 이만큼 이상 쌓인 플리만 후보가 돼요.
const weeklyPlaylistMinReviews = 50;

/// 이번 주의 플리: 최근 7일 리뷰가 [weeklyPlaylistMinReviews]개 이상인 플리를 평점 높은 순으로 보여 줘요.
/// (서버가 인기순으로만 주기 때문에 앱에서 거르고 다시 정렬합니다.)
final weeklyPlaylistsProvider = FutureProvider.autoDispose<List<PopularItem>>((ref) async {
  final list = await ref.watch(musicRepositoryProvider).popular(type: ItemType.playlist, days: 7, limit: 50);
  final qualified = list.where((p) => p.reviewCount >= weeklyPlaylistMinReviews && p.averageRating != null).toList();
  qualified.sort((a, b) {
    final byRating = b.averageRating!.compareTo(a.averageRating!);
    return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
  });
  return qualified;
});
