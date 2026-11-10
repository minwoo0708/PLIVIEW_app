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

/// 이번 주의 플리: 서버가 리뷰 50개 이상인 플리를 평균 총점 높은 순으로 줘요(최근 7일 기준).
/// 서비스 초반엔 비어 있을 수 있어서 화면에서는 비면 숨겨요.
final weeklyPlaylistsProvider = FutureProvider.autoDispose<List<PopularItem>>((ref) {
  return ref.watch(musicRepositoryProvider).weeklyPlaylists(minReviews: 50, limit: 10, days: 7);
});
